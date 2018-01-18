#!/bin/bash

rootPartition=1
homePartition=2
country="America"
city="New_York"

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
}

baseinstall(){
    #installing base package
    echo
    #Installs base and base-devel packages
    pacstrap -i /mnt base base-devel --noconfirm 
    #Generate fstab
    genfstab -U /mnt >> /mnt/etc/fstab
    
    ln -sf /usr/share/zoneinfo/$country/$city /etc/localtime
    
    #Create locale
    sed -i 's/^#en_US\.UTF/en_US\.UTF/' /mnt/etc/locale.gen
    locale-gen
    
    echo -ne "1) mv chroot.sh /mnt/root \n 2) arch-chroot /mnt \n 3) sh /root/chroot.sh\n"
 }
internetCheck
