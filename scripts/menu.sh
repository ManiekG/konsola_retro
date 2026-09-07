#!/bin/bash
CHOICE=$(whiptail --title "RETRO MENU" --menu "Wybierz platforme:" 20 60 11 \
"1" "SAM Coupe" \
"2" "Atari 800XL" \
"3" "Sinclair (Spectrum 48K/+3)" \
"4" "Atari 1040ST" \
"5" "MSX" \
"6" "Amiga 500" \
"7" "Commodore (C64/C128/VIC-20/Plus4)" \
"8" "Amstrad CPC 6128" \
"9" "Apple II" \
"0" "Powloka (bash)" 3>&1 1>&2 2>&3)

clear
case $CHOICE in
    1) simcoupe -fullscreen ;;
    2) atari800 ;;
    3) exec ~/sinclair_menu.sh ;;
    4) hatari ;;
    5) openmsx ;;
    6) fs-uae --floppy-drive-0="/home/maniek/amiga/disks/workbench.adf" ;;
    7) exec ~/commodore_menu.sh ;;
    8) cap32 ;;
    9) linapple ;;
    0) exec bash ;;
    *) ;;
esac
exec ~/menu.sh
