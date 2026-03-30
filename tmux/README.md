# Tmux Setup

This directory contains the tmux configuration used on the Mac host.

Current files:

- [.tmux.conf](./.tmux.conf): main tmux configuration

This README documents the actual behavior of the config in this directory, not a generic tmux setup.

## Overview

The current tmux setup is built around:

- `Ctrl-a` as the prefix
- `zsh` as the default shell
- mouse support
- vi-style copy mode and pane navigation
- top status bar
- Catppuccin theme
- persistent sessions with `tmux-resurrect` and `tmux-continuum`
- macOS clipboard integration through `pbcopy`

## Core Behavior

Current defaults from [.tmux.conf](./.tmux.conf):

- terminal: `tmux-256color`
- RGB override: `xterm-256color:RGB`
- mouse: enabled
- window numbering: starts at `1`
- pane numbering: starts at `1`
- history limit: `10000`
- clipboard integration: enabled
- status bar position: top
- window renumbering: enabled

## Keybindings

Important bindings:

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

Copy mode uses vi keys.

| Action | Binding |
| --- | --- |
| Begin selection | `v` |
| Copy selection to macOS clipboard | `y` |
| Toggle rectangle selection | `r` |
| Copy with mouse drag | drag and release |

This setup is macOS-specific because it depends on:

- `pbcopy`

## Pane and Window Behavior

Current behavior:

- pane splits inherit the current working directory
- new windows open in the current working directory
- activity monitoring is enabled
- visual activity notifications are disabled
- windows are renumbered automatically after close

## Plugins

Current plugin list:

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-sensible`
- `catppuccin/tmux#v2.1.0`
- `christoomey/vim-tmux-navigator`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`
- `tmux-plugins/tmux-yank`
- `fcsonline/tmux-thumbs`

Current plugin settings:

- `@continuum-restore = on`
- `@resurrect-capture-pane-contents = on`
- `@thumbs-key = F`
- `@catppuccin_flavor = "mocha"`
- `@catppuccin_window_status_style = "rounded"`

## Status Bar

The current status line uses Catppuccin.

Current layout:

- top status bar
- empty left side
- right side modules:
  - application
  - CPU
  - session
  - uptime
  - battery

Relevant settings:

- `status-left = ""`
- `status-left-length = 100`
- `status-right-length = 100`

The battery and CPU segments are provided through Catppuccin's status modules. This repo no longer documents the older mixed plugin-path setup.

## Shell Integration

Current shell settings:

- `default-shell /bin/zsh`
- `default-command "exec /bin/zsh"`
- `update-environment -r`
- `focus-events on`
- `allow-passthrough on`

This config assumes:

- `zsh` exists at `/bin/zsh`
- `pbcopy` exists
- TPM plugins are installed under `~/.tmux/plugins`

## Plugin Path Model

The current config uses one consistent plugin path model:

- Catppuccin is loaded from `~/.tmux/plugins/tmux/catppuccin.tmux`
- TPM is initialized from `~/.tmux/plugins/tpm/tpm`

This is intentionally aligned with TPM's default install location.

## Install on macOS

Install tmux:

```bash
brew install tmux
```

Install TPM:

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Copy the repo config into place:

```bash
cp tmux/.tmux.conf ~/.tmux.conf
```

Start tmux and install plugins:

```text
Prefix + I
```

Reload config later with:

```text
Prefix + r
```

## Maintenance Notes

If you change:

- prefix bindings
- copy-mode behavior
- shell integration
- plugin list
- Catppuccin status modules
- plugin load paths

update both:

- [.tmux.conf](./.tmux.conf)
- [README.md](./README.md)

Keep this README aligned with the checked-in config, not the live machine by memory.

## References

- tmux docs: https://github.com/tmux/tmux/wiki
- TPM: https://github.com/tmux-plugins/tpm
- Catppuccin tmux: https://github.com/catppuccin/tmux
