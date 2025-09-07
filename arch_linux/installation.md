# Arch Linux with Hyprland and BTRFS

Use Ctrl-l to clear the terminal

## Set the console keyboard layout and font

List available layouts

```
localectl list-keymaps
```

Set the layout

```
loadkeys us
```

## Verify the boot mode

To verify the boot mode, check the UEFI bitness:

cat /sys/firmware/efi/fw_platform_size

If the directory exists, your computer supports EFI
ls /sys/firmware/efi/efivars

### Connect to the internet

iwctl

device list

station wlan0 get-networks

station wlan0 connect <essid>

exit

ping ping.archlinux.org

### Update mirrorlist

reflector --country Kenya --age 6 --sort rate --save /etc/pacman.d/mirrorlist

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

Verify state with

```
timedatectl status
```

## Partition the disks

Use fdisk, or cfdisk or gdisk

### Mount Points

/efi
/boot
/

## Format the partitions

mkfs.fat -F 32 /dev/nvme0n1p1

mkfs.btrfs /dev/nvme0n1p2

mkswap /dev/nvme0n1p3

## Mount the file systemss

Correctly mount al filesystems to the `/mnt`

```
swapon /dev/nvme0n1p3
```

```
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```

or

```
mount --mkdir /dev/nvme0n1p1 /mnt/efi
```

```
mount /dev/nvme0n1p2 /mnt
```

## Creating subvolumes

Create root subvolume

```
btrfs subvolume create /mnt/@
```

btrfs subvolume create /mnt/@tmp
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache
btrfs subvolume create /mnt/@opt
btrfs subvolume create /mnt/@srv
btrfs subvolume create /mnt/@snapshots

Unmount the roof fs

```
umount /mnt
```

Mount the subvolumes

mount -o noatime,compress=zstd,ssd,space_cache=v2,subvol=@ /dev/nvme0n1p2 /mnt

Make directories for the subvolumes

mkdir -p /mnt/{var/tmp,var/log,var/cache,opt,.snapshots}

sudo mount -o subvolume=@tmp /dev/nvme0n1p3 /mnt/var/tmp
sudo mount -o subvolume=@log /dev/nvme0n1p3 /mnt/var/log
sudo mount -o subvolume=@cache /dev/nvme0n1p3 /mnt/var/cache
sudo mount -o subvolume=@opt /dev/nvme0n1p3 /mnt/opt
sudo mount -o subvolume=@srv /dev/nvme0n1p3 /mnt/srv
sudo mount -o subvolume=@snapshots /dev/nvme0n1p3 /mnt/.snapshots

List the subvolumes

```
btrfs subvolume list /mnt
```

BTRFS info

```
btrfs filesystem show /
```

## Installation

Install essential packages into the new filesystem

pacstrap -K /mnt base base-devel linux-zen linux-lts linux-firmware sudo fish git btrfs-progs vim amd-ucode openssh networkmanager pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber

## Configure the system

### Fstab

Generate fstab (filesystem table)

```
genfstab -U /mnt >> /mnt/etc/fstab
```

