# Steps to install Arch Linux

1. Connect to a network using `iwctl`. You will be prompted for a password. Replace `wlan0` and `WilmFi` with you interface name and SSID.
   ```bash
   $ iwctl
   [iwd]# station wlan0 connect WilmFi
   password:
   ```
2. Sync the repos:
   ```bash
   $ pacman -Sy
   ```
3. Format the disks. First list them
   ```bash
   $ lsblk
   ```
   Use `gdisk` to create partitions.
   ```bash
   $ gdisk /dev/nvme0n1
   ```
   EFI partition:
   ```bash
   Command (? for help): n
   Partition number (1-128, default 1):
   First sector (34-104857566, default 2048) or{+-}size{KMGTP}:
   Last sector (2048-104857566, default 104857566) or{+-}size{KMGTP}: +350M
   Current type is 8300 (Linux filesystem)
   Hex code or GUID (L to show codes, Enter = 8300): ef00
   Changed partition type to 'EFI system partition'
   ```
   Linux partition:
   ```bash
   Command (? for help): n
   Partition number (2-128, default 2):
   First sector (34-104857566, default 718848) or{+-}size{KMGTP}:
   Last sector (718848-104857566, default 104857566) or{+-}size{KMGTP}:
   Current type is 8300 (Linux filesystem)
   Hex code or GUID (L to show codes, Enter = 8300):
   Changed partition type to 'Linux filesystem'
   ```
   Write changes to disk:
   ```bash
   Command (? for help): w
   ...
   ...
   Do you want to proceed? (Y/N): y
   ```
4. Format the EFI partition.
   ```bash
   $ mkfs.vfat /dev/nvme0n1p1
   ```
5. Prepare encryption of root volume:
   ```bash
   $ cryptsetup luksFormat /dev/nvme0n1p2
   ...
   Are you sure? (Type 'yes' in capital letters): YES
   Enter passphrase for /dev/nvme0n1p2:
   Verify passphrase:
   ```
   Open partition:
   ```bash
   $ cryptsetup luksOpen /dev/nvme0n1p2 cryptroot
   Enter passphrase for /dev/nvme0n1p2:
   ```
6. Format the `btrfs` partition:
   ```bash
   $ mkfs.btrfs /dev/mapper/cryptroot
   ```
7. Create `btrfs` subvolumes
   ```bash
   $ mount /dev/mapper/cryptroot /mnt
   $ btrfs subvolume create /mnt/@
   $ btrfs subvolume create /mnt/@home
   $ btrfs subvolume create /mnt/@var
   ```
8. Unmount the device
   ```bash
   $ umount /mnt
   ```
9. Mount the `@` subvolume with options:
   ```bash
   $ mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@ /dev/mapper/cryptroot /mnt
   ```
   Create directories for all other volumes:
   ```bash
   mkdir -p /mnt/{boot/efi,home,var}
   ```
   Remount the `@home` subvolume with options:
   ```bash
   $ mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@home /dev/mapper/cryptroot /mnt/home
   ```
   Remount the `@var` subvolume with options:
   ```bash
   $ mount -o noatime,compress=zstd,ssd,discard=async,space_cache=v2,subvol=@var /dev/mapper/cryptroot /mnt/var
   ```
   Mount EFI partition:
   ```bash
   $ mount /dev/nvme0n1p1 /mnt/boot/efi
   ```
   Verify everything mounted correctly:
   ```bash
   $ lsblk
   ```
10. Install the base system:
    ```bash
    $ pacstrap /mnt \
       base linux linux-firmware \
       intel-ucode btrfs-progs \
       git vim
    ```
11. Create `fstab`:
    ```bash
    genfstab -U /mnt >> /mnt/etc/fstab
    ```
12. Enter installation
    ```bash
    arch-chroot /mnt
    ```
13. Configure the system. Check out [this script](https://gitlab.com/eflinux/arch-basic) to make your own version.
14. Edit `mkinitcpio.conf` to add support for `btrfs` and encryption.
    ```bash
    MODULES=(btrfs)
    ...
    HOOKS=(...block enrcypt filesystems...)
    ```
    Recreate image:
    ```bash
    mkinitcpio -p linux
    ```
15. TODO: figure out how to do this with `refind`
    Edit `/etc/default/grub.cfg`. Replace `${UUID}` with the UUID of the encrypted partition, not the mapper device:
    ```bash
    ...
    GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=${UUID}:cryptroot root=/dev/mapper/cryptroot"
    ...
    ```
    Regenerate `grub` config:
    ```bash
    grub-mkconfig -o /boot/grub/grub.cfg
    ```
16. Exit `chroot`, unmount `/mnt` folder and reboot.
17. Connect to the network:
    ```bash
    sudo nmcli --ask d wifi connect ${SSID}
    ```
18. Install and configure sway:
    ```bash
    sudo pacman -S sway swaylock swayidle xorg-xwayland
    mkdir ~/.config/sway
    cp /etc/sway/config ~/.config/sway/
    ```
    NOTE: at time of writing there is an issue with the `swayidle` install which causes the `pacman` command to fail. I simply removed it for this install.
19. Install `yay`:
    ```bash
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    ```
20. Configure Ulauncher.
    Add this line to set it as Sway menu shortcut:
    ```bash
    set $menu ulauncher | xargs swagmsg exec --
    ```
21. Configure hardware keys. You'll need to install a package for screen brightness:
    ```bash
    yay -S brightnessctl
    ```
    Add [the following directives](https://wiki.archlinux.org/title/Sway#Custom_keybindings) to your sway config.
22. Install and configure waybar:
    ```bash
    yay -S community/waybar
    mkdir ~/.config/waybar
    cp /etc/xdg/waybar/* ~/.config/waybar/
    ```
23. Install nerd fonts:
    ```bash
    yay -S nerd-fonts-complete
    ```
24. Authorize CalDigit TS3 Plus (`bolt` package required):
    ```bash
    $ bolt list
    Caldigit, Inc. TS3 Plus
    ...
    ...
       uuid: UUID
    ...
    $ bolt authorize UUID
    ```
25. Configure DDC/DI:
    ```bash
    usermod -aG i2c david
    ```
    Load `i2c-dev` kernel module on startup by creating `/etc/modules-load.d/i2c-dev.conf`:
    ```
    # Support DDC/DI of external monitors via ddcutil
    i2c-dev
    ```
