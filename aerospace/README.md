# AeroSpace Configuration

This repository contains a personalized configuration for [AeroSpace](https://github.com/nikitabobko/AeroSpace), a dynamic tiling window manager for macOS.

## ✨ Features

- Starts automatically on login
- Smart window layouts: `tiles` and `accordion`
- Workspace keybindings (Alt + number)
- Intuitive resizing and navigation
- Gap customizations between windows and screen edges
- Layout normalization for nested containers
- Modes for resizing and service commands
- Predefined movement, focus, and layout switching shortcuts

## Keybindings Overview

| Action                    | Shortcut                |
| ------------------------- | ----------------------- |
| Focus window (hjkl)       | `Alt + h/j/k/l`         |
| Move window (hjkl)        | `Alt + Shift + h/j/k/l` |
| Workspace switch          | `Alt + 1-7`             |
| Move window to workspace  | `Alt + Shift + 1-8`     |
| Fullscreen toggle         | `Alt + Shift + f`       |
| Toggle layout (tiles)     | `Alt + /`               |
| Toggle layout (accordion) | `Alt + ,`               |
| Resize mode               | `Alt + Shift + r`       |
| Service mode              | `Alt + Shift + ;`       |

---

## Installation on macOS

### 1. Install [AeroSpace](https://github.com/nikitabobko/AeroSpace)

AeroSpace is available via Homebrew:

```bash
brew tap nikitabobko/homebrew-aerospace
brew install --cask aerospace
```

### 2. Enable Accessibility Permissions

After installation, macOS will prompt you to give AeroSpace Accessibility permissions. You can also enable it manually:

- Open **System Settings** → **Privacy & Security** → **Accessibility**
- Add and enable **AeroSpace.app**

### 3. Add the Config File

Place your custom configuration in your home directory:

```bash
cp aerospace.toml ~/.aerospace.toml
```

> If `~/.aerospace.toml` is missing a key, the default config will be used as a fallback.

### 4. Start at Login

Make sure `start-at-login = true` is set in the config to launch AeroSpace when you log in.

---

## 🧪 Customization & Documentation

- Commands: [https://nikitabobko.github.io/AeroSpace/commands](https://nikitabobko.github.io/AeroSpace/commands)
- Guide: [https://nikitabobko.github.io/AeroSpace/guide](https://nikitabobko.github.io/AeroSpace/guide)
- GitHub: [https://github.com/nikitabobko/AeroSpace](https://github.com/nikitabobko/AeroSpace)

---

## 🛠️ Troubleshooting

If something doesn't work as expected:

- Ensure AeroSpace is granted all required permissions
- Use `Alt + Shift + ;` to enter Service Mode
- Press `r` to reset layout or `esc` to reload config

---

## License

MIT License – customize and share freely.
