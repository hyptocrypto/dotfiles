# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="/Users/julianbaumgartner/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	git
    gh
    brew
    golang	
    docker
    vi-mode
	docker-compose
	zsh-autosuggestions
	zsh-autocomplete
    zsh-syntax-highlighting	
    colored-man-pages
)

source $ZSH/oh-my-zsh.sh
# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='vim'
 else
  export EDITOR='vim'
 fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


####### PERSONAL #####
BREW_PATH="/opt/homebrew/bin"
GO_PATH="/Users/julianbaumgartner/go/bin"
VSCODE_PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin" 

export PATH="$PATH:$GO_PATH:$VSCODE_PATH:$BREW_PATH"


export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


function shellconf() {
        nvim ~/.zshrc && source ~/.zshrc
}

function vimconf() {
        cur_dir="$PWD"
        cd ~/.config/nvim &&
        nvim . &&
        cd "$cur_dir"
}

function makepr() {
        gh pr create --fill && gh pr view -w
}

function makerepo() {
        gh repo create --public --source . --remote origin
}

function startenv() {
	source .venv/bin/activate
}

function gbrename() {
    CURRENT_NAME="$(git rev-parse --abbrev-ref HEAD)"
    NEW_NAME=$1
    git branch -m $NEW_NAME
    git push origin :$CURRENT_NAME $NEW_NAME
    git push origin -u $NEW_NAME
}

function gmainpull() {
        MAIN="$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
        git pull & git checkout $MAIN && git pull
}

function gmain() {
        echo "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')"
}

function gcmain(){
    git checkout $(gmain)
}

function gcurr() {
        echo "$(git rev-parse --abbrev-ref HEAD)"
}

#Gitlab MergeReqeust
function makepr() {
        MAIN=$(gmain)
        CUR=$(gcurr)
        echo "$MAIN"
        git push -o merge_request.create -o merge_request.target=$MAIN origin $CUR
}

function gitreb() {
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if output=$(git status --porcelain) && [ -n "$output" ]; then
        echo "Stashing changes"
        STASHED=true
        git stash -q --include-untracked
    else
        echo "Working Tree Clean"
        STASHED=false
    fi

    MAIN_BRANCH=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')

    echo "Checking out $MAIN_BRANCH to pull latest changes"
    git checkout -q "$MAIN_BRANCH"
    git pull -q origin "$MAIN_BRANCH"

    echo "Returning to $CURRENT_BRANCH and rebasing onto $MAIN_BRANCH"
    git checkout -q "$CURRENT_BRANCH"
    git rebase -q "$MAIN_BRANCH"

    if $STASHED; then
        echo "Popping stashed changes"
        git stash pop -q
    fi
}


function gitmer() {
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    if output=$(git status --porcelain) && [ -n "$output" ]; then
        echo "Stashing changes"
        STASHED=true
        git stash -q --include-untracked
    else
        echo "Working Tree Clean"
        STASHED=false
    fi

    MAIN_BRANCH=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')

    echo "Checking out $MAIN_BRANCH to pull latest changes"
    git checkout -q "$MAIN_BRANCH"
    git pull -q origin "$MAIN_BRANCH"

    echo "Returning to $CURRENT_BRANCH and merging with $MAIN_BRANCH"
    git checkout -q "$CURRENT_BRANCH"
    git merge -q "$MAIN_BRANCH"

    if $STASHED; then
        echo "Popping stashed changes"
        git stash pop -q
    fi
}

function makeenv() {
    uv python install 3.13 && \
    uv init && \
    rm hello.py && \
    uv venv --python 3.13 && \
    source .venv/bin/activate && \
    uv add ipython black isort flake8 autoflake && \
    echo "[tool.ruff]
line-length = 88
extend-select = [\"I\", \"UP\"]
extend-ignore = [\"E501\"]  # Ignore line length errors
fix = true" >> pyproject.toml
}

function syncdot() {
    curr_dir=$(pwd)
    cd ~/dev/dotfiles
    git checkout main
    git pull
    cp omz/.zshrc ~/.zshrc
	cp .wezterm.lua ~/.wezterm.lua
    source ~/.zshrc
    cd "$curr_dir"
}

function mkcd (){
        mkdir -p -- "$1" &&
        cd -P "$1"
}

# ALIAS
alias n="nvim ."
alias cdd='cd ../'
alias cddd='cd ../../'
alias cdddd='cd ../../../'
alias cat='bat'
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gr='git rebase -i HEAD~2'
alias gcu='git commit -m "Update"'
alias ls='lsd --all --long --header'
alias c='stty sane && clear'
alias gitclear='git stash && git stash clear'
alias gcoo='git switch $(git branch --all | sed 's/^..//' | fzf)'

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/julianbaumgartner/Desktop/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/julianbaumgartner/Desktop/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/julianbaumgartner/Desktop/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/julianbaumgartner/Desktop/google-cloud-sdk/completion.zsh.inc'; fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion


# Custom key binings
bindkey -v
bindkey '\t\t' autosuggest-accept
bindkey -M viins 'jk' vi-cmd-mode
expand_and_accept_cmd() {
  zle expand-or-complete
  zle accept-line
}

# Register the widget
zle -N expand_and_accept_cmd

# Bind Enter (`^M`) in vi command mode (`vicmd`) to first expand, then execute
bindkey -M vicmd '^M' expand_and_accept_cmd

# Source the local shell conf
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

export PATH="$HOME/.local/bin:$PATH"