Check if fstab is fine ( it is if you've faithfully followed the previous steps )

```
cat /mnt/etc/fstab
```

### Chroot

arch-chroot /mnt

### Time

ln -sf /usr/share/zoneinfo/Africa/Nairobi /etc/localtime

Synchronize hardware clock and the system clock

```
hwclock --systohc
```

### Localization

Go to /etc/locale.gen and uncomment the line with `en_US.UTF-8 UTF-8`
Then run:

```
locale-gen
```

or

echo "LANG=en_US.UTF-8" > /etc/locale.conf

Set the console keyboard layout

echo "KEYMAP=us" > /etc/vconsole.conf

### Network configuration

Create hostname file:

echo "archlinux" > /etc/hostname

### Root password

passwd root

### Install other packages

pacman -Syu grub efibootmgr networkmanager git reflector snapper bluez bluez-utils xdg-user-dirs xdg-utils base-devel linux-headers

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

### Make slight change to mkinitcpio.conf file

Ensure to add the btrfs in the MODULES array

```

MODULES=(usbhid xhci_hcd)
MODULES=(btrfs)
```

Then run:

```
mkinitcpio -P
```

### Boot loader

Install and configure grub

pacman -S grub efibootmgr

grub-install --target=x86_64-efi --efi-directory=/efi --boot-directory=/boot --bootloader-id=arch --recheck

Generate configuration file for GRUB

```
grub-mkconfig -o /boot/grub/grub.cfg
```

### Network stack

```
pacman -Syu networkmanager
```

```
sudo systemctl enable NetworkManager.service

sudo systemctl start NetworkManager.service
```

Install additional interfaces: for a graphical user interface and system tray applet respectively.
```
sudo pacman -Syu nm-connection-editor network-manager-applet
```


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

## Configure Snapshots

We need to configure snapshots directory, since we don't have the configurations for snapper

Unmount snaphosts directory

```
umount /.snapshots
```

Remove the directory

```
rm -r /.snapshots
```

Create configuration for snapper

```
sudo snapper -c root create-config /
```

Above command a new .snapshots directory. Delete it.

```
sudo btrfs subvolume delete /.snapshots
```

Re-create our snapshots directory

```
sudo mkdir /.snapshots
```

Remount snapshots subvolume. We already have its mountpoint in the fstab file, thus we can run the simpler command

```
sudo mount -a
```

Change permissions for snapshots folder. All snapshots that snapper creates will be stored outside of the root subvolume. So that
the root subvolume can be easily replaced any time without losing the snapshots.

```
sudo chmod 750 /.snapshots

sudo chmod a+rx /.snapshots

# user will always be root, but for the group,, use the username. User of username will be able to access the snaphots
            sudo chown :username /.snapshots
```

Go to the configuration file for snapper at `/etc/snapper/configs/root`
Go to users and groups section and inlcude your username in the ALLOW_USERS entry; allwos your user to manage the snaphosts.
Adjust how many snaphosts you want to keep in the system; adjust the sectio for limits for timeline cleanup.
We can enable timeline and timeline cleanup of snapper:

```
sudo systemctl enable --now snapper-timeline.timer
suod systemctl enable --now snapper-cleanup.timer
```

You can install some packgess:

```
sudo pacman -Syu snap-pac-grub snapper-gui
```

Boot dir is not a btrfs directory; but we can create a hook so that we can 'backup' the boot directory as well, when there is a kernel update

```
mkkdir /etc/pacman.d/hooks/

touch /etc/pacman.d/hooks/50-bootbackup.hook
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

## Hibernation

### Manually specify hibernation location
```
sudo vim /etc/default/grub
```

```
GRUB_CMDLINE_LINUX_DEFAULT="quiet resume=UUID=<UUID of your swap partition>"
```

Generate GRUB config
```
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

COnfigure initranmfs, by adding the `resume` hook in the `/etc/mkinitcpio.conf` file. The `resume` hook needs go after the `udev` hook:
```
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems resume fsck)
```


## ZRAM

Install `zram-generator` and create file `/etc/systemd/zram-generator.conf` with the following:
```
[zram0]
zram-size = min(4096, 8192)
compression-algorithm = zstd
swap-priority=60

```

The run `sudo systemctl daemon-reload` adn start the configured service:
```
sudo systemctl start systemd-zram-setup@zram0.service

```

## SDDM
```
sudo pacman -Syu sddm

sudo systemctl enable sddm

```

```
sudo pacman -Syu sddm qt5-graphicaleffects qt5-svg qt5-quickcontrols2
```

Cloned the corners theme: `git clone https://github.com/aczw/sddm-theme-corners.git`

Copy to sddm themes:
```
cd sddm-theme-corners

sudo cp -r corners/ /usr/share/sddm/themes/
```

Create config directory: `sudo mkdir /etc/sddm.conf.d/`

Create `sddm` config file: `touch sddm.conf` with the contents:
```
[Theme]
Current=corners
```

To always ensure numlock is always on at startup; create file `numlock.conf` in the same directory with contents:
```
Numlock=on
```

## Fonts

```
sudo pacman -Syu ttf-jetbrains-mono-nerd
```
### CJK
```
sudo pacman -Syu noto-fonts-cjk wqy-microhei
```

### Emoji
```
sudo pacman -Syu noto-fonts-emoji
```

# References

https://github.com/silentz/arch-linux-install-guide

https://gist.github.com/mjkstra/96ce7a5689d753e7a6bdd92cdc169bae

https://github.com/dreamsofautonomy/arch-from-scratch
