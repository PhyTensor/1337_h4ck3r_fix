# Arch Linux with Hyprland and BTRFS

## Set the console keyboard layout and font

List available layouts

```
localectl list-keymaps
```

Set the layout

```
loadkeys de-latin1
```

## Verify the boot mode

To verify the boot mode, check the UEFI bitness:

cat /sys/firmware/efi/fw_platform_size

### Connect to the internet

iwctl

station wlan0 get-networks

station wlan0 connect <essid>

exit

ping ping.archlinux.org

### Synchronize pacman packages

pacman -Syy

## Update system clock

Check if the ntp is active and if the time is right

```
timedatectl
```

In case it is not active, you can do

```
timedatectl set-ntp true
```

## Partition the disks

### Mount Points

/boot
/

## Format the partitions

mkfs.fat -F 32 /dev/nvme0n1p1

mkfs.btrfs /dev/nvme0n1p2

mkswap /dev/nvme0n1p3

## Mount the file systemss

Correctly mount al filesystems to the `/mnt`

mount --mkdir /dev/nvme0n1p1 /mnt/boot

mount /dev/nvme0n1p2 /mnt

swapon /dev/nvme0n1p3

## Creating subvolumes

btrfs subvolume create /mnt/@

btrfs subvolume create /mnt/@/var/tmp
btrfs subvolume create /mnt/@/var/log
btrfs subvolume create /mnt/@/var/cache
btrfs subvolume create /mnt/@/opt
btrfs subvolume create /mnt/@/.snapshots

Unmount the roof fs

umount /mnt

Mount the subvolumes

mount -o compress=zstd,subvol=@ /dev/nvme0n1p2 /mnt

## Installation

Install essential packages into the new filesystem

pacstrap -K /mnt base base-devel linux-zen linux-lts linux-firmware sudo fish git btrfs-progs vim amd-ucode openssh networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

## Configure the system

### Fstab

Generate fstab

genfstab -U /mnt >> /mnt/etc/fstab

Check if fstab is fine ( it is if you've faithfully followed the previous steps )

```
cat /mnt/etc/fstab
```

### Chroot

arch-chroot /mnt

### Time

ln -sf /usr/share/zoneinfo/Africa/Nairobi /etc/localtime

hwclock --systohc

### Localization

locale-gen

or

echo "LANG=en_US.UTF-8" > /etc/locale.conf

Set the console keyboard layout

echo "KEYMAP=de-latin1" > /etc/vconsole.conf

### Network configuration

Create hostname file:

echo "archlinux" > /etc/hostname

### Add new users and setup passwords

useradd -mG wheel -s /bin/bash <username>

passwd <username>

EDITOR=vim visudo

#### Add Wheel to group to sudoers file to allow users to run sudo

```
$ visudo
    [uncomment following line in file]
    %wheel ALL=(ALL) ALL
```

### Initramfs

mkinitcpio -P

### Root password

passwd root

### Boot loader

Install and configure grub

pacman -S grub efibootmgr

grub-install --target=x86_64-efi --efi-directory=/boot --recheck

grub-mkconfig -o /boot/grub/grub.cfg

### Network stack

pacman -Syu dhcpd networkmanager resolveconf

systemctl enable dhcpd

systemctl enable NetworkManager

systemctl enable systemd-resolved

## Reboot

exit the chroot environmenmt

exit

umount /mnt/boot

umount /mnt

reboot

## On Login

Enable and start the time synchronization service

```
timedatectl set-ntp true
```

## Video Drivers

sudo pacman -Syu mesa vulkan-radeon libva-mesa-driver mesa-vdpau lib32-mesa lib32-vulkan-radeon lib32-libva-mesa-driver lib32-mesa-vdpau

## Hyprland

sudo pacman -Syu hyprland wofi waybar

## Display manager

sudo pacman -Syu sddm

sudo systemctl enable sddm

## Gaming

sudo pacman -Syu steam gamemode wine proton

## Battery

sudo pacman -Syu auto-cpufreq
