# This script sets up most of what is needed for a new device
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git lsd bat delta gh lazygit lazydocker
brew install --cask font-jetbrains-mono-nerd-font spotify brave-browser wezterm

# powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
