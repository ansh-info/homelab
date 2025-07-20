# Zsh Configuration

This is a customized Zsh configuration built for an enhanced developer experience with fast navigation, powerful autocompletions, prompt theming, and integration with modern CLI tools.

## Features

- Prompt powered by `powerlevel10k`
- Plugin management via `oh-my-zsh`
- Auto-suggestions, syntax highlighting, fuzzy matching
- Support for completions from Docker, NPM, pip, kubectl
- Interactive directory jumping with `zoxide`
- Pre-configured aliases for productivity
- Python virtualenv support
- Java (JDK 21) and Conda environment setup
- NVM (Node Version Manager) initialization

---

## Installation

### 1. Install Zsh

Zsh is typically preinstalled on macOS. Confirm with:

```bash
zsh --version
```

If not installed:

```bash
brew install zsh
```

### 2. Install Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### 3. Install Powerlevel10k Theme

```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

Set `ZSH_THEME="powerlevel10k/powerlevel10k"` in your `.zshrc`.

### 4. Install Plugins

#### Zsh Syntax Highlighting

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### Zsh Autosuggestions

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions \
  ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

#### Other Required Tools

Ensure these are installed:

```bash
brew install colorls zoxide nvm conda
brew install kubectl docker npm pip
```

Also, ensure `nvim` is installed and aliased correctly.

---

## Aliases Overview

| Alias            | Description                               |
| ---------------- | ----------------------------------------- |
| `v`, `vi`, `vim` | Open Neovim                               |
| `ls`             | Use `colorls` for enhanced `ls`           |
| `zshrc`          | Edit `.zshrc` with Neovim                 |
| `szshrc`         | Source `.zshrc`                           |
| `venv`           | Create Python virtualenv                  |
| `svenv`          | Activate virtualenv                       |
| `c`              | Clear terminal                            |
| `y`              | Launch `yazi` terminal file manager       |
| `brewup`         | Update, upgrade, and cleanup Homebrew     |
| `homelab`        | SSH into home server                      |
| `zi`             | Interactive directory search via `zoxide` |

---

## Prompt Setup

To customize the prompt, run:

```bash
p10k configure
```

Or manually edit: `~/.p10k.zsh`

---

## Optional: Enable Completions

Ensure CLI tools like `docker`, `npm`, `pip`, and `kubectl` are installed and their completions are sourced.

This is handled automatically in the configuration using conditional checks.

---

## Environment Integrations

- **Node.js:** Uses `nvm` to manage Node versions. Default version is loaded on startup.
- **Java:** Configured for JDK 21 via Homebrew.
- **Python:** Conda environment initialized via `conda init`.

---

## Cache & Completion Optimization

- Completions are cached for better performance
- Fuzzy and approximate matching is enabled for mistyped inputs
- Menu selection and enhanced color formatting for autocompletion

---

## File Locations

- `~/.zshrc` – Main shell configuration
- `~/.p10k.zsh` – Powerlevel10k prompt config
- `~/.oh-my-zsh/custom/plugins/` – Custom plugin paths

---

## License

MIT License
