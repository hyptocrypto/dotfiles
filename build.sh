#!/usr/bin/env bash
# Bootstrap a new Mac with my tools and settings. Idempotent: safe to re-run.
#
# Usage: ./build.sh   (run from anywhere; repo location is auto-detected)
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
    echo "Don't run with sudo - it makes files in \$HOME root-owned. It will prompt when needed." >&2
    exit 1
fi

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "dotfiles @ $(git -C "$REPO" log -1 --format='%h %s' 2>/dev/null || echo unknown)"
STATE_DIR="$HOME/.local/state/dotfiles"

# Earlier sudo runs can leave root-owned dirs in $HOME; take them back.
ME="$(id -un)"
for d in "$HOME/.oh-my-zsh" "$HOME/.config" "$HOME/.ssh" "$HOME/.local" "$HOME/dev"; do
    if [ -e "$d" ] && [ -n "$(find "$d" ! -user "$ME" -print -quit 2>/dev/null)" ]; then
        echo "Fixing ownership of $d (needs sudo)"
        sudo chown -R "$ME:staff" "$d"
    fi
done
mkdir -p "$STATE_DIR"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*" >&2; }

# Symlink $1 (repo path) to $2. Existing non-link targets are moved to .bak.
link() {
    local src="$REPO/$1" dst="$2"
    [ "$(readlink "$dst" 2>/dev/null)" = "$src" ] && return 0
    mkdir -p "$(dirname "$dst")"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
        echo "  backed up $dst"
    fi
    ln -sfn "$src" "$dst"
    echo "  linked $dst -> $src"
}

# Clone $1 into $2 if missing; if $3 (tag) given, make sure it is checked out.
clone() {
    local url="$1" dst="$2" tag="${3:-}"
    if [ ! -d "$dst/.git" ]; then
        git clone -q --depth 1 ${tag:+--branch "$tag"} "$url" "$dst"
    elif [ -n "$tag" ] && [ "$(git -C "$dst" describe --tags --exact-match 2>/dev/null)" != "$tag" ]; then
        git -C "$dst" fetch -q --depth 1 origin tag "$tag" && git -C "$dst" checkout -q "$tag"
    fi
}

