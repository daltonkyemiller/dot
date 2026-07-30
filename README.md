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
- links every tracked `.agents/skills` entry into `~/.agents/skills` and
  `~/.claude/skills` while preserving extra machine-local skills;
- initializes the `nvim` submodule and links it to `~/.config/nvim`;
- installs or updates [Bob](https://github.com/MordechaiHadad/bob), installs
  the Tree-sitter CLI, and selects stable Neovim while preserving a working
  existing Neovim if the update fails;
- installs LazyGit and Lazydocker;
- links the tracked LazyGit and Lazydocker themes into the XDG config directory;
- links Herdr, Sesh, and the Switchboard agent-command configuration into the XDG config directory;
- installs Herdr and Gum, then clones and links the tracked Sesh and Switchboard Herdr plugins;
- offers GitHub CLI authentication when needed;
- clones `~/dev/mdx-preview.nvim`, required by the Neovim MDX preview plugin;
- clones `~/dev/switchboard`, installs its Linux CLI release, and loads its
  Neovim companion plugin;
- restores the locked Lazy.nvim plugin set headlessly.

Use `--auth` to require the GitHub CLI login flow rather than being prompted.
The script never changes your login shell; run `chsh -s "$(command -v zsh)"`
separately if desired.

Existing `~/.zshrc` and `~/.config/nvim` files are protected by default. Pass
`--force` to create timestamped backups and replace them with dotfile symlinks.

Machine-specific shell settings stay in `~/.zshrc.local`. Keep variables that
must exist in non-interactive shells in `~/.zshenv`.
