---
name: public-site-deployment
description: Use when publishing explicit *.dalton.computer sites safely.
version: 1.0.0
author: Hermes Agent
license: Private
metadata:
  hermes:
    tags: [caddy, public-hosting, static-sites, basic-auth]
    related_skills: [private-web-app-deployment, tanstack-start, production-deployment-operations]
---

# Public Site Deployment

## Boundary

Use the dedicated public Caddy container for `*.dalton.computer` routes while preserving `*.miller.tools` in a separate private Caddy container and TLS cache. The two containers share only the systemd-managed Compose lifecycle; public routes have no DNS API credentials or private artifact mounts. Apps bind loopback only; public Caddy alone binds the VPS public addresses on ports 80 and 443.

Publishing command: `/usr/local/bin/publish-dalton-site` (also available as `publish-dalton-site`). It validates DNS labels, permits only loopback proxy upstreams, validates the complete public Caddy config, and applies it with a graceful admin reload that leaves the private container untouched.

## Static artifacts

The source must contain `index.html` at its root and live beneath root-owned, non-writable ancestor directories (for example `/root/dev/...` or `/srv/...`, not `/tmp`). Deployment copies a timestamped immutable release and atomically switches `current`:

```sh
publish-dalton-site static <name> <directory>
```

Result: `https://<name>.dalton.computer/`.

Password protection prompts privately and stores only a bcrypt hash in Caddy config:

```sh
publish-dalton-site static <name> <directory> --protect
```

For non-interactive automation, use `--password-stdin` or a root-readable `--password-file`; do not put plaintext passwords in command arguments, repositories, or generated Caddy snippets. Passwords must contain at least 12 characters. The default username is `dalton`; override with `--username` when needed.

## TanStack Start and other services

Start the app on an unused loopback port and verify it directly, then publish:

```sh
publish-dalton-site proxy <name> http://127.0.0.1:<port>
publish-dalton-site proxy <name> http://127.0.0.1:<port> --protect
```

The tool rejects non-loopback upstreams and URLs with embedded credentials, paths, queries, or fragments.

## Operations

```sh
publish-dalton-site list
publish-dalton-site remove <name>
```

Removal disables the route but intentionally retains static releases for rollback. A single wildcard A/AAAA DNS setup means individual subdomains require no new DNS records unless explicitly overridden. Each explicit site gets its own ACME certificate through the public HTTP/HTTPS listener; do not remove or repurpose the existing `_acme-challenge.dalton.computer` delegation used by the apex Fly deployment.

## DNS prerequisite

Point wildcard A and AAAA records for `*.dalton.computer` at the VPS public addresses. DNS wildcarding is only name resolution; Caddy still serves explicit generated host routes and requests one certificate per published hostname. Certificate issuance uses HTTP-01 or TLS-ALPN, so the existing `_acme-challenge.dalton.computer` CNAME is intentionally unrelated and must remain in place.

## Verification

After every publish:

1. Verify the direct loopback app or static release.
2. Verify HTTPS and expected content through the final hostname.
3. For protected sites, verify unauthenticated requests return 401, valid credentials return 200, and the plaintext password does not appear in config/process output.
4. Verify an existing private route such as `brief.miller.tools` still works on the loopback/Tailnet path.
5. Probe a private `*.miller.tools` SNI name against the public listener and confirm it receives no private certificate or content.
6. Verify an unknown `*.dalton.computer` hostname fails closed.
7. Inspect both Caddy containers and application logs for errors.

Never report a deployment complete before DNS resolves publicly and the final HTTPS request passes from outside the loopback path.
