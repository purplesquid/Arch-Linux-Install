#!/bin/bash

#Arch x86-64 Install Instructions
#1) curl -L https://github.com/purplesquid/Arch-Linux-Install/tarball/master | tar xz
#2) sh arch.sh
#3) after arch.sh completes copy chroot.sh to /mnt/root
#4) go into chroot using arch-chroot /mnt 
#5) run chroot.sh from the /mnt/root directory

internetCheck(){
    if ping -c 1 www.google.com &> /dev/null
    then
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
    read -rp "Do you have a swap partition? [y/n] " swap

    if [[ $swap =~ [yY](es)* ]]
    then
        echo -e "What partition number is it? "
        echo
        
        read swappartition
        mkswap /dev/sda${swappartition} && swapon /dev/sda${swappartition}
        echo "y" | (mkfs.ext4 -O ^64bit /dev/sda${swappartition}
    else
        echo
        read -rp "Which partition number is root? " rootpartition
        read -rp "Which partition number is home? " home
        echo "y" | (mkfs.ext4 -O ^64bit /dev/sda${rootpartition} && mkfs.ext4 -O ^64bit /dev/sda${home})
        
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

timezonesort(){
    timesort="timedatectl list-timezones"
    printf "%-20s%-20s%-20s%s\n" $($timesort | grep -o "$1.*" | cut -f2- -d'/')
    read -rp "Please enter a city: " city
    
    ln -sf /usr/share/zoneinfo/$1/$city /etc/localtime
}

baseinstall(){
    #installing base package
    echo
    PS3='Please enter a number to install packages or 3 to quit: '
    connections=("Base" "Base and devel" "Quit")
    select opt in "${connections[@]}"
    do
        case $opt in 
            "Base")
                #hits enter twice to install base packages
                echo -ne "\n\n y" | pacstrap -i /mnt base
                break;;
            "Base and devel")
                echo -ne "\n\n y" | pacstrap -i /mnt base base-devel
                break;;
            "Quit")
                exit 1;;
            *) echo "invalid option";;
        esac
    done
    
    #Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
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
    
    #Create locale
    sed -i 's/^#en_US\.UTF/en_US\.UTF/' /mnt/etc/locale.gen
    locale-gen
    
    echo -e "Now move chroot.sh to /mnt/root directory, change root (chroot) using arch-chroot /mnt, and run chroot.sh\n"
 }
internetCheck
