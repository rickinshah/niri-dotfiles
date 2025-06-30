#!/bin/bash
set -e

# Install AUR Helper - yay
sudo pacman -S --needed base-devel git

# Check yay exists or not
if ! command -v yay &> /dev/null; then
  git clone https://aur.archlinux.org/yay.git ~/yay
  cd ~/yay && makepkg -si
fi

#Cleanup yay
rm -rf ~/yay

# Install required packages
if [[ -f packages.txt ]]; then
    yay -S --needed --noconfirm $(< packages.txt)
else
    echo "packages.txt not found"
    exit 1
fi

# Clone the repo
git clone https://github.com/rickinshah/niri-dotfiles.git ~/

# Clone the catppuccin-gtk-theme
git clone https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git ~/themes-temp
bash ~/themes-temp/themes/install.sh
gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Dark'
mkdir -p ~/.config/gtk-4.0
cp -r ~/.themes/Catppuccin-Dark/gtk-4.0/* ~/.config/gtk-4.0/

# Cleanup themes-temp
rm -rf ~/themes-temp

# Check sddm is enabled or not
if ! systemctl is-active --quiet sddm.service; then
    echo "Enabling sddm..."
    sudo systemctl enable sddm.service
fi

# Start all the needed services
for service in waybar avizo swaybg swayidle cliphist kdeconnect-indicator auto-hide-waybar plasma-polkit-agent; do
  read -rp "Do you want to enable'$service.service'? [y/N] " answer
  case "$answer" in
    [yY][eE][sS]|[yY])
      systemctl --user add-wants niri.service "$service.service"
      echo "'$service.service' enabled."
      ;;
    *)
      echo "Skipped '$service.service'."
      ;;
  esac
done

systemctl --user daemon-reload

# neovim configs
[ -d ~/.config/nvim ] || git clone https://github.com/rickinshah/nvim-config.git ~/.config/nvim

# Setup completed
echo "Setup completed! Reboot and select Niri from the login screen."
