# Tmux Setup

This directory contains the tmux configuration used in this repo.

Current files:

- [.tmux.conf](.tmux.conf): main tmux configuration

This README explains the current behavior, plugin assumptions, installation steps, and maintenance notes for the actual config in this directory.

## Current Setup

The current tmux config is built around:

- `Ctrl-a` as the tmux prefix
- `zsh` as the default shell
- vi-style navigation and copy mode
- mouse support
- top status bar
- Catppuccin theme integration
- persistent sessions using `tmux-resurrect` and `tmux-continuum`
- clipboard integration using `pbcopy`

## Main Config Behavior

Current highlights from [.tmux.conf](.tmux.conf):

- prefix:
  - `Ctrl-a`
- default terminal:
  - `tmux-256color`
- terminal override:
  - `xterm-256color:RGB`
- mouse:
  - enabled
- window numbering:
  - starts at `1`
- pane numbering:
  - starts at `1`
- history limit:
  - `10000`
- clipboard:
  - enabled
- status bar position:
  - top

## Keybindings

Current important bindings:

| Action | Binding |
| --- | --- |
| Reload config | `Prefix + r` |
| Focus pane left | `Prefix + h` |
| Focus pane down | `Prefix + j` |
| Focus pane up | `Prefix + k` |
| Focus pane right | `Prefix + l` |
| Resize pane left | `Prefix + H` |
| Resize pane down | `Prefix + J` |
| Resize pane up | `Prefix + K` |
| Resize pane right | `Prefix + L` |
| Split horizontally | `Prefix + |` |
| Split vertically | `Prefix + -` |
| New window in current path | `Prefix + c` |
| Previous window | `Prefix + Ctrl-h` |
| Next window | `Prefix + Ctrl-l` |
| Paste buffer | `Prefix + P` |

## Copy Mode

Current copy-mode behavior uses vi keys.

Bindings:

| Action | Binding |
| --- | --- |
| Begin selection | `v` |
| Copy selection to macOS clipboard | `y` |
| Toggle rectangle selection | `r` |
| Mouse drag copy to clipboard | mouse drag end |

Clipboard copy uses:

- `pbcopy`

This config is therefore clearly macOS-oriented.

## Pane and Window Behavior

Current behavior:

- pane splitting preserves the current pane path
- new windows open in the current pane path
- windows are renumbered automatically when one is closed
- activity monitoring is enabled
- visual activity notification is disabled

## Plugins

Current plugin list from the config:

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
- `catppuccin/tmux#v2.1.0`
- `christoomey/vim-tmux-navigator`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`
- `tmux-plugins/tmux-yank`
- `fcsonline/tmux-thumbs`

Current plugin-related settings:

- `@continuum-restore = on`
- `@resurrect-capture-pane-contents = on`
- `@thumbs-key = F`
- `@catppuccin_flavor = "mocha"`
- `@catppuccin_window_status_style = "rounded"`

## Status Bar

Current status bar behavior:

- shown at the top
- left side is empty
- right side includes Catppuccin segments for:
  - application
  - CPU
  - session
  - uptime
  - battery

Current relevant settings:

- `status-right-length = 100`
- `status-left-length = 100`

## Shell and Command Behavior

Current shell settings:

- `default-shell /bin/zsh`
- `default-command "exec /bin/zsh"`
- `default-command zsh`

This config assumes:

- `zsh` exists
- `pbcopy` exists
- plugin files are available in the expected plugin directories

## Plugin Path Assumptions

The config currently loads plugins from two different locations:

- `~/.config/tmux/plugins/...`
- `~/.tmux/plugins/tpm/tpm`

Specifically:

```tmux
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
run ~/.config/tmux/plugins/tmux-plugins/tmux-cpu/cpu.tmux
run ~/.config/tmux/plugins/tmux-plugins/tmux-battery/battery.tmux
run '~/.tmux/plugins/tpm/tpm'
```

That means the current setup assumes:

- TPM itself is installed under `~/.tmux/plugins/tpm`
- some plugins are available under `~/.config/tmux/plugins/...`

If you want a cleaner setup later, this is one of the first things worth normalizing.

## Install on macOS

Install tmux:

```bash
brew install tmux
```

Install TPM:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Then install plugins from inside tmux with:

```text
Prefix + I
```

## Install This Config

Copy the config into place:

```bash
cp tmux/.tmux.conf ~/.tmux.conf
```

Then reload inside tmux:

```text
Prefix + r
```

## Maintenance Notes

If you change:

- prefix
- shell settings
- plugin list
- plugin path assumptions
- copy-mode behavior
- status bar layout

update both:

- [.tmux.conf](.tmux.conf)
- [README.md](README.md)

Keep the README aligned with the actual config rather than documenting a generic tmux setup.

## References

- tmux docs: https://github.com/tmux/tmux/wiki
- TPM: https://github.com/tmux-plugins/tpm
