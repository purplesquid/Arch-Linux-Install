hostName="archpc"

hwclock --systohc --localtime
#Setting hostname
echo $hostName > /etc/hostname
    
echo -e "Creating initial ramdisk environment and setting up kernel modules for init\n"
mkinitcpio -p linux 
    
echo
read -rsp $'Press any key to set the root passwd...\n' -n1 key
passwd
echo
    
pacman -S syslinux gptfdisk --noconfirm
syslinux-install_update -i -a -m
nano /boot/syslinux/syslinux.cfg
