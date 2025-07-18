# powerlevel10k configuration
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# enable extended globbing
export ZSH="$HOME/.oh-my-zsh"

# powerlevel10k theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# additional plugins
autoload -Uz compinit
compinit

# Enable cache for completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"

# Enable menu selection
zstyle ':completion:*' menu select

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'


# Fuzzy matching for misspelled completions
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Group matches and describe groups
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'

# Colors in completion
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Kill command completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'

plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker kubectl npm pip)

# source oh-my-zsh
source $ZSH/oh-my-zsh.sh

# source zsh-syntax-highlighting
source /Users/anshkumar/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#Custom aliases
# Set nvim as the default editor
export EDITOR='nvim'
export VISUAL='nvim'
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias ls='colorls'
alias zshrc='vi ~/.zshrc'
alias conf='cd ~/.config/ && vi .'
alias szshrc='source ~/.zshrc'
alias venv='python3.12 -m venv venv'
alias svenv='source venv/bin/activate'
alias c='clear'
alias y='yazi'
alias brewup="brew update && brew upgrade && brew cleanup"

# ssh
alias homelab='ssh username@ip'

# Zoxide interactive
alias zi='zoxide query --interactive'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
        . "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
    else
        export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# completions
# Enable docker completion if not already enabled
if [ $commands[docker] ]; then
    source <(docker completion zsh)
fi

# Node/npm completion
if [ $commands[npm] ]; then
    source <(npm completion)
fi

# Kubectl completion
if [ $commands[kubectl] ]; then
    source <(kubectl completion zsh)
fi

# pip completion
if [ $commands[pip] ]; then
    eval "$(pip completion --zsh)"
fi

# export nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
nvm use default &> /dev/null

# JDK Runtime@21
export PATH="/opt/homebrew/opt/openjdk@21/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk@21"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@21/include"

# Zoxide
eval "$(zoxide init zsh)"
