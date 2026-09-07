#!/bin/bash
clear
echo "=================================="
echo "   COMMODORE"
echo "=================================="
echo "1) Commodore 64"
echo "2) Commodore 128"
echo "3) VIC-20"
echo "4) Plus/4 - C116"
echo "0) Powrot do glownego menu"
echo "=================================="
read -p "Wybierz: " choice
case $choice in
    1)
        cd ~/c64/disks
        x64sc -sounddev alsa
        ;;
    2)
        cd ~/c128/disks
        x128 -sounddev alsa
        ;;
    3)
        cd ~/vic20/disks
        xvic -sounddev alsa
        ;;
    4)
        cd ~/plus4/disks
        xplus4 -sounddev alsa
        ;;
    0)
        exec ~/menu.sh
        ;;
    *)
        echo "Nieznana opcja"
        sleep 2
        ;;
esac
exec ~/commodore_menu.sh
