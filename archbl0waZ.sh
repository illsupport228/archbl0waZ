#!/bin/bash
set -e
set -o

echo '
                     .__   ___.   .__  _______                 __________
_____ _______   ____ |  |__\_ |__ |  | \   _  \__  _  _______  \____    /
\__  \\_  __ \_/ ___\|  |  \| __ \|  | /  /_\  \ \/ \/ /\__  \   /     /
 / __ \|  | \/\  \___|   Y  \ \_\ \  |_\  \_/   \     /  / __ \_/     /_
(____  /__|    \___  >___|  /___  /____/\_____  /\/\_/  (____  /_______ \
     \/            \/     \/    \/            \/             \/        \/'

sudo loadkeys es
sudo ls /sys/firmware/efi/efivars
sudo timedatectl set-ntp true
sudo yes | pacman -Syy reflector
sudo reflector -c Spain -a 12 --sort rate --save /etc/pacman.d/Mirrorlist
sudo pacman -Syyy
sudo lsblk
sudo echo 'nombre del disco'
read disk
sudo sgdisk -d 1 /dev/$disk
sudo sgdisk -d 2 /dev/$disk
sudo sgdisk -n 1:0:+500M /dev/$disk
sudo sgdisk -n 2 /dev/$disk
sudo sgdisk -t 1:ef00 /dev/$disk
sudo sgdisk -t 2:8e00 /dev/$disk
sudo cryptsetup luksFormat /dev/$disk2
read -p ''
sudo cryptsetup open /dev/$disk2 cryptlvm
read -p ''
sudo pvcreate /dev/mapper/cryptlvm
sudo vgcreate vg1 /dev/mapper/cryptlvm
sudo lvcreate -L 50G vg1 -n root
sudo lvcreate -L 11G vg1 -n swap
sudo lvcreate -l 100%FREE vg1 -n home
sudo mkfs.fat -F32 /dev/$disk1
sudo mkfs.ext4 /dev/vg1/root
sudo mkfs.ext4 /dev/vg1/home
sudo mkswap /dev/vg1/swap
sudo mount /dev/vg1/root /mnt
sudo mkdir /mnt/home
sudo mount /dev/vg1/home /mnt/home
sudo mkdir /mnt/boot
sudo mount /dev/$disk1 /mnt/boot
sudo swapon /dev/vg1/swap
sudo pacstrap /mnt base linux linux-firmware vim intel-ucode lvm2
sudo genfstab -U /mnt >> /mnt/etc/fstab
sudo arch-chroot /mnt
sudo ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
sudo hwclock --systohc
sudo sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sudo locale-gen
sudo echo LANG=en_US.UTF-8 >> /etc/locale.conf
sudo echo KEYMAP=es >> /etc/vconsole.conf
sudo echo 'nombre de host'
read hostname
sudo echo $hostname >> /etc/hostname
sudo echo '
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain     $hostname' >> /etc/hosts
sudo echo "root:root" | sudo chpasswd
sudo pacman -S grub efibootmgr networkmanager network-manager-applet wireless_tools wpa_supplicant dialog os-prober mtools dosfstools base-devel linux-headers git reflector bluez bluez-utils pulseaudio-bluetooth cups xdg-utils xdg-user-dirs
sudo sed -i 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)/g' /etc/mkinitcpio.conf
sudo mkinitcpio -p linux
sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
uuid=$(blkid -o value /dev/$disk2)
grub-uuid=$(sudo echo 'GRUB_CMDLINE_LINUX="cryptdevice=UUID=$uuid:cryptlvm root=/dev/vg1/root"')
sudo sed -i 's/GRUB_CMDLINE_LINUX=""/$grub-uuid/g' /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable cups
sudo echo 'nombre de usuario'
read username
sudo useradd -mG wheel $username
sudo echo 'contraseña'
read password
sudo echo "$username:$password" | sudo chpasswd
sudo EDITOR=vim visudo
sudo sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers.d
exit
umount -a
reboot


