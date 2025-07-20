# Tmux Configuration

This repository contains a custom `tmux` configuration optimized for enhanced navigation, session management, and aesthetics.

## Features

- Prefix remapped to `Ctrl-a`
- System clipboard integration
- Mouse support enabled
- Vi-style keybindings in copy mode
- Smart pane splitting and Vim-style pane navigation
- Persistent sessions using `tmux-resurrect` and `tmux-continuum`
- Stylish Catppuccin theme with CPU, battery, uptime, and session info in the status bar
- Plugin support via TPM (Tmux Plugin Manager)

## Installation

### 1. Install Tmux

Ensure Tmux is installed:

```bash
brew install tmux
```

### 2. Install TPM (Tmux Plugin Manager)

Clone TPM into your plugins directory:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 3. Install Required Plugins

Once inside a Tmux session, press:

```
Prefix (Ctrl-a) + I
```

This will install all plugins defined in the config file.

### 4. Copy the Configuration File

Place the `tmux.conf` file into your home directory:

```bash
cp tmux.conf ~/.tmux.conf
```

Or use the config from `~/.config/tmux/tmux.conf` if you manage dotfiles via XDG.

### 5. Reload Configuration

Within a Tmux session, reload the config with:

```
Prefix (Ctrl-a) + r
```

## Plugin List

- [`tmux-plugins/tpm`](https://github.com/tmux-plugins/tpm) – Plugin manager
- [`tmux-plugins/tmux-sensible`](https://github.com/tmux-plugins/tmux-sensible) – Sensible defaults
- [`catppuccin/tmux`](https://github.com/catppuccin/tmux) – Theming
- [`christoomey/vim-tmux-navigator`](https://github.com/christoomey/vim-tmux-navigator) – Seamless navigation between Vim and Tmux
- [`tmux-plugins/tmux-resurrect`](https://github.com/tmux-plugins/tmux-resurrect) – Restore sessions
- [`tmux-plugins/tmux-continuum`](https://github.com/tmux-plugins/tmux-continuum) – Auto-save sessions
- [`tmux-plugins/tmux-yank`](https://github.com/tmux-plugins/tmux-yank) – Clipboard integration
- [`fcsonline/tmux-thumbs`](https://github.com/fcsonline/tmux-thumbs) – Fast link and text selection

## Default Keybindings

| Action                  | Binding                  |     |
| ----------------------- | ------------------------ | --- |
| Reload config           | `Ctrl-a r`               |     |
| Select pane (hjkl)      | `Ctrl-a h/j/k/l`         |     |
| Resize pane (HJKL)      | `Ctrl-a Shift + h/j/k/l` |     |
| Split pane horizontally | \`Ctrl-a                 | \`  |
| Split pane vertically   | `Ctrl-a -`               |     |
| Create new window       | `Ctrl-a c`               |     |
| Next/prev window        | `Ctrl-a C-l / C-h`       |     |
| Copy mode (Vi)          | `Ctrl-a [`               |     |
| Copy selection          | `v` + `y`                |     |
| Paste buffer            | `Ctrl-a P`               |     |

## Notes

- This configuration assumes `zsh` is your default shell.
- Make sure `pbcopy` is available on macOS for clipboard support in copy mode.
- Plugins like `tmux-cpu` and `tmux-battery` are loaded directly. Ensure they are cloned into `~/.config/tmux/plugins/`.

## Recommended Dependencies

- [kitty](https://github.com/kovidgoyal/kitty)
- [Nerd Fonts](https://www.nerdfonts.com/) (for icons and enhanced status line appearance)
- [fzf](https://github.com/junegunn/fzf) and [ripgrep](https://github.com/BurntSushi/ripgrep) for fuzzy search integrations (optional)

## License

MIT License
