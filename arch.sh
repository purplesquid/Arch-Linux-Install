#!/bin/bash
#Arch x86-64 Install
#curl -L https://github.com/username/repository name/tarball/development | tar xz

internetCheck(){
    if ping -c 2 www.google.com &> /dev/null
    then
        echo "Internet: OK"
        partitions
    else
        echo
        echo -e "Attempting to gain network connection...\n"
        connect
    fi
}

connect(){
    PS3='Please enter a number or 3 to quit: '
    connections=("Wifi" "Ethernet" "Quit")
    select opt in "${connections[@]}"
    do
        case $opt in 
            "Wifi")
                sudo wifi-menu;;
            "Ethernet")
                ip link
                read -rp "\nPlease enter the interface name: " ethName
                ip link set $ethName up;;
            "Quit")
                exit 1;;
            *) echo "invalid option";;
            
        esac

        if internetCheck == true
        then
            partitions
        else
            connect
        fi
    done
}   

partitions(){
    cfdisk /dev/sda
    lsblk /dev/sda
    read -rp "Do you have a swap partition? [y/n] " swap

    if [[ $swap =~ [yY](es)* ]]
    then
        echo -e "What partition number is it? "
        echo
        
        read swappartition
        mkswap /dev/sda${swappartition} && swapon /dev/sda${swappartition}
    else
        echo
        read -rp "Which partition number is root? " rootpartition
        read -rp "Which partition number is home? " home
        echo "y" | (mkfs.ext4 /dev/sda${rootpartition} && mkfs.ext4 /dev/sda${home})
        
        mount /dev/sda$rootpartition /mnt
        mkdir -p /mnt/home
        mount /dev/sda$home /mnt/home
        
        lsblk /dev/sda 

        #Verifies partitions are correct before continuing
        echo
        echo -e "The root partition should be labeled as /mnt\n"
            echo -e "The home partition should be labeled as /mnt/home\n"
            echo -e "The swap partition should be labeled as /swap\n"
            
        read -rp "Are you sure the partitions are correct? [y/n] " response
        
        if [[ $response =~ [yY](es)* ]]
        then
            baseinstall
        else
                partitions
        fi
    fi
}

baseinstall(){
    #installing base package
    echo
    read -rp  "Do you want to install the base-devel pacakges? [y/n] ?" base
    
    if [[ $base =~ [yY](es)* ]] 
    then   
        #hits enter twice to install base packages
        echo -ne "\n\n y" | pacstrap -i /mnt base base-devel
    else
        echo -ne "\n\n y" | pacstrap -i /mnt base 
    fi
    
    echo -e "Generating fstab file\n"
    genfstab -U /mnt >> /mnt/etc/fstab
    
    echo "Chrooting into new system"
    #echo -e "\n" | arch-chroot /mnt /bin/bash | chrootsystem
    #chrootsystem | arch-chroot /mnt /bin/bash
    chrootsystem
}

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
        
    read -rp "Enter in the hostname of the computer (e.g archlinuxpc)" host
    echo $host > /etc/hostname
    
    echo -e "Creating initial ramdisk environment and setting up kernel modules for init\n"
    mkinitcpio -p linux 
    
    read -rsp $'Press any key to set the root passwd...\n' -n1 key
    passwd
    PS3='Enter the boot loader to install\n'
    options=("Grub" "Syslinux")
    select opt in "${options[@]}"
    do
    case $opt in
        "Grub")
            pacman -S grub os-prober
            grub-install -target=x86_64-pc /dev/sda
            grub-mkconfig -o /boot/grub/grub.cfg
            break;;     
        "Syslinux")
            pacman -S syslinux gptfdisk 
            syslinux-install_update -i -a -m
            read -rsp $'Add the root partition number after /dev/. For example -->  LABEL arch  APPEND root=/dev/"rootpartition number goes here" rw. Once you hit a key, the terminal will automatically switch to the file...\n' -n1 key
#            nano /boot/syslinux/syslinux.cfg
            break;;
    *) echo "invalid option";;
    esac
    done
    
    read -rsp $'Press any key to exit the chroot environment and reboot...\n' -n1 key
    
    exit
    unmount -R /mnt
    reboot  
}

internetCheck
