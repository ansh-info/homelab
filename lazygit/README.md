# Lazygit Configuration

This repository contains a personalized configuration for [Lazygit](https://github.com/jesseduffield/lazygit), a simple terminal UI for Git commands.

## Features

- Customized dark theme with clear color coding for Git statuses
- File tree display with Nerd Fonts icon support
- Automatic fetching and refreshing of repository status
- Flexible panel resizing and navigation
- Custom keybindings for files, branches, and commits
- Commitizen integration for standardized commit messages
- Support for multiple Git workflows (merge, rebase, fast-forward)

## Keybindings Overview

| Context   | Action             | Shortcut                    |
| --------- | ------------------ | --------------------------- |
| Universal | Quit               | `q` / `Ctrl + C` / `Q`      |
|           | Toggle panel       | `<Tab>`                     |
|           | Navigation         | Arrows                      |
| Files     | Stage/unstage all  | `<Ctrl + A>` / `a`          |
|           | Commit             | `c` (direct) / `C` (editor) |
|           | Amend last commit  | `A`                         |
| Branches  | Checkout           | `c`                         |
|           | Force checkout     | `F`                         |
|           | Merge into current | `M`                         |
|           | Rebase             | `r`                         |
| Commits   | Squash             | `s`                         |
|           | Rename             | `r` / `R`                   |
|           | Cherry-pick        | `c` / `C`                   |
|           | Revert             | `t`                         |

---

## Installation

### 1. Install Lazygit

Lazygit is available via Homebrew on macOS:

```bash
brew install lazygit
```

On Linux, refer to the Lazygit [installation instructions](https://github.com/jesseduffield/lazygit#installation).

### 2. Install Neovim

This configuration is designed to work with Neovim installed from [this repository](https://github.com/anshinfo/neovim-config).

Follow the setup guide in that repository to ensure your Neovim environment matches this Lazygit configuration.

### 3. Add the Config File

On macOS, place the configuration file in:

```bash
mkdir -p ~/Library/Application\ Support/lazygit
cp config.yml ~/Library/Application\ Support/lazygit/config.yml
```

On Linux, place it in:

```bash
mkdir -p ~/.config/lazygit
cp config.yml ~/.config/lazygit/config.yml
```

---

## Customization & Documentation

- Lazygit Documentation: [https://github.com/jesseduffield/lazygit](https://github.com/jesseduffield/lazygit)
- Theming Guide: [https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md)
- Commitizen: [https://commitizen-tools.github.io/commitizen/](https://commitizen-tools.github.io/commitizen/)

---

## Troubleshooting

If something doesn't work as expected:

- Ensure Nerd Fonts are installed and configured in your terminal
- Verify Neovim is installed from the recommended repository
- Check Lazygit logs for errors by pressing `?` and selecting "Show Logs"
- Make sure the configuration file is in the correct location for your OS

---

## License

MIT License – customize and share freely.
