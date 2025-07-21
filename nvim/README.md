# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

# Neovim Setup with LazyVim

Welcome to your streamlined Neovim environment powered by **LazyVim**—an extensible and fast Neovim configuration framework built around [lazy.nvim][1]. This guide will walk you through installation on **Mac** and **Linux**, as well as setup recommendations.

## Features

- Out-of-the-box Neovim IDE experience.
- Highly extensible and easily customized.
- Fast startup and plugin management.
- Maintains sane defaults for new and experienced users alike.

## Prerequisites

- **Neovim** >= 0.9.0 (with LuaJIT enabled)
- **Git** >= 2.19.0
- **Nerd Font** (for proper icons, recommended)
- [Optional] **Lazygit**, **FZF**, **Ripgrep** for enhanced workflow.

## Installation Instructions

### Step 1: Backup Existing Neovim Config (Recommended)

```sh
# Required
mv ~/.config/nvim{,.bak}

# Optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
```

This prevents any conflicts with your previous Neovim settings[1][5][4].

### Step 2: Install Neovim

**Mac:**

```sh
# If you don't have Homebrew (package manager)
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Neovim
brew install neovim
```

**Linux:**

```sh
# Download Neovim's latest prebuilt binary
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

# Extract and install
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

# Add to your PATH (add this line to your ~/.bashrc or ~/.zshrc)
export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# Reload your shell config
source ~/.bashrc  # or source ~/.zshrc
```

Test installation:

```sh
nvim --version
```

You should see Neovim's version output[5].

### Step 3: Install LazyVim Starter

```sh
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git  # Remove git history so you can version your config later
```

_Note: Cloning the [starter template](https://github.com/LazyVim/starter) gives you a basic but highly configurable LazyVim setup[1][2]._

### Step 4: Launch Neovim (LazyVim)

```sh
nvim
```

LazyVim will install dependencies and plugins on first launch. Review the config and explore customization options.

**Tip:** Run the following command in Neovim after initial install to check your environment:

```
:LazyHealth
```

This ensures all required plugins and tools are functioning correctly.

## Optional: Additional Tools

For a full IDE experience, consider adding:

- [Lazygit](https://github.com/jesseduffield/lazygit) for git UI integration.
- [FZF](https://github.com/junegunn/fzf), [Ripgrep](https://github.com/BurntSushi/ripgrep), and [fd](https://github.com/sharkdp/fd) for enhanced search and navigation.
- Install via Homebrew (`brew install lazygit fzf ripgrep fd`) or your Linux package manager.

## Directory Structure

```
~/.config/
 └── nvim/
     ├── init.lua
     ├── lua/
     └── ...
```

LazyVim enables further customization under the `lua/` directory.

## Customization & Docs

- Modify settings and add plugins by editing files inside `~/.config/nvim/lua/`.
- See the official [LazyVim documentation](https://lazyvim.github.io) for advanced configuration and plugin management.

## Getting Help

- Run `:help lazyvim` inside Neovim.
- Visit the LazyVim docs or community forums for troubleshooting tips.
