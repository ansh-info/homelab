
# ===== Powerlevel10k Instant Prompt (keep at very top) =====
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ===== Paths =====
export PATH="/opt/homebrew/opt/openjdk@21/bin:/Library/TeX/texbin:/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# ===== Oh My Zsh =====
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)
zstyle ':omz:update' mode disabled

# ===== Completions (quiet, cached) =====
autoload -Uz compinit
# add optional completion dirs before compinit
[[ -d /Users/anshkumar/.docker/completions ]] && fpath=(/Users/anshkumar/.docker/completions $fpath)
# Use versioned dump; skip expensive security audit
if [[ -r ~/.zcompdump-$ZSH_VERSION ]]; then
  compinit -C -d ~/.zcompdump-$ZSH_VERSION
else
  compinit -i -d ~/.zcompdump-$ZSH_VERSION
fi

# Your completion styles
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

# ===== Source Oh My Zsh (loads plugins) =====
source $ZSH/oh-my-zsh.sh

# ===== Powerlevel10k speed knobs =====
typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0.2
typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN='~/(Library|Movies|node_modules|.cache)(/|$)|/Volumes(/|$)'
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ===== Prompt-related plugins order =====
# Keep syntax highlighting LAST so it sees the final prompt
if [[ -r /Users/anshkumar/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /Users/anshkumar/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# ===== Editor & Aliases =====
export EDITOR='nvim'
export VISUAL='nvim'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias ls='eza'
alias zshrc='vi ~/.zshrc'
alias conf='cd ~/.config/ && vi .'
alias szshrc='source ~/.zshrc'
alias svenv='source .venv/bin/activate'
alias c='clear'
alias y='yazi'
# alias brewup="brew update && brew upgrade && brew cleanup"
alias zi='zoxide query --interactive'
alias bat='cat'


# Smarter brew updater + uv completion refresh
brewup() {
  # Remember uv version (if present) before upgrade
  local uv_before="" uv_after=""
  if command -v uv >/dev/null 2>&1; then
    uv_before="$(uv --version 2>/dev/null)"
  fi

  # Do the usual Homebrew maintenance
  brew update && brew upgrade && brew cleanup || return $?

  # If uv exists, refresh completion when needed
  if command -v uv >/dev/null 2>&1; then
    uv_after="$(uv --version 2>/dev/null)"
    if [[ "$uv_before" != "$uv_after" || ! -r "$HOME/.cache/uv/_uv.zsh" ]]; then
      mkdir -p "$HOME/.cache/uv"
      uv generate-shell-completion zsh > "$HOME/.cache/uv/_uv.zsh" 2>/dev/null
      echo "[brewup] refreshed uv completions ($uv_after)"
    fi
  fi
}

# ===== NVM (lazy load; preserves default-node behavior) =====
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

# ===== Conda (lazy, no Python subprocess at startup) =====
export CONDA_HOME="/opt/homebrew/Caskroom/miniconda/base"
export PATH="$CONDA_HOME/bin:$PATH"  # discover `conda` without activating base
__load_conda() {
  unset -f conda __conda_hashr
  if [[ -f "$CONDA_HOME/etc/profile.d/conda.sh" ]]; then
    . "$CONDA_HOME/etc/profile.d/conda.sh"
  fi
  # To auto-activate base each session, uncomment:
  # conda activate base >/dev/null 2>&1
}
conda() { __load_conda; conda "$@"; }
__conda_hashr() { __load_conda; hash -r; }

# ===== zoxide =====
eval "$(zoxide init zsh)"

# ===== uv / uvx completions (cached, no per-launch exec) =====
# Generate once, then source from cache
_uv_dir="$HOME/.cache/uv"
_uv_comp="$_uv_dir/_uv.zsh"
if command -v uv >/dev/null; then
  [[ -r "$_uv_comp" ]] || { mkdir -p "$_uv_dir"; uv generate-shell-completion zsh >"$_uv_comp" 2>/dev/null; }
  source "$_uv_comp"
fi
# If you really want a separate uvx completion file, uncomment below:
# _uvx_comp="$_uv_dir/_uvx.zsh"
# if command -v uvx >/dev/null; then
#   [[ -r "$_uvx_comp" ]] || { mkdir -p "$_uv_dir"; uvx --generate-shell-completion zsh >"$_uvx_comp" 2>/dev/null; }
#   source "$_uvx_comp"
# fi

# ===== Built-in clear (instant) =====
bindkey '^L' clear-screen

# ===== Secrets (keep API keys out of this file) =====
[[ -f "$HOME/.secrets.zsh" ]] && source "$HOME/.secrets.zsh"

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="/opt/homebrew/opt/perl/bin:$PATH"
export PATH="/Library/TeX/texbin:$PATH"

# Create a new LaTeX file from a template
texnew() {
local fname="$1"
if [[ -z "$fname" ]]; then
    printf "New LaTeX filename (without .tex): "
    IFS= read -r fname
fi
if [[ -z "$fname" ]]; then
    echo "Aborted: empty filename."
    return 1
fi

# Ensure .tex extension

[[ "$fname" != *.tex ]] && fname="${fname}.tex"

# Confirm overwrite

if [[ -e "$fname" ]]; then
    if ! read -q "REPLY?File '$fname' exists. Overwrite? [y/N] "; then
      echo
      echo "Aborted."
      return 1
    fi
    echo
fi

# Write template

cat > "$fname" <<'EOF'
% !TeX TS-program = pdflatex
\documentclass[11pt,a4paper]{article}

% Encoding, fonts, and micro-typography
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc} % Not needed for Lua/XeLaTeX
\usepackage{lmodern}
\usepackage{microtype}

% Page layout
\usepackage[a4paper,margin=1in]{geometry}

% Math and symbols
\usepackage{amsmath,amssymb,amsthm}

% Figures, tables, colors
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{booktabs}

% Units and numbers
\usepackage{siunitx}

% Links and cross-references
\usepackage{hyperref}
\usepackage[nameinlink,capitalise,noabbrev]{cleveref}
\hypersetup{
colorlinks=true,
linkcolor=blue,
citecolor=magenta,
urlcolor=blue
}

% Metadata
\title{Your Title}
\author{Your Name}
\date{\today}

\begin{document}
\maketitle

\begin{abstract}
A short abstract describing the document.
\end{abstract}

\tableofcontents
\newpage

\section{Introduction}
Hello, \LaTeX{} from VimTeX!

\section{Math}
Einstein's famous equation is shown in \cref{eq:einstein}.
\begin{equation}\label{eq:einstein}
E = mc^2
\end{equation}

\section{Figure}
\begin{figure}[h]
\centering
% \includegraphics[width=0.7\linewidth]{path/to/image}
\caption{An example figure.}
\label{fig:example}
\end{figure}

\section{Links}
See \href{https://example.com}{a link}.

\section{Conclusion}
A brief conclusion.

% \bibliographystyle{unsrt}
% \bibliography{references}

\end{document}
EOF

echo "Created '$fname'. Open with: nvim '$fname'"
}
