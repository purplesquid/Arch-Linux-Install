timezonesort(){
    timesort="timedatectl list-timezones"
    printf "%-20s%-20s%-20s%s\n" $($timesort | grep -o "$1.*" | cut -f2- -d'/')
    read -rp "Please enter a city: " city
    
    ln -sf /usr/share/zoneinfo/$1/$city /etc/localtime
}

chrootsystem(){
    PS3='Enter the area you are located: '
    options=("Africa" "America" "Antarctica" "Asia" "Atlantic" "Australia" "Europe" "Indian" "Pacific")
    select opt in "${options[@]}"
    do
        case $opt in
            "$opt")
            timezonesort $opt
            break;;
            *) echo "invalid option";;
        esac
    done
    
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
    
    #Create locale
    sed -i 's/^#en_US\.UTF/en_US\.UTF/' /mnt/etc/locale.gen
    locale-gen
        
    read -rp "Enter in the hostname of the computer (e.g archlinuxpc)" host
    echo $host > /etc/hostname
    
    echo -e "Creating initial ramdisk environment and setting up kernel modules for init\n"
    mkinitcpio -p linux 
    
    read -rsp $'Press any key to set the root passwd...\n' -n1 key
    passwd
    PS3='Enter the boot loader to install: '
    options=("Grub" "Syslinux")
    select opt in "${options[@]}"
    do
        case $opt in
            "Grub")
                echo -ne "y" | pacman -S grub os-prober 
                grub-install --target=x86_64-pc /dev/sda
                grub-mkconfig -o /boot/grub/grub.cfg
                break;;     
            "Syslinux")
                echo -ne "y" | pacman -S syslinux gptfdisk 
                syslinux-install_update -i -a -m
                read -rsp $'Add the root partition number after /dev/. For example -->  LABEL arch  APPEND root=/dev/"rootpartition number goes here" rw. Once you hit a key, the terminal will automatically switch to the file...\n' -n1 key
                nano /boot/syslinux/syslinux.cfg
                break;;
        *) echo "invalid option";;
        esac
    done
    
    read -rsp $'Press any key to exit the chroot environment and reboot...\n' -n1 key
    
    exit
    unmount -R /mnt
    reboot  
}

chrootsystem

