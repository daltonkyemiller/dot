#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fcntl
import getpass
import os
import re
import stat
import shutil
import subprocess
import sys
import tempfile
from datetime import UTC, datetime
from pathlib import Path
from urllib.parse import urlparse

DOMAIN = "dalton.computer"
IMAGE = "caddy:2.10.2-alpine@sha256:4c6e91c6ed0e2fa03efd5b44747b625fec79bc9cd06ac5235a779726618e530d"
CONFIG_DIR = Path("/docker/caddy-private/public-sites")
CADDYFILE = Path("/docker/caddy-private/Caddyfile.public")
SITES_DIR = Path("/srv/public-sites")
COMPOSE_FILE = Path("/docker/caddy-private/docker-compose.yml")
CADDY_SERVICE = "public-caddy"
LOCK_FILE = Path("/run/publish-dalton-site/lock")
MAX_STATIC_BYTES = 1_073_741_824
MAX_STATIC_FILES = 50_000
MIN_PUBLIC_APP_PORT = 9130
MAX_PUBLIC_APP_PORT = 9199
NAME_PATTERN = re.compile(r"^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$")
USER_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,64}$")


class PublishError(RuntimeError):
    pass


def run(command: list[str], *, input_text: str | None = None) -> str:
    result = subprocess.run(
        command,
        input=input_text,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or result.stdout.strip() or "command failed"
        raise PublishError(f"{command[0]}: {detail}")
    return result.stdout.strip()


def validate_name(name: str) -> str:
    normalized = name.lower()
    if not NAME_PATTERN.fullmatch(normalized):
        raise PublishError("site name must be a valid single DNS label")
    return normalized


def validate_username(username: str) -> str:
    if not USER_PATTERN.fullmatch(username):
        raise PublishError("username may contain only letters, numbers, dot, underscore, and hyphen")
    return username


def escape_caddy_token(value: str) -> str:
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def read_password(args: argparse.Namespace) -> str | None:
    if not args.protect:
        return None
    sources = sum(bool(value) for value in (args.password_file, args.password_stdin))
    if sources > 1:
        raise PublishError("choose only one password input method")
    if args.password_file:
        path = Path(args.password_file)
        try:
            descriptor = os.open(path, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW)
        except OSError as error:
            raise PublishError("password file must be a readable non-symlink") from error
        try:
            metadata = os.fstat(descriptor)
            if not stat.S_ISREG(metadata.st_mode):
                raise PublishError("password file must be a regular file")
            if metadata.st_uid != 0 or stat.S_IMODE(metadata.st_mode) & 0o077:
                raise PublishError("password file must be root-owned with mode 0600 or stricter")
            with os.fdopen(descriptor, "r", encoding="utf-8") as handle:
                descriptor = -1
                password = handle.read(4097).rstrip("\r\n")
        finally:
            if descriptor >= 0:
                os.close(descriptor)
    elif args.password_stdin:
        password = sys.stdin.readline().rstrip("\r\n")
    elif sys.stdin.isatty():
        password = getpass.getpass("Site password: ")
        confirmation = getpass.getpass("Confirm password: ")
        if password != confirmation:
            raise PublishError("passwords do not match")
    else:
        raise PublishError("protected publishing requires --password-stdin or --password-file")
    if len(password) < 12:
        raise PublishError("password must be at least 12 characters")
    if len(password) > 4096 or "\n" in password or "\r" in password:
        raise PublishError("password must be one line and no longer than 4096 characters")
    return password


def hash_password(password: str) -> str:
    return run(
        [
            "docker",
            "run",
            "--rm",
            "-i",
            "--entrypoint",
            "caddy",
            IMAGE,
            "hash-password",
            "--bcrypt-cost",
            "14",
        ],
        input_text=password + "\n",
    )


def auth_block(username: str, password_hash: str | None) -> str:
    if password_hash is None:
        return ""
    return (
        "\tbasic_auth {\n"
        f"\t\t{escape_caddy_token(username)} {escape_caddy_token(password_hash)}\n"
        "\t}\n"
    )


def static_config(
    name: str,
    username: str,
    password_hash: str | None,
    release_id: str,
) -> str:
    host = f"{name}.{DOMAIN}"
    return (
        f"http://{host} {{\n"
        "	import public_bind\n"
        "	redir https://{host}{uri} 308\n"
        "}\n\n"
        f"https://{host} {{\n"
        "	import public_bind\n"
        f"{auth_block(username, password_hash)}"
        f"	root * /srv/public-sites/{name}/releases/{release_id}\n"
        "	encode zstd gzip\n"
        "	file_server\n"
        "}\n"
    )


def proxy_config(name: str, upstream: str, username: str, password_hash: str | None) -> str:
    host = f"{name}.{DOMAIN}"
    return (
		f"http://{host} {{\n"
		"\timport public_bind\n"
		"\tredir https://{host}{uri} 308\n"
		"}\n\n"
		f"https://{host} {{\n"
		"\timport public_bind\n"
		f"{auth_block(username, password_hash)}"
        f"\treverse_proxy {upstream}\n"
        "}\n"
    )


def validate_upstream(upstream: str) -> str:
    parsed = urlparse(upstream)
    if parsed.scheme not in {"http", "https"} or parsed.username or parsed.password:
        raise PublishError("upstream must be an http(s) URL without credentials")
    if parsed.hostname not in {"127.0.0.1", "localhost", "::1"}:
        raise PublishError("upstream must be loopback-only")
    try:
        port = parsed.port
    except ValueError as error:
        raise PublishError("upstream must include a valid port") from error
    if port is None or not 1 <= port <= 65535:
        raise PublishError("upstream must include an explicit port")
    if not MIN_PUBLIC_APP_PORT <= port <= MAX_PUBLIC_APP_PORT:
        raise PublishError(
            f"upstream port must be in the dedicated public app range "
            f"{MIN_PUBLIC_APP_PORT}-{MAX_PUBLIC_APP_PORT}"
        )
    if parsed.path not in {"", "/"} or parsed.query or parsed.fragment:
        raise PublishError("upstream must not include a path, query, or fragment")
    host = f"[{parsed.hostname}]" if parsed.hostname == "::1" else parsed.hostname
    return f"{parsed.scheme}://{host}:{port}"


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.chmod(temporary_name, 0o640)
        os.replace(temporary_name, path)
        fsync_directory(path.parent)
    finally:
        Path(temporary_name).unlink(missing_ok=True)


def fsync_directory(path: Path) -> None:
    descriptor = os.open(path, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(descriptor)
    finally:
        os.close(descriptor)


def validate_static_source(source: Path) -> tuple[int, int]:
    if source == SITES_DIR or SITES_DIR in source.parents:
        raise PublishError("source must not be inside the managed release directory")
    for ancestor in (source, *source.parents):
        metadata = ancestor.lstat()
        if not stat.S_ISDIR(metadata.st_mode) or metadata.st_uid != 0:
            raise PublishError("source path and every ancestor must be root-owned directories")
        if stat.S_IMODE(metadata.st_mode) & 0o022:
            raise PublishError("source path ancestors must not be group/other writable")
    total_bytes = 0
    total_files = 0
    for root, directories, files in os.walk(source, followlinks=False):
        root_metadata = Path(root).lstat()
        if root_metadata.st_uid != 0 or stat.S_IMODE(root_metadata.st_mode) & 0o022:
            raise PublishError("source tree must be root-owned and not group/other writable")
        for name in [*directories, *files]:
            path = Path(root) / name
            metadata = path.lstat()
            mode = metadata.st_mode
            if metadata.st_uid != 0 or stat.S_IMODE(mode) & 0o022:
                raise PublishError("source tree must be root-owned and not group/other writable")
            if stat.S_ISLNK(mode):
                raise PublishError("published trees may not contain symbolic links")
            if not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
                raise PublishError("published trees may contain only regular files and directories")
            if stat.S_ISREG(mode):
                total_files += 1
                total_bytes += metadata.st_size
                if total_files > MAX_STATIC_FILES or total_bytes > MAX_STATIC_BYTES:
                    raise PublishError("static artifact exceeds the publishing size or file-count limit")
    return total_files, total_bytes


def validate_caddy() -> None:
    run(
        [
            "docker",
            "compose",
            "-f",
            str(COMPOSE_FILE),
            "exec",
            "-T",
            CADDY_SERVICE,
            "caddy",
            "validate",
            "--config",
            "/etc/caddy/Caddyfile",
            "--adapter",
            "caddyfile",
        ]
    )


def validate_candidate(config_path: Path, candidate: str | None) -> None:
    import_marker = "import /etc/caddy/public-sites/*.caddy"
    base = CADDYFILE.read_text(encoding="utf-8")
    if base.count(import_marker) != 1:
        raise PublishError("public Caddyfile has an unexpected route import contract")
    with tempfile.TemporaryDirectory(prefix=".candidate-", dir=CADDYFILE.parent) as temporary:
        validation_root = Path(temporary)
        validation_sites = validation_root / "public-sites"
        validation_sites.mkdir()
        for existing in CONFIG_DIR.glob("*.caddy"):
            if existing == config_path:
                continue
            metadata = existing.lstat()
            if not stat.S_ISREG(metadata.st_mode) or metadata.st_uid != 0:
                raise PublishError("public route snippets must be root-owned regular files")
            (validation_sites / existing.name).write_text(
                existing.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
        if candidate is not None:
            (validation_sites / config_path.name).write_text(candidate, encoding="utf-8")
        validation_caddyfile = validation_root / "Caddyfile"
        validation_caddyfile.write_text(
            base.replace(import_marker, "import /validation/public-sites/*.caddy"),
            encoding="utf-8",
        )
        run(
            [
                "docker",
                "run",
                "--rm",
                "--entrypoint",
                "caddy",
                "-v",
                f"{validation_root}:/validation:ro",
                IMAGE,
                "validate",
                "--config",
                "/validation/Caddyfile",
                "--adapter",
                "caddyfile",
            ]
        )


def apply_caddy() -> None:
    run(
        [
            "docker",
            "compose",
            "-f",
            str(COMPOSE_FILE),
            "exec",
            "-T",
            CADDY_SERVICE,
            "caddy",
            "reload",
            "--config",
            "/etc/caddy/Caddyfile",
            "--adapter",
            "caddyfile",
            "--address",
            "unix//run/caddy/admin.sock",
        ]
    )


def prune_releases(releases_dir: Path, current_link: Path, *, keep: int = 5) -> None:
    current_name = current_link.resolve().name if current_link.is_symlink() else None
    releases = sorted(
        (path for path in releases_dir.iterdir() if path.is_dir() and not path.is_symlink()),
        key=lambda path: path.name,
        reverse=True,
    )
    retained = {path.name for path in releases[:keep]}
    if current_name:
        retained.add(current_name)
    for release in releases:
        if release.name not in retained:
            shutil.rmtree(release)
    fsync_directory(releases_dir)


def install_static(args: argparse.Namespace) -> None:
    name = validate_name(args.name)
    source_argument = Path(args.source)
    if source_argument.is_symlink():
        raise PublishError("source must not be a symbolic link")
    source = source_argument.resolve()
    if not source.is_dir() or not (source / "index.html").is_file():
        raise PublishError("source must be a directory containing index.html at its root")
    _, source_bytes = validate_static_source(source)
    username = validate_username(args.username)
    password = read_password(args)
    password_hash = hash_password(password) if password is not None else None

    site_dir = SITES_DIR / name
    releases_dir = site_dir / "releases"
    releases_dir.mkdir(parents=True, exist_ok=True)
    if source_bytes + 134_217_728 > shutil.disk_usage(releases_dir).free:
        raise PublishError("not enough free disk space for this release")
    release_id = datetime.now(UTC).strftime("%Y%m%dT%H%M%S.%fZ")
    temporary_release = releases_dir / f".{release_id}.tmp"
    final_release = releases_dir / release_id
    try:
        shutil.copytree(source, temporary_release, symlinks=True)
        for path in temporary_release.rglob("*"):
            if path.is_symlink():
                raise PublishError("published trees may not contain symbolic links")
    except Exception:
        shutil.rmtree(temporary_release, ignore_errors=True)
        raise
    os.replace(temporary_release, final_release)
    fsync_directory(releases_dir)

    config_path = CONFIG_DIR / f"{name}.caddy"
    previous_config = config_path.read_text(encoding="utf-8") if config_path.exists() else None
    candidate_config = static_config(name, username, password_hash, release_id)
    try:
        validate_candidate(config_path, candidate_config)
    except Exception:
        shutil.rmtree(final_release, ignore_errors=True)
        raise
    current_link = site_dir / "current"
    previous_target = os.readlink(current_link) if current_link.is_symlink() else None
    next_link = site_dir / ".current.next"
    next_link.unlink(missing_ok=True)
    next_link.symlink_to(Path("releases") / release_id)

    try:
        atomic_write(config_path, candidate_config)
        validate_caddy()
        apply_caddy()
        os.replace(next_link, current_link)
        fsync_directory(site_dir)
    except Exception as error:
        next_link.unlink(missing_ok=True)
        if previous_config is None:
            config_path.unlink(missing_ok=True)
            fsync_directory(config_path.parent)
        else:
            atomic_write(config_path, previous_config)
        if previous_target is not None:
            rollback_link = site_dir / ".current.rollback"
            rollback_link.unlink(missing_ok=True)
            rollback_link.symlink_to(previous_target)
            os.replace(rollback_link, current_link)
            fsync_directory(site_dir)
        elif current_link.is_symlink():
            current_link.unlink()
        final_release.unlink(missing_ok=True) if final_release.is_file() else shutil.rmtree(final_release, ignore_errors=True)
        try:
            apply_caddy()
        except Exception as rollback_error:
            raise PublishError(
                f"{error}; restoring the previous Caddy config also failed: {rollback_error}"
            ) from error
        raise

    prune_releases(releases_dir, current_link)
    protection = f"password protected as {username}" if password_hash else "public"
    print(
        f"configured https://{name}.{DOMAIN}/ ({protection}); "
        "verify public DNS and HTTPS before reporting deployment complete"
    )


def install_proxy(args: argparse.Namespace) -> None:
    name = validate_name(args.name)
    upstream = validate_upstream(args.upstream)
    username = validate_username(args.username)
    password = read_password(args)
    password_hash = hash_password(password) if password is not None else None
    config_path = CONFIG_DIR / f"{name}.caddy"
    previous_config = config_path.read_text(encoding="utf-8") if config_path.exists() else None
    candidate_config = proxy_config(name, upstream, username, password_hash)
    validate_candidate(config_path, candidate_config)
    try:
        atomic_write(config_path, candidate_config)
        validate_caddy()
        apply_caddy()
    except Exception as error:
        if previous_config is None:
            config_path.unlink(missing_ok=True)
            fsync_directory(config_path.parent)
        else:
            atomic_write(config_path, previous_config)
        try:
            apply_caddy()
        except Exception as rollback_error:
            raise PublishError(
                f"{error}; restoring the previous Caddy config also failed: {rollback_error}"
            ) from error
        raise
    protection = f"password protected as {username}" if password_hash else "public"
    print(
        f"configured https://{name}.{DOMAIN}/ -> {upstream} ({protection}); "
        "verify public DNS and HTTPS before reporting deployment complete"
    )


def remove_site(args: argparse.Namespace) -> None:
    name = validate_name(args.name)
    config_path = CONFIG_DIR / f"{name}.caddy"
    if not config_path.exists():
        raise PublishError(f"{name}.{DOMAIN} is not published")
    previous_config = config_path.read_text(encoding="utf-8")
    validate_candidate(config_path, None)
    config_path.unlink()
    fsync_directory(config_path.parent)
    try:
        validate_caddy()
        apply_caddy()
    except Exception as error:
        atomic_write(config_path, previous_config)
        try:
            apply_caddy()
        except Exception as rollback_error:
            raise PublishError(
                f"{error}; restoring the previous Caddy config also failed: {rollback_error}"
            ) from error
        raise
    print(f"unpublished https://{name}.{DOMAIN}/; retained release files")


def list_sites(_: argparse.Namespace) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    for config_path in sorted(CONFIG_DIR.glob("*.caddy")):
        text = config_path.read_text(encoding="utf-8")
        mode = "protected" if "basic_auth" in text else "public"
        kind = "proxy" if "reverse_proxy" in text else "static"
        print(f"{config_path.stem}.{DOMAIN}\t{kind}\t{mode}")


def add_auth_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--protect", action="store_true", help="require HTTP Basic Authentication")
    parser.add_argument("--username", default="dalton")
    parser.add_argument("--password-file")
    parser.add_argument("--password-stdin", action="store_true")


def open_publication_lock():
    lock_directory = LOCK_FILE.parent
    lock_directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    directory_metadata = lock_directory.lstat()
    if (
        not stat.S_ISDIR(directory_metadata.st_mode)
        or directory_metadata.st_uid != 0
        or stat.S_IMODE(directory_metadata.st_mode) & 0o077
    ):
        raise PublishError("publisher lock directory must be a root-owned private directory")
    descriptor = os.open(
        LOCK_FILE,
        os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW,
        0o600,
    )
    metadata = os.fstat(descriptor)
    if (
        not stat.S_ISREG(metadata.st_mode)
        or metadata.st_uid != 0
        or stat.S_IMODE(metadata.st_mode) & 0o077
    ):
        os.close(descriptor)
        raise PublishError("publisher lock must be a root-owned private regular file")
    return os.fdopen(descriptor, "a+", encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Publish explicit *.dalton.computer sites")
    commands = parser.add_subparsers(dest="command", required=True)

    static_parser = commands.add_parser("static", help="atomically publish a static directory")
    static_parser.add_argument("name")
    static_parser.add_argument("source")
    add_auth_options(static_parser)
    static_parser.set_defaults(handler=install_static)

    proxy_parser = commands.add_parser("proxy", help="publish a loopback web service")
    proxy_parser.add_argument("name")
    proxy_parser.add_argument("upstream")
    add_auth_options(proxy_parser)
    proxy_parser.set_defaults(handler=install_proxy)

    remove_parser = commands.add_parser("remove", help="remove a public route")
    remove_parser.add_argument("name")
    remove_parser.set_defaults(handler=remove_site)

    list_parser = commands.add_parser("list", help="list configured public sites")
    list_parser.set_defaults(handler=list_sites)
    return parser


def main() -> int:
    try:
        args = build_parser().parse_args()
        if args.command == "list":
            args.handler(args)
        else:
            with open_publication_lock() as lock:
                fcntl.flock(lock, fcntl.LOCK_EX)
                args.handler(args)
    except (OSError, PublishError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
