# Zsh Setup

This directory contains the current Zsh setup used on the Mac.

Source files:

- [`.zshrc`](.zshrc)
- [`.secrets.zsh`](.secrets.zsh)

The setup is optimized for:

- fast interactive shell startup
- a clean split between public shell config and private local secrets
- modern CLI tooling on Apple Silicon macOS

## Current Behavior

The current shell config uses:

- `oh-my-zsh`
- `powerlevel10k`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- cached completions via `compinit`
- lazy-loaded `nvm`
- cached `uv` completions
- `zoxide`
- `eza`
- a `y()` wrapper that keeps the shell working directory in sync with `yazi`

The current config also:

- uses `brew shellenv`
- sets up `JAVA_HOME` for `openjdk@21`
- adds Homebrew, Docker app, Perl, and TeX paths
- skips the heavier prompt/completion stack for non-TTY shell invocations

Conda is intentionally not part of the current setup anymore.

## Files

### `.zshrc`

This is the main shell configuration.

It includes:

- prompt and plugin loading
- completion setup
- aliases
- lazy `nvm`
- `zoxide`
- `uv` completion cache loading
- sourcing of `~/.secrets.zsh`

### `.secrets.zsh`

This is a template for local-only shell secrets and private aliases.

It is intended for values such as:

- `OPENAI_API_KEY`
- `NGC_API_KEY`
- `NVIDIA_API_KEY`
- `HF_TOKEN`
- `HUGGING_FACE_HUB_TOKEN`
- `WANDB_*`
- private host aliases like `homelab`

The checked-in file must always keep placeholders only.

## Required Tools

Install the tools used by the current config:

```bash
brew install zsh eza zoxide nvm
brew install --cask docker
```

Also install:

- Oh My Zsh
- Powerlevel10k
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `nvim`
- `yazi`
- `uv`

## Current Aliases and Helpers

| Name | Purpose |
| --- | --- |
| `v`, `vi`, `vim` | open Neovim |
| `ls` | use `eza` |
| `zshrc` | edit `~/.zshrc` |
| `secrets` | edit `~/.secrets.zsh` |
| `szshrc` | source `~/.zshrc` |
| `svenv` | activate `.venv` |
| `c` | clear the screen |
| `zi` | interactive `zoxide` query |
| `brewup` | update/upgrade/cleanup Homebrew and refresh cached `uv` completion if needed |
| `y()` | launch `yazi` and `cd` into the selected directory afterward |

## Notes

- The repo copy of [`.zshrc`](.zshrc) should track the live `~/.zshrc`.
- The repo copy of [`.secrets.zsh`](.secrets.zsh) should remain a placeholder template only.
- Keep machine-specific private values out of [`.zshrc`](.zshrc) when they belong in [`.secrets.zsh`](.secrets.zsh).
- If the shell setup changes, update both the config files and this README together.
