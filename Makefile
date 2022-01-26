# Basic install
# yay + AUR
# sway

sway:
  basic
  sudo pacman -S sway swaylock swayidle xorg-xwayland
  yay -S ly ulauncher
  mkdir -p ~/.config/{sway}
  cp /etc/sway/config ~/.config{sway}