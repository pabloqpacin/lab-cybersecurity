#!/usr/bin/env bash

# ~~# RESUMEN: paquetes de terminal y gráficos para el usuario ~~

# # Ejecutar en Ubuntu Desktop 22.04 LTS como usuario (no root):
# bash <(curl -fsSL https://github.com/pabloqpacin/lab_asterisk/raw/main/scripts/Ubuntu_2404-base.sh)


set_variables() {
    read -p "Saltar confirmaciones tipo 'apt install <package>' e instalar todo? [Y/n] " opt
    case $opt in
        'N'|'n') sa_install="sudo apt-get install"      ;;
        *)       sa_install="sudo apt-get install -y"   ;;
    esac
    sa_update="sudo apt-get update"
}

disable_cups(){
    if [ $(systemctl is-enabled cups) == 'enabled' ]; then
        sudo systemctl disable --now cups.service
        sudo systemctl disable --now cups.socket
        sudo systemctl mask --now cups.service
    fi
}

snap_update(){
    sudo snap refresh
}

apt_update_install(){
    if [ ! -e "/etc/apt/apt.conf.d/99show-versions" ]; then
        echo 'APT::Get::Show-Versions "true";' | sudo tee /etc/apt/apt.conf.d/99show-versions
    fi

    $sa_update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

    $sa_install build-essential curl git net-tools wget wl-clipboard xclip xsel
    $sa_install bat fd-find fzf grc jq keepassxc nmap ripgrep tldr tmux vim
    $sa_install --no-install-recommends neofetch

    if ! command -v bat &>/dev/null && command -v batcat &>/dev/null; then
        sudo mv $(which batcat) /usr/bin/bat
    fi
    if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
        sudo mv $(which fdfind) /usr/bin/fd
    fi
    if [ ! -d ~/.local/share ]; then
        mkdir ~/.local/share
    fi
    tldr --update

    if ! command -v lf &>/dev/null; then
        cd /tmp
        wget -q https://github.com/gokcehan/lf/releases/download/r32/lf-linux-amd64.tar.gz
        tar xf lf-linux-amd64.tar.gz
        sudo chmod +x lf
        sudo chown root:root lf
        sudo mv lf /usr/local/bin/lf
        cd $HOME
    fi

    if ! command -v eza &>/dev/null; then
        cd /tmp
        wget -q https://github.com/eza-community/eza/releases/download/v0.18.17/eza_x86_64-unknown-linux-gnu.tar.gz
        tar xf eza_x86_64-unknown-linux-gnu.tar.gz
        sudo chmod +x eza
        sudo chown root:root eza
        sudo mv eza /usr/local/bin/eza
        cd $HOME
    fi
}

setup_ssh(){
    if systemctl is-enabled ssh 2>&1 | grep 'No such file' > /dev/null; then
        $sa_install openssh-server
    elif [ $(systemctl is-enabled ssh) == 'not-found' ]; then
        $sa_install openssh-server
    fi

    if [ $(systemctl is-enabled ssh) == 'disabled' ]; then
        sudo systemctl enable --now ssh
    fi

    # TODO: config
}

clone_symlink_dotfiles() {
    if true; then
        sudo mkdir /root/.config 2>/dev/null
    fi
    if [ ! -d ~/.config ]; then
        mkdir ~/.config &>/dev/null
    fi
    if [ ! -d ~/dotfiles ]; then
        git clone --depth 1 https://github.com/pabloqpacin/dotfiles $HOME/dotfiles
    fi
    if [ ! -L ~/.config/alacritty ]; then
        ln -s ~/dotfiles/.config/alacritty ~/.config
    fi
    if [ ! -L ~/.config/bat ]; then
        ln -s ~/dotfiles/.config/bat ~/.config
        sudo ln -s ~/dotfiles/.config/bat /root/.config
    fi
    if [ ! -L ~/.config/lf ]; then
        ln -s ~/dotfiles/.config/lf ~/.config
        sudo ln -s ~/dotfiles/.config/lf /root/.config
    fi
    if [ ! -L ~/.config/tmux ]; then
        ln -s ~/dotfiles/.config/tmux ~/.config
    fi
    if [ ! -L ~/.vimrc ]; then
        if [ -e ~/.vimrc ]; then mv ~/.vimrc{,.bak}; fi
        ln -s ~/dotfiles/.vimrc ~/ &&
        sudo ln -s ~/dotfiles/.vimrc /root/
    fi
}

