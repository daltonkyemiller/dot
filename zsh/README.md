# Zsh

This directory owns the shared, portable shell configuration. The installer
creates `~/.zshrc` as a symlink to `zsh/zshrc`, installs Oh My Zsh, and installs
the configured plugins:

- `zsh-vi-mode`
- `zsh-system-clipboard`
- `fzf-tab`

For a complete shell and Neovim setup, run the repository-root `./bootstrap`
script instead.

## Bootstrap a machine

```sh
git clone git@github.com:daltonkyemiller/dot.git ~/dotfiles
cd ~/dotfiles
./zsh/install --packages --force
```

`--packages` supports Homebrew, apt, dnf, pacman, and apk. It installs the
shell dependencies where available, and always falls back to the required
`zsh` and `git` pair. On a restricted VPS, install those two packages yourself,
then run `./zsh/install --force`.

The installer never changes your login shell. Set it separately when wanted:

```sh
chsh -s "$(command -v zsh)"
```

## Machine-local configuration

Put secrets, work tokens, host-only paths, and experiments in
`~/.zshrc.local`. It is sourced after the shared configuration and is never
tracked by this repository.

```sh
export SOME_TOKEN='...'
export PATH="$HOME/custom-tool/bin:$PATH"
```

The shared configuration works without optional tools such as `eza`, `fzf`, or
`zoxide`; it simply enables their integrations when installed.
