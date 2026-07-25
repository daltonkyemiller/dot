# dot

Personal dotfiles for macOS and Linux machines.

## Bootstrap a new machine

```sh
git clone --recurse-submodules git@github.com:daltonkyemiller/dot.git ~/dev/dot
cd ~/dev/dot
./bootstrap --packages --force
```

The bootstrap script:

- installs the shell, editor, GitHub CLI, and Neovim prerequisites;
- installs Oh My Zsh plus the tracked zsh plugins and links `~/.zshrc`;
- initializes the `nvim` submodule and links it to `~/.config/nvim`;
- installs [Bob](https://github.com/MordechaiHadad/bob) and uses stable Neovim;
- offers GitHub CLI authentication when needed;
- clones `~/dev/mdx-preview.nvim`, required by the Neovim MDX preview plugin;
- restores the locked Lazy.nvim plugin set headlessly.

Use `--auth` to require the GitHub CLI login flow rather than being prompted.
The script never changes your login shell; run `chsh -s "$(command -v zsh)"`
separately if desired.

Existing `~/.zshrc` and `~/.config/nvim` files are protected by default. Pass
`--force` to create timestamped backups and replace them with dotfile symlinks.

Machine-specific shell settings stay in `~/.zshrc.local`. Keep variables that
must exist in non-interactive shells in `~/.zshenv`.
