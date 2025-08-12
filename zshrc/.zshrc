# ===== Powerlevel10k Instant Prompt (keep at very top) =====
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===== Paths (your originals, consolidated) =====
export PATH="/opt/homebrew/opt/openjdk@21/bin:/Library/TeX/texbin:/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# ===== Oh My Zsh setup =====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Keep your plugin set; syntax-highlighting is sourced manually later.
plugins=(git zsh-autosuggestions docker kubectl npm pip)

# Optional: disable OMZ auto-update checks
zstyle ':omz:update' mode disabled

# ===== Completions (single, cached compinit; macOS-safe, no console output) =====
autoload -Uz compinit
zmodload zsh/stat
if [[ -f ~/.zcompdump-$ZSH_VERSION ]]; then
  local _zcd_mtime
  _zcd_mtime=$(zstat +mtime ~/.zcompdump-$ZSH_VERSION 2>/dev/null)
  if (( EPOCHSECONDS - _zcd_mtime < 2592000 )); then
    compinit -C -d ~/.zcompdump-$ZSH_VERSION
  else
    compinit -i -d ~/.zcompdump-$ZSH_VERSION
  fi
else
  compinit -i -d ~/.zcompdump-$ZSH_VERSION
fi

# Your completion styles (kept)
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Docker CLI adds completion functions into fpath (keep this)
fpath=(/Users/anshkumar/.docker/completions $fpath)

# ===== Source Oh My Zsh (loads your plugins) =====
source $ZSH/oh-my-zsh.sh

# ===== Powerlevel10k speed knobs (before sourcing ~/.p10k.zsh) =====
typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.2
typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN='~/(Library|Movies|node_modules|.cache)(/|$)|/Volumes(/|$)'
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ===== Prompt-related plugins order =====
# zsh-autosuggestions via plugins; syntax-highlighting LAST:
source /Users/anshkumar/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ===== Editor & Aliases (your originals) =====
export EDITOR='nvim'
export VISUAL='nvim'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias ls='eza'
alias zshrc='vi ~/.zshrc'
alias conf='cd ~/.config/ && vi .'
alias szshrc='source ~/.zshrc'
alias venv='python3.12 -m venv venv'
alias svenv='source venv/bin/activate'
alias c='clear'
alias y='yazi'
alias brewup="brew update && brew upgrade && brew cleanup"
alias homelab='ssh homelab@100.123.147.108'
alias zi='zoxide query --interactive'
alias bat='cat'

# ===== Replace heavy manual completions with OMZ plugins =====
# (Removed: docker/kubectl/npm/pip completion subprocesses)

# ===== NVM (lazy load; preserves your default-node behavior) =====
export NVM_DIR="$HOME/.nvm"
_lazy_nvm() { unset -f node npm npx nvm; [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"; }
nvm()  { _lazy_nvm; command nvm "$@"; }
node() { _lazy_nvm; command node "$@"; }
npm()  { _lazy_nvm; command npm  "$@"; }
npx()  { _lazy_nvm; command npx  "$@"; }
# Emulate "nvm use default" once per session without startup cost
_nvm_use_default_once() {
  unset -f _nvm_use_default_once
  command -v nvm >/dev/null || _lazy_nvm
  nvm use default &>/dev/null
}
precmd_functions+=(_nvm_use_default_once)

# ===== Conda (lazy; base not auto-activated) =====
# Run once:  conda config --set auto_activate_base false
_lazy_conda() {
  unset -f conda
  __conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' shell.zsh hook 2>/dev/null)"
  eval "$__conda_setup"
  unset __conda_setup
}
conda() { _lazy_conda; command conda "$@"; }

# ===== zoxide (kept) =====
eval "$(zoxide init zsh)"

# ===== uv / uvx completions (kept, gated) =====
command -v uv  >/dev/null && eval "$(uv generate-shell-completion zsh)"
command -v uvx >/dev/null && eval "$(uvx --generate-shell-completion zsh)"

# ===== Built-in clear (instant) =====
bindkey '^L' clear-screen

# ===== Load secrets (keep API keys out of this file) =====
[[ -f "$HOME/.secrets.zsh" ]] && source "$HOME/.secrets.zsh"
