# Kitty Terminal Configuration

This repository contains a customized configuration for the [Kitty](https://sw.kovidgoyal.net/kitty/) terminal emulator, designed to provide a clean, efficient, and visually appealing experience. It includes a tailored layout, keyboard shortcuts, visual settings, and the **Tokyo Night** color scheme.

## Features

- **JetBrains Mono Nerd Font** for rich glyph support
- **Tokyo Night theme** with carefully selected colors for readability
- Custom **window dimensions**, **line height**, and **font size**
- Optimized **cursor behavior**, **mouse interaction**, and **tab/window navigation**
- Fast **performance tweaks** with minimal input and repaint delay
- Keyboard mappings for efficient **tab**, **window**, **split**, and **layout** management
- Support for image previews and clipboard integration
- Compatible with **macOS and Linux**

## Installation

### 1. Install Kitty

#### macOS (Homebrew)

```sh
brew install --cask kitty
```

#### Linux

Follow the official instructions from the [Kitty website](https://sw.kovidgoyal.net/kitty/#installation) or use your package manager:

**Debian/Ubuntu:**

```sh
sudo apt install kitty
```

**Arch Linux:**

```sh
sudo pacman -S kitty
```

### 2. Install JetBrains Mono Nerd Font

Download and install from the [Nerd Fonts website](https://www.nerdfonts.com/font-downloads), or via Homebrew:

```sh
brew tap homebrew/cask-fonts
brew install --cask font-jetbrains-mono-nerd-font
```

### 3. Apply the Configuration

1. Clone this repository:

```sh
git clone https://github.com/yourusername/kitty-config.git
```

2. Copy or symlink the config file:

```sh
mkdir -p ~/.config/kitty
cp kitty.conf ~/.config/kitty/kitty.conf
```

Or symlink it to keep it updated:

```sh
ln -s ~/path/to/kitty-config/kitty.conf ~/.config/kitty/kitty.conf
```

### 4. Launch Kitty

```sh
kitty
```

## Notes

- The configuration assumes you are using `zsh` and `nvim`. You can change the `shell` and `editor` values to fit your preferences.
- macOS users benefit from system-specific tweaks like `macos_quit_when_last_window_closed` and `macos_thicken_font`.
- This config disables shell integration for cursor shaping and echo control to avoid conflicts.

## License

MIT
