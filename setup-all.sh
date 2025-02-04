#!/bin/bash

# Function to check if a package is installed
is_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to source the appropriate configuration file
source_shell_config() {
    if [[ "$SHELL" == */bash ]]; then
        source ~/.bash_profile
        source ~/.bashrc
    elif [[ "$SHELL" == */zsh ]]; then
        source ~/.zshrc
    fi
}

# Function to install isc-dhcp-client
install_dhcp_client() {
    if ! is_installed isc-dhcp-client; then
        sudo apt install -y isc-dhcp-client
        sudo dhclient -v
        (sudo crontab -l; echo "@reboot dhclient -v") | sudo crontab -
        
        # Commented out the reboot countdown and command
        # for i in {15..3..-3}; do
        #     echo "The system will reboot in $i seconds..."
        #     sleep 3
        # done
        
        # sudo reboot
    fi
}

# Function for general setup
general_setup() {
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt-get install -y vim git snapd exuberant-ctags ack wget jq libunwind8 fontconfig screen curl wget unzip zsh
    chsh -s "$(which zsh)"
    touch ~/.zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    setup_swap
    clone_personal_repo
    setup_vim
    install_nerd_fonts
}

# Function to setup swap file
setup_swap() {
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
}

# Function to clone personal repositories
clone_personal_repo() {
    mkdir -p ~/git-repos ~/bin
    cd ~/git-repos || exit
    git clone git@github.com:krisrmgua/kris-private-git.git
    git clone git@github.com:krisrmgua/kp.git
    cp ~/git-repos/kris-private-git/Code/BASH/gitpull ~/bin
}

# Function to setup Vim
setup_vim() {
    # Download the .vimrc file from the specified URL
    curl -o ~/.vimrc https://raw.githubusercontent.com/krisrmgua/kp/refs/heads/main/VIM/vimrc
    curl https://raw.githubusercontent.com/Shougo/neobundle.vim/master/bin/install.sh | bash
}

# Function to install Nerd Fonts
install_nerd_fonts() {
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts || exit
    curl -fLO https://github.com/ryanoasis/nerd-fonts/raw/HEAD/patched-fonts/DroidSansMono/DroidSansMNerdFont-Regular.otf
    wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
    unzip JetBrainsMono.zip && rm JetBrainsMono.zip
    fc-cache -fv
}

# Function to install Terraform
install_terraform() {
    git clone https://github.com/tfutils/tfenv.git ~/.tfenv
    echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
    echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.zshrc
    source_shell_config
    version_output=$(tfenv install)
    tf_version=$(echo "$version_output" | grep -oP "(?<=run 'tfenv use )\d+\.\d+\.\d+")
    tfenv use "$tf_version"
}

# Function to install AWS CLI
install_awscli() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws
}

# Function to install Azure CLI
install_azurecli() {
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
}

# Function to install PowerShell
install_powershell() {
    curl -sSL https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -o packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb
    rm packages-microsoft-prod.deb
    sudo apt-get update
    sudo apt-get install -y powershell
    pwsh -Command "Install-Module -Name Az -AllowClobber -Scope CurrentUser"
}

# Function to install Oh-My-Zsh
install_oh_my_zsh() {
    sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
    echo 'source ~/.powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
    sed -i 's/^ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
}

# Function to install Oh-My-Posh
install_oh_my_posh() {
    curl -s https://ohmyposh.dev/install.sh | bash -s
    mkdir -p ~/.oh-my-posh
    cp -rf /root/.cache/oh-my-posh/themes/* ~/.oh-my-posh
    curl -o ~/.oh-my-posh/kris-packsize.omp.json https://raw.githubusercontent.com/krisrmgua/kp/refs/heads/main/oh-my-posh/kris-packsize.omp.json
    echo 'eval "$(oh-my-posh init zsh)"' >> ~/.zshrc
    echo 'eval "$(oh-my-posh init zsh --config ~/.oh-my-posh/kris-packsize.omp.json)"' >> ~/.zshrc
}

# Function to configure Git
configure_git() {
    cat <<EOL > ~/.gitconfig
[user]
    email = $GIT_EMAIL
    name = $GIT_NAME
EOL

    if [[ $INSTALL_GCM == "y" ]]; then
        curl -sSL https://aka.ms/gcm/linux-install-source.sh | bash
        git config --global credential.helper "git-credential-manager"
        /usr/local/bin/git-credential-manager configure
        git config --global credential.https://dev.azure.com/.usehttppath false

        cat <<EOL >> ~/.gitconfig
[credential]
    helper = git-credential-manager
    helper =
    helper = /usr/local/bin/git-credential-manager
[credential "https://dev.azure.com"]
    useHttpPath = true
    helper = store
[credential "https://dev.azure.com/"]
    usehttppath = false
EOL
    fi
}

# Main script execution
install_dhcp_client
general_setup

echo "Do you want to install:"
echo "  1. oh-my-zsh"
echo "  2. oh-my-posh"
echo "  3. none"
read -p "Please enter the number of your choice: " INSTALL_SHELL_CHOICE

case "${INSTALL_SHELL_CHOICE,,}" in
    1)
        INSTALL_SHELL="zsh"
        ;;
    2)
        INSTALL_SHELL="posh"
        ;;
    3|none)
        INSTALL_SHELL="none"
        ;;
    *)
        echo "Invalid choice. Defaulting to none."
        INSTALL_SHELL="none"
        ;;
esac

read -p "Do you want to install Terraform? (y/n): " INSTALL_TERRAFORM
INSTALL_TERRAFORM="${INSTALL_TERRAFORM,,}"
read -p "Do you want to install AWS CLI? (y/n): " INSTALL_AWSCLI
INSTALL_AWSCLI="${INSTALL_AWSCLI,,}"
read -p "Do you want to install Azure CLI? (y/n): " INSTALL_AZURECLI
INSTALL_AZURECLI="${INSTALL_AZURECLI,,}"
read -p "Do you want to install PowerShell? (y/n): " INSTALL_POWERSHELL
INSTALL_POWERSHELL="${INSTALL_POWERSHELL,,}"
read -p "Do you want to install Git Credential Manager? (y/n): " INSTALL_GCM
INSTALL_GCM="${INSTALL_GCM,,}"

[[ $INSTALL_TERRAFORM == "y" || $INSTALL_TERRAFORM == "yes" ]] && install_terraform
[[ $INSTALL_AWSCLI == "y" || $INSTALL_AWSCLI == "yes" ]] && install_awscli
[[ $INSTALL_AZURECLI == "y" || $INSTALL_AZURECLI == "yes" ]] && install_azurecli
[[ $INSTALL_POWERSHELL == "y" || $INSTALL_POWERSHELL == "yes" ]] && install_powershell

if [[ $INSTALL_SHELL == "posh" ]]; then
    install_oh_my_posh
elif [[ $INSTALL_SHELL == "zsh" ]]; then
    install_oh_my_zsh
fi

read -p "Enter your full name for Git configuration: " GIT_NAME
read -p "Enter your email for Git configuration: " GIT_EMAIL

configure_git

echo "All steps complete!"