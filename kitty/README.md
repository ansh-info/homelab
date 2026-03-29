# Kitty Setup

This directory contains the Kitty terminal configuration used in this repo.

Current files:

- [kitty.conf](kitty.conf): main Kitty configuration
- [current-theme.conf](current-theme.conf): active color theme included by `kitty.conf`

The source of truth is the config in this directory. This README explains what the current setup does and how to install it.

## Current Setup

The current Kitty config is built around:

- `JetBrains Mono Nerd Font`
- a `14.0` font size
- `Tokyo Night` as the active theme
- `zsh` as the shell
- `nvim` as the configured editor
- macOS-specific behavior for `Option` as `Alt`

## Main Config Behavior

Current highlights from [kitty.conf](kitty.conf):

- font family:
  - `JetBrains Mono Nerd Font`
- font size:
  - `14.0`
- line height:
  - `120%`
- cursor:
  - block cursor
  - blinking enabled
  - cursor trail enabled
- initial window size:
  - width `1000`
  - height `650`
- window padding:
  - `4`
- decorations:
  - `titlebar-only`
- tab bar:
  - top edge
  - powerline style
  - slanted powerline tabs
- shell:
  - `/bin/zsh`
- editor:
  - `/usr/local/bin/nvim`
- terminal type:
  - `xterm-256color`
- layouts:
  - `splits,stack`
- Kitty remote control:
  - enabled
- Kitty listen socket:
  - `unix:/tmp/kitty`

## Theme

The active theme is loaded through:

```conf
include current-theme.conf
```

Current theme file:

- [current-theme.conf](current-theme.conf)

Current theme:

- `Tokyo Night`

Theme metadata from the file:

- name: `Tokyo Night`
- author: `Folke Lemaitre`
- upstream:
  - `https://github.com/folke/tokyonight.nvim/raw/main/extras/kitty/tokyonight_night.conf`

## Mouse and Clipboard Behavior

Current relevant behavior:

- `copy_on_select yes`
- `cmd+c` copies to clipboard
- `cmd+v` pastes from clipboard
- URL detection is enabled
- `kitty_mod` is used for `open_url_modifiers`

## Performance Settings

Current performance-related values:

- `repaint_delay 8`
- `input_delay 0`
- `sync_to_monitor yes`

## Bell Behavior

Current bell behavior:

- audio bell disabled
- visual bell duration `0.0`
- window alert on bell enabled
- bell on tab disabled

## macOS-Specific Settings

This config is clearly optimized for macOS.

Current macOS settings include:

- `macos_option_as_alt yes`
- `macos_quit_when_last_window_closed yes`
- `macos_window_resizable yes`
- `macos_thicken_font 0.75`
- `macos_traditional_fullscreen no`
- `macos_show_window_title_in all`

## Install on macOS

Install Kitty:

```bash
brew install --cask kitty
```

Install the required font:

```bash
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

## Install This Config

Copy or symlink the repo config into Kitty's config directory:

```bash
mkdir -p ~/.config/kitty
cp kitty/kitty.conf ~/.config/kitty/kitty.conf
cp kitty/current-theme.conf ~/.config/kitty/current-theme.conf
```

Or symlink them:

```bash
mkdir -p ~/.config/kitty
ln -sf ~/path/to/repo/kitty/kitty.conf ~/.config/kitty/kitty.conf
ln -sf ~/path/to/repo/kitty/current-theme.conf ~/.config/kitty/current-theme.conf
```

Then reload Kitty config or restart Kitty.

## Notes

Current assumptions in this config:

- `zsh` exists at `/bin/zsh`
- `nvim` exists at `/usr/local/bin/nvim`
- `JetBrains Mono Nerd Font` is installed

If any of those paths differ on the local machine, update [kitty.conf](kitty.conf).

## Maintenance Notes

If you change:

- font family
- font size
- shell path
- editor path
- tab bar behavior
- macOS-specific settings
- active theme include

update:

- [kitty.conf](kitty.conf)
- [current-theme.conf](current-theme.conf) if the theme itself changes
- [README.md](README.md)

Keep the README aligned with the actual config, not a generic Kitty setup.

## References

- Kitty docs: https://sw.kovidgoyal.net/kitty/
- Kitty config docs: https://sw.kovidgoyal.net/kitty/conf/
