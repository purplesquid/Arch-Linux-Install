chrootsystem(){  
    PS3='Enter a number for your time standard: '
    timestandard=("localtime" "UTC")
    select reply in "${timestandard[@]}"
    do
        case $reply in
            "localtime")
                hwclock --systohc --localtime
                break;;     
            "UTC")
                hwclock --systohc --utc
                break;;
        *) echo "invalid option";;
        esac
    done
        
    read -rp "Enter in the hostname of the computer (e.g archlinuxpc)" host
    echo $host > /etc/hostname
    
    echo -e "Creating initial ramdisk environment and setting up kernel modules for init\n"
    mkinitcpio -p linux 
    
    echo
    read -rsp $'Press any key to set the root passwd...\n' -n1 key
    passwd
    echo
    read -rsp $'Press any key to install the Syslinux bootloader...\n' -n1 key
    echo -ne "y" | pacman -S syslinux gptfdisk
    syslinux-install_update -i -a -m
    echo
    lsblk /dev/sda
    read -rsp $'Add the root partition number after /dev/'
    echo -e "\n For example -->  LABEL arch  APPEND root=/dev/"rootpartition number goes here" rw. Once you hit a key, the terminal will automatically switch to the file...\n' -n1 key
    nano /boot/syslinux/syslinux.cfg 
    exit
    read -rsp $'Press any key to reboot the system and launch Arch Linux!' -n1 key
}
chrootsystem