setup_zsh(){
    $sa_update && $sa_install zsh

    if [ ! -d ~/.oh-my-zsh ]; then
        yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        bash $HOME/dotfiles/scripts/setup/omz-msg_random_theme.sh
    fi
    
    if [ $(echo $SHELL | awk -F '/' '{print $(NF)}') != 'zsh' ]; then
        sudo chsh -s $(which zsh) $USER
    fi
    
    if [ ! -L ~/.zshrc ]; then
        mv ~/.zshrc{,.bak} &&
        ln -s ~/dotfiles/.zshrc ~/

        sed -i '/ubuntu/ {/MANPAGER/s/^/# /}' ~/.zshrc
    fi
    
    if [[ ! -d ~/dotfiles/zsh/plugins/zsh-autosuggestions || ! -d ~/dotfiles/zsh/plugins/zsh-syntax-highlighting ]]; then
        bash $HOME/dotfiles/zsh/plugins/clone-em.sh
    fi
}

setup_nvim(){
    if ! command -v nvim &>/dev/null; then
        $sa_install build-essential cmake gettext ninja-build unzip
        git clone --depth 1 https://github.com/neovim/neovim.git /tmp/neovim
        cd /tmp/neovim && make CMAKE_BUILD_TYPE=Release && sudo make install && cd $HOME
    fi

    if ! command -v npm &>/dev/null; then
        if [ ! -s "$HOME/.nvm/nvm.sh" ]; then
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        fi
        if ! command -v node &>/dev/null && ! command -v npm &>/dev/null; then
            [ -s "$HOME/.nvm/nvm.sh" ] && \. "$HOME/.nvm/nvm.sh"
            nvm install node
        fi
    fi

    # TODO: revisar recomendaciones del desarrollador; quizá usar otro plugin-manager este verano
    if [ ! -d ~/.local/share/nvim/site/pack/packer ]; then
        git clone --depth 1 https://github.com/wbthomason/packer.nvim \
            ~/.local/share/nvim/site/pack/packer/start/packer.nvim
    fi

    if [ ! -L ~/.config/nvim ]; then
        sudo mkdir -p /root/.config/nvim &&
        sudo ln -s ~/dotfiles/.vimrc /root/.config/nvim/init.vim

        ln -s ~/dotfiles/.config/nvim ~/.config
        cd ~/.config/nvim && {
            read -p "Pasa los mensajes de error con <INTRO>, luego escribe :so <INTRO>, :PackerSync <INTRO> y :qa <INTRO> " null
            nvim lua/pabloqpacin/packer.lua
            read -p "Pasa los mensajes de error con <INTRO>, luego escribe :Mason <INTRO> y :qa <INTRO> " null
            nvim after/plugin/lsp.lua
            cd $HOME
        }
    fi
}

install_docker(){
    if ! command -v docker &>/dev/null; then
        sh <(curl -sSL https://get.docker.com)
        sudo usermod -aG docker $USER
    fi
}

install_nerdfonts(){
    if [ ! -d ~/.fonts ]; then
        mkdir ~/.fonts
    fi

    if ! fc-cache -v | grep -q 'Fira'; then
        wget -qO /tmp/FiraCode.zip 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip'
        unzip -q /tmp/FiraCode.zip -d ~/.fonts/FiraCodeNerdFont
    fi
    if ! fc-cache -v | grep -q 'Cascadia'; then
        wget -qO /tmp/CascadiaCode.zip 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip'
        unzip -q /tmp/CascadiaCode.zip -d ~/.fonts/CascadiaCodeNerdFont
    fi

    fc-cache -f
}

install_desktop_pkgs(){

    if ! command -v alacritty &>/dev/null; then
        sudo add-apt-repository ppa:aslatter/ppa -y
        $sa_update && $sa_install alacritty
    fi

    if ! command -v brave-browser &>/dev/null; then
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
            https://brave-browser-apt-release.s3.brave.com/ stable main" \
            | sudo tee /etc/apt/sources.list.d/brave-browser-release.list
        $sa_update && $sa_install brave-browser
    fi

    if ! command -v codium &>/dev/null; then
        wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
            | gpg --dearmor \
            | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg ] https://download.vscodium.com/debs vscodium main' \
            | sudo tee /etc/apt/sources.list.d/vscodium.list
        $sa_update && $sa_install codium

        bash $HOME/dotfiles/scripts/setup/codium-extensions.sh
        ln -s ~/dotfiles/.config/code/User/settings.json ~/.config/VSCodium/User/settings.json
    fi

}