# ---------------------------------------------------------------- Homebrew
step "Homebrew"
if [ ! -x /opt/homebrew/bin/brew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
# .zshrc adds this too; set it here so installers (lean-ctx) don't append
# PATH lines to ~/.zshrc, which is a symlink into this repo.
export PATH="$HOME/.local/bin:$PATH"
# Homebrew is single-user: if it was installed by another (e.g. deleted)
# account, brew can't write and zsh rejects its completions as insecure.
if [ "$(stat -f %Su /opt/homebrew)" != "$ME" ]; then
    echo "Taking ownership of /opt/homebrew (needs sudo)"
    sudo chown -R "$ME:admin" /opt/homebrew
fi
chmod -R go-w /opt/homebrew/share  # zsh compaudit: no group/world-writable fpath

step "Brew bundle (Brewfile)"
# Don't abort on one failed package (e.g. app already installed outside brew).
brew bundle --verbose --file="$REPO/Brewfile" || warn "some Brewfile entries failed - see output above"

# Font casks install into the *installing user's* ~/Library/Fonts, and brew
# considers them installed even for a different user. Reinstall if missing.
if ! ls "$HOME/Library/Fonts"/JetBrainsMonoNerdFont-* >/dev/null 2>&1; then
    brew reinstall --cask font-jetbrains-mono-nerd-font || warn "Nerd Font install failed"
fi

# pi is also in the Brewfile (npm entry); fall back if bundle skipped it.
command -v pi >/dev/null || npm install -g @earendil-works/pi-coding-agent || warn "pi install failed"

# ---------------------------------------------------------------- Shell
step "oh-my-zsh + plugins"
ZSH_DIR="$HOME/.oh-my-zsh"
if [ ! -f "$ZSH_DIR/oh-my-zsh.sh" ]; then
    # A previous broken run may have left a dir with only custom plugins in it.
    [ -d "$ZSH_DIR" ] && mv "$ZSH_DIR" "$ZSH_DIR.broken.$(date +%Y%m%d%H%M%S)"
    # Pass ZSH explicitly: an inherited $ZSH (from the calling shell) would
    # make the installer target the wrong directory.
    env -u ZSH_CUSTOM ZSH="$ZSH_DIR" RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="$ZSH_DIR/custom"
clone https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
# Pinned: newer zsh-autocomplete releases break (see SHELL-FIX.md).
clone https://github.com/marlonrichert/zsh-autocomplete.git "$ZSH_CUSTOM/plugins/zsh-autocomplete" 24.09.04
clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
mkdir -p "$HOME/.nvm"
# Stale completion caches from earlier broken runs cause compdef errors;
# zsh rebuilds them on next start.
rm -f "$HOME"/.zcompdump*

# ---------------------------------------------------------------- Dotfiles
step "Dotfiles (symlinks into $REPO)"
link omz/.zshrc             "$HOME/.zshrc"
link omz/.zprofile          "$HOME/.zprofile"
link .p10k.zsh              "$HOME/.p10k.zsh"
link .vimrc                 "$HOME/.vimrc"
link .gitconfig             "$HOME/.gitconfig"
link gitignore_global       "$HOME/.gitignore_global"
link .wezterm.lua           "$HOME/.wezterm.lua"
link nvim                   "$HOME/.config/nvim"
link lazygit/config.yml     "$HOME/.config/lazygit/config.yml"
link btop/btop.conf         "$HOME/.config/btop/btop.conf"
link gh/config.yml          "$HOME/.config/gh/config.yml"
link vscode/settings.json   "$HOME/Library/Application Support/Code/User/settings.json"
link raycast/scripts        "$HOME/dev/raycast_scripts"
# Karabiner docs: symlink the whole dir (not the file) so it detects changes.
link karabiner              "$HOME/.config/karabiner"
launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server" 2>/dev/null || true

# Machine-specific secrets/aliases live here; never tracked in git.
[ -f "$HOME/.zshrc.local" ] || { touch "$HOME/.zshrc.local"; echo "  created empty ~/.zshrc.local (copy secrets over manually)"; }

# ---------------------------------------------------------------- SSH
step "SSH key"
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -C "jbaumgartner93@gmail.com" -f "$HOME/.ssh/id_ed25519"
    echo "  New key - add it to GitHub: gh auth login && gh ssh-key add ~/.ssh/id_ed25519.pub"
fi
ssh-add --apple-use-keychain "$HOME/.ssh/id_ed25519" 2>/dev/null || true

# ---------------------------------------------------------------- pi
step "pi (coding agent)"
bash "$REPO/pi/install.sh" || warn "pi/install.sh failed - re-run after 'pi' + /login"

# ---------------------------------------------------------------- Raycast
step "Raycast"
RAYCONFIG="$REPO/raycast/raycast.rayconfig"
RAYMARK="$STATE_DIR/raycast-imported"
if [ ! -f "$RAYCONFIG" ]; then
    warn "no $RAYCONFIG - export from Raycast > Settings > Advanced > Export and commit it"
elif [ "$(cat "$RAYMARK" 2>/dev/null)" != "$(shasum -a 256 "$RAYCONFIG" | cut -d' ' -f1)" ]; then
    open -a Raycast "$RAYCONFIG"
    shasum -a 256 "$RAYCONFIG" | cut -d' ' -f1 >"$RAYMARK"
    echo "  Raycast import opened - enter the export password in Raycast."
    echo "  (rm $RAYMARK to import again)"
else
    echo "  already imported (re-imports automatically when the export changes)"
fi

# ---------------------------------------------------------------- macOS defaults
step "macOS defaults"
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 15
defaults write -g AppleInterfaceStyle -string Dark
defaults write -g AppleKeyboardUIMode -int 2           # full keyboard navigation
defaults write -g com.apple.swipescrolldirection -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock mru-spaces -bool false   # don't rearrange Spaces
defaults write com.apple.dock wvous-br-corner -int 14  # bottom-right = Quick Note
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv  # list view
defaults write com.apple.finder NewWindowTarget -string PfAF       # new window = Recents
# Free Cmd+Space for Raycast (disable Spotlight shortcut).
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
    '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
killall Dock Finder 2>/dev/null || true

step "Done"
echo "Log out/in for key repeat + Spotlight shortcut changes. Open a new terminal for shell config."
