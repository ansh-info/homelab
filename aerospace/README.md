# AeroSpace Setup

This directory contains the AeroSpace configuration used on macOS.

The source of truth is:

- [aerospace.toml](aerospace.toml)

This README explains what the current config does, how to install it, and how the keybindings are organized.

## Current Behavior

The current config is built around three modes:

- `main`: normal navigation, movement, layout switching, and workspace control
- `resize`: temporary mode for resizing containers
- `service`: temporary mode for reload, flatten, floating-layout toggle, and join actions

Other current behavior:

- AeroSpace starts at login
- root layout defaults to `tiles`
- root orientation defaults to `auto`
- normalization is enabled
- uniform `5px` gaps are used around and between windows
- accordion layout uses `30px` padding
- workspace switching is enabled for `1` through `7`
- moving windows to workspaces is enabled for `1` through `8`

## Install on macOS

Install AeroSpace with Homebrew:

```bash
brew tap nikitabobko/homebrew-aerospace
brew install --cask aerospace
```

Then grant the required macOS permissions:

1. Open `System Settings`
2. Go to `Privacy & Security`
3. Open `Accessibility`
4. Allow `AeroSpace.app`

## Install This Config

Copy the repo config into the default AeroSpace config location:

```bash
cp aerospace/aerospace.toml ~/.aerospace.toml
```

Then either:

- restart AeroSpace
- or reload the config from service mode

## Keybindings

## Main Mode

These bindings are always available in the default mode.

| Action | Binding |
| --- | --- |
| Focus left | `Alt + h` |
| Focus down | `Alt + j` |
| Focus up | `Alt + k` |
| Focus right | `Alt + l` |
| Move window left | `Alt + Shift + h` |
| Move window down | `Alt + Shift + j` |
| Move window up | `Alt + Shift + k` |
| Move window right | `Alt + Shift + l` |
| Switch to workspace 1-7 | `Alt + 1..7` |
| Move window to workspace 1-8 | `Alt + Shift + 1..8` |
| Toggle fullscreen | `Alt + Shift + f` |
| Tiles / layout cycle | `Alt + /` |
| Accordion / layout cycle | `Alt + ,` |
| Previous workspace | `Alt + Tab` |
| Move workspace to next monitor | `Alt + Shift + Tab` |
| Enter resize mode | `Alt + Shift + r` |
| Enter service mode | `Alt + Shift + ;` |

## Resize Mode

Enter with:

- `Alt + Shift + r`

Bindings:

| Action | Binding |
| --- | --- |
| Shrink width | `h` |
| Grow height | `j` |
| Shrink height | `k` |
| Grow width | `l` |
| Balance sizes | `b` |
| Smart shrink | `-` |
| Smart grow | `=` |
| Return to main mode | `Enter` |
| Return to main mode | `Esc` |

## Service Mode

Enter with:

- `Alt + Shift + ;`

Bindings:

| Action | Binding |
| --- | --- |
| Reload config and return to main mode | `Esc` |
| Flatten workspace tree and return to main mode | `r` |
| Toggle floating / tiling and return to main mode | `f` |
| Close all windows except current and return to main mode | `Backspace` |
| Join with left | `Alt + Shift + h` |
| Join with down | `Alt + Shift + j` |
| Join with up | `Alt + Shift + k` |
| Join with right | `Alt + Shift + l` |

## Layout and Gap Settings

Current layout-related values from the config:

- `default-root-container-layout = 'tiles'`
- `default-root-container-orientation = 'auto'`
- `enable-normalization-flatten-containers = true`
- `enable-normalization-opposite-orientation-for-nested-containers = true`
- `accordion-padding = 30`

Current gaps:

- `inner.horizontal = 5`
- `inner.vertical = 5`
- `outer.left = 5`
- `outer.right = 5`
- `outer.top = 5`
- `outer.bottom = 5`

## Workspace Notes

Current active workspace bindings:

- direct switching: `1` through `7`
- move-node bindings: `1` through `8`

Workspace `8` is available for moving windows, but direct switching to `8` is currently commented out in the config.

## Maintenance Notes

If you change:

- keybindings
- mode behavior
- workspace range
- gap values
- startup behavior

update both:

- [aerospace.toml](aerospace.toml)
- [README.md](README.md)

Keep the README aligned with the actual config instead of documenting hypothetical bindings.

## References

- AeroSpace guide: https://nikitabobko.github.io/AeroSpace/guide
- AeroSpace commands: https://nikitabobko.github.io/AeroSpace/commands
- AeroSpace GitHub: https://github.com/nikitabobko/AeroSpace