# info_vbox_additions(){
#     echo -e "\nInstalamos los drivers de VirtualBox:"
#     echo "- VirtualBox: Devices > Insert Guest Additions CD image..."
#     read -p "- Ubuntu: /media/setesur/VBox_GAs_6.1.50 > Click derecho en 'autorun.sh' > Ejecutar " null
# }


# ---

if true; then
    set_variables
    disable_cups
    snap_update
    apt_update_install
    clone_symlink_dotfiles

    case $(echo $sa_install | awk '{print $(NF)}') in
        '-y')
            setup_zsh
            setup_nvim
        ;;
        *)
            opt_zsh=''
            while [[ $opt_zsh != 'y' && $opt_zsh != 'n' ]]; do
                read -p "Establecer zsh [y/n]? " opt_zsh
            done
            if [[ $opt_zsh == 'y' ]]; then
                setup_zsh
            fi

            opt_nvim=''
            while [[ $opt_nvim != 'y' && $opt_nvim != 'n' ]]; do
                read -p "Instalar y configurar Neovim [y/n]? " opt_nvim
            done
            if [[ $opt_nvim == 'y' ]]; then
                setup_nvim
            fi
        ;;
    esac

    install_docker
    install_nerdfonts
    install_desktop_pkgs
    # info_vbox_additions
fi

echo "" && neofetch && sudo grc docker ps -a && echo -e "\n" && df -h | grep -e '/$' -e 'Mo'
[ -f /var/run/reboot-required ] && echo -e "\nReinicia la máquina.\n"


# ---

# # Importante para AnyDesk...
# set_x11_vbox(){}
    # $sa_install virtualbox-guest-utils virtualbox-guest-x11
    # sudo sed -i '/WaylandEnable/s/^#//' /etc/gdm3/custom.conf || {
    # echo "EN OPCIONES DE VBOX, SELECCIONA '3D Acceleration'"
    # echo "AL HACER LOGIN, SELECCIONA 'Ubuntu en Xorg"
    # }
# }


# more_installs(){
    # PERHAPS: btm btop devilspie git-delta ipcalc kitty mycli vim zoxide       # TODO: flameshot alt. for wayland
    # $sa_install --no-install-recommends python3-pip python3-venv oneko
    # $snap_install cheat


    # if ! command -v anydesk &>/dev/null && ! flatpak list 2>/dev/null | grep -q 'anydesk'; then
    #     wget -qO - https://keys.anydesk.com/repos/DEB-GPG-KEY | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/anydesk-archive-keyring.gpg
    #     echo "deb http://deb.anydesk.com/ all main" | sudo tee /etc/apt/sources.list.d/anydesk-stable.list
    #     $sa_update && $sa_install anydesk
    #     sudo systemctl disable anydesk
    # fi

    # if ! command -v nmapsi4 &>/dev/null; then
    #     $sa_install nmapsi4
    # fi

    # if ! command -v wireshark &>/dev/null; then
    #     read -p "En el menú que aparecerá, selecciona Yes " null  
    #     $sa_update && $sa_install wireshark tshark
    #     sudo usermod -aG wireshark $USER
    # fi

    # if ! command -v keepassxc &>/dev/null; then
    #     $sa_install keepassxc
    #     mkdir ~/KeePassXC
    #     # yes 'changeme' | head -n 2 | keepassxc-cli db-create ~/KeePassXC/example.kdbx -p
    #     # keepassxc-cli add -u pablo.quevedo@setesur.com ~/KeePassXC/Passwords.kdbx GoogleWorkspace -p
    #     # xdg-open https://keepassxc.org/docs/KeePassXC_UserGuide#_setup_browser_integration
    # fi


# }
