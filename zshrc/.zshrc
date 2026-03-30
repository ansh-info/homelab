# Powerlevel10k instant prompt must stay at the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Homebrew and base paths.
eval "$(/opt/homebrew/bin/brew shellenv)"
typeset -U path PATH fpath

path=(
  /opt/homebrew/opt/openjdk@21/bin
  /opt/homebrew/opt/perl/bin
  /Library/TeX/texbin
  /Applications/Docker.app/Contents/Resources/bin
  $path
)

export PATH
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"
export EDITOR='nvim'
export VISUAL='nvim'

# Detect whether this shell has a real terminal attached.
if [[ -t 0 && -t 1 ]]; then
  ZSH_HAS_TTY=1
else
  ZSH_HAS_TTY=0
fi

# Oh My Zsh and prompt stack only need to load for real terminal sessions.
if (( ZSH_HAS_TTY )); then
  export ZSH="$HOME/.oh-my-zsh"
  ZSH_THEME="powerlevel10k/powerlevel10k"
  plugins=(git zsh-autosuggestions)
  zstyle ':omz:update' mode disabled

  # Completions.
  [[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
  autoload -Uz compinit
  local_zcomp_host="${HOST%%.*}"
  local_zcompdump="$HOME/.zcompdump-${local_zcomp_host}-$ZSH_VERSION"
  if [[ -r "$local_zcompdump" ]]; then
    compinit -C -d "$local_zcompdump"
  else
    compinit -i -d "$local_zcompdump"
  fi

  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path "$HOME/.zcompcache"
  zstyle ':completion:*' menu select
  zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
  zstyle ':completion:*' completer _complete _match _approximate
  zstyle ':completion:*:match:*' original only
  zstyle ':completion:*:approximate:*' max-errors 1 numeric
  zstyle ':completion:*:*:*:*:*' menu select
  zstyle ':completion:*:matches' group yes
  zstyle ':completion:*:options' description yes
  zstyle ':completion:*:options' auto-description '%d'
  zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
  zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*:messages' format ' %F{purple}-- %d --%f'
  zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
  zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
  zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
  zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

  source "$ZSH/oh-my-zsh.sh"

  # Powerlevel10k prompt tuning.
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.2
  typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
  typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN='~/(Library|Movies|node_modules|.cache)(/|$)|/Volumes(/|$)'
  [[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

  # Syntax highlighting should load after Oh My Zsh.
  if [[ -r "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
  fi
fi

# Aliases and helpers.
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias ls='eza'
alias zshrc='nvim ~/.zshrc'
alias conf='cd ~/.config/ && nvim .'
alias szshrc='source ~/.zshrc'
alias secrets='nvim ~/.secrets.zsh'
alias svenv='source .venv/bin/activate'
alias c='clear'
alias zi='zoxide query --interactive'

brewup() {
  local uv_before="" uv_after=""
  if command -v uv >/dev/null 2>&1; then
    uv_before="$(uv --version 2>/dev/null)"
  fi

  brew update && brew upgrade && brew cleanup || return $?

  if command -v uv >/dev/null 2>&1; then
    uv_after="$(uv --version 2>/dev/null)"
    if [[ "$uv_before" != "$uv_after" || ! -r "$HOME/.cache/uv/_uv.zsh" ]]; then
      mkdir -p "$HOME/.cache/uv"
      uv generate-shell-completion zsh > "$HOME/.cache/uv/_uv.zsh" 2>/dev/null
      echo "[brewup] refreshed uv completions ($uv_after)"
    fi
  fi
}

# Lazy-load NVM while preserving the default node selection.
export NVM_DIR="$HOME/.nvm"
_lazy_nvm() {
  unset -f node npm npx nvm
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
}
nvm()  { _lazy_nvm; command nvm "$@"; }
node() { _lazy_nvm; command node "$@"; }
npm()  { _lazy_nvm; command npm "$@"; }
npx()  { _lazy_nvm; command npx "$@"; }
_nvm_use_default_once() {
  unset -f _nvm_use_default_once
  command -v nvm >/dev/null || _lazy_nvm
  nvm use default &>/dev/null
}
precmd_functions+=(_nvm_use_default_once)

# zoxide.
eval "$(zoxide init zsh)"

# uv completions from cache.
if (( ZSH_HAS_TTY )) && command -v uv >/dev/null 2>&1; then
  _uv_dir="$HOME/.cache/uv"
  _uv_comp="$_uv_dir/_uv.zsh"
  [[ -r "$_uv_comp" ]] || {
    mkdir -p "$_uv_dir"
    uv generate-shell-completion zsh > "$_uv_comp" 2>/dev/null
  }
  source "$_uv_comp"
fi

# Input and shell behavior.
bindkey '^L' clear-screen
bindkey -v

# Local secrets.
[[ -f "$HOME/.secrets.zsh" ]] && source "$HOME/.secrets.zsh"

# yazi wrapper that keeps shell cwd in sync.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# vim: set ft=zsh
