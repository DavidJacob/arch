#!/bin/bash

# This script is based on Ermanno from EF - Linux Made Simple
# Check out this repo here: https://gitlab.com/eflinux/arch-basic
# Check out the channel here: https://www.youtube.com/channel/UCX_WM2O-X96URC5n66G-hvw

# Basic configuration
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
sed -i '177s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo root:password | chpasswd

# Install basic packages
pacman -S acpi acpid acpi_call alacritty alsa-utils avahi \
    base-devel bash-completion bluez bluez-utils bridge-utils \
    cups dialog dnsmasq dnsutils dosfstools efibootmgr flatpak \
    grub grub-btrfs gvfs gvfs-smb hplip inetutils ipset iptables-nft linux-headers \
    mtools networkmanager network-manager-applet nfs-utils nss-mdns ntfs-3g \
    openbsd-netcat openssh pipewire pipewire-alsa pipewire-jack pipewire-pulse \
    ranger reflector rsync terminus-font tlp wpa_supplicant xdg-user-dirs xdg-utils

# Configure grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable tlp
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable acpid

# Configure user
useradd -m david
echo :password | chpasswd
echo "david ALL=(ALL) ALL" >> /etc/sudoers.d/david


printf "\e[1;32mBasic install complete!.\e[0m"
