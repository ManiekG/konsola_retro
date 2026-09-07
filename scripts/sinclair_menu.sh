#!/bin/bash
clear
echo "=================================="
echo "   SINCLAIR"
echo "=================================="
echo "1) ZX Spectrum 48K (TAP/TZX)"
echo "2) ZX Spectrum +3 (TAP/TZX/DSK)"
echo "0) Powrot do glownego menu"
echo "=================================="
read -p "Wybierz: " choice
cd ~/spectrum/disks
case $choice in
    1)
        fuse-sdl --machine 48
        ;;
    2)
        fuse-sdl --machine plus3
        ;;
    0)
        exec ~/menu.sh
        ;;
    *)
        echo "Nieznana opcja"
        sleep 2
        ;;
esac
exec ~/sinclair_menu.sh
