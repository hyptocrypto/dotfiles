# This script sets up most of what is needed for a new device

# Install brew and packages
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install vim neovim clicklick imagemagick git lsd bat git-delta gh lazygit lazydocker k9s uv go python@3.13 sqlite btop fzf
brew install --cask spotify brave-browser ghostty raycast karabiner-elements visual-studio-code

# Shell stuff
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git $HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete
git clone --depth 1 -- https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone --depth 1 -- https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting

# SSH
ssh-keygen -t ed25519 -C "jbaumgartner93@gmail.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Dotfiles
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/ghostty/"
cp "$HOME"/dev/dotfiles/omz/.zshrc "$HOME/"
cp "$HOME"/dev/dotfiles/.vimrc "$HOME/"
cp "$HOME"/dev/dotfiles/.gitconfig "$HOME/"
cp "$HOME"/dev/dotfiles/.p10k.zsh "$HOME/"
cp "$HOME"/dev/dotfiles/ghostty_config "$HOME/.config/ghosty/config"
cp "$HOME"/dev/dotfiles/nvim "$HOME/.config/"

# Raycast
if [ -d "$HOME/dev/dotfiles/raycast/com.raycast.macos" ]; then
    echo "Restoring Raycast settings..."
    cp -R "$HOME/dev/dotfiles/raycast/com.raycast.macos" "$HOME/Library/Application Support/"
else
    echo "No Raycast settings found in dotfiles. Skipping restore."
fi
cp "$HOME"/dev/dotfiles/raycast/raycast_scripts "$HOME/dev/"

# Misc mac settings
defaults write -g KeyRepeat -int 1         # Fastest key repeat
defaults write -g InitialKeyRepeat -int 10 # Short delay before repeat
echo "Keyboard key repeat speed set. You may need to log out for changes to take effect."
