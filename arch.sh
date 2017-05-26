#!/bin/bash

#Arch x86-64 Install Instructions
#curl -L https://github.com/purplesquid/Arch-Linux-Install/tarball/master | tar xz
#sh arch.sh

internetCheck(){
    if ping -c 1 www.google.com &> /dev/null
    then
        echo "Internet: Connected"
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
    PS3='Please enter a number to install packages or 3 to quit: '
    connections=("Base" "Base and devel" "Quit")
    select opt in "${connections[@]}"
    do
        case $opt in 
            "Base")
                #hits enter twice to install base packages
                echo -ne "\n\n y" | pacstrap -i /mnt base base-devel
                break;;
            "Base and devel")
                echo -ne "\n\n y" | pacstrap -i /mnt base
                break;;
            "Quit")
                exit 1;;
            *) echo "invalid option";;
        esac
    done
    
    #Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    arch-chroot /mnt /bin/bash
}
internetCheck
