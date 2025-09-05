sudo mkdir /mnt/os
sudo mount /dev/nvme0n1p4 /mnt/os -o subvol=@
sudo mount /dev/nvme0n1p4 /mnt/os/var -o subvol=@var
sudo mount --bind /dev /mnt/os/dev
sudo mount --bind /dev/pts /mnt/os/dev/pts
sudo mount --bind /proc /mnt/os/proc
sudo mount --bind /run /mnt/os/run
sudo mount --bind /sys /mnt/os/sys
sudo mount --bind /sys/firmware/efi/efivars /mnt/sys/firmware/efi/efivars
sudo mount --bind /home /mnt/os/home

sudo chroot /mnt/os

