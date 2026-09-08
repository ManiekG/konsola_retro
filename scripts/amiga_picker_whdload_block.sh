# Blok do użycia wewnątrz pętli w ~/amiga_picker.sh dla LETTER="H".
# Stan przetestowany 2026-09-08.

    if [ "$LETTER" = "H" ]; then
        WHD_DIR="/home/maniek/amiga/harddrive/a1200"

        while true; do
            WHD_LETTER=$(whiptail \
                --title "Amiga 1200 - WHDLoad" \
                --menu "Wybierz litere:" 24 50 16 \
                "A" "Gry na A" "B" "Gry na B" "C" "Gry na C" "D" "Gry na D" "E" "Gry na E" \
                "F" "Gry na F" "G" "Gry na G" "H" "Gry na H" "I" "Gry na I" "J" "Gry na J" \
                "K" "Gry na K" "L" "Gry na L" "M" "Gry na M" "N" "Gry na N" "O" "Gry na O" \
                "P" "Gry na P" "Q" "Gry na Q" "R" "Gry na R" "S" "Gry na S" "T" "Gry na T" \
                "U" "Gry na U" "V" "Gry na V" "W" "Gry na W" "X" "Gry na X" "Y" "Gry na Y" \
                "Z" "Gry na Z" "0" "0-9 / inne" \
                "9" "Powrot" \
                3>&1 1>&2 2>&3)

            if [ -z "$WHD_LETTER" ] || [ "$WHD_LETTER" = "9" ]; then
                break
            fi

            MENU_ITEMS=()
            GAME_DIRS=()
            i=1

            while IFS= read -r -d '' d; do
                name=$(basename "$d")

                case "$name" in
                    C|Devs|Libs|S|WHDBooter|Savegames)
                        continue
                        ;;
                esac

                first=$(printf '%s' "$name" | cut -c1 | tr '[:lower:]' '[:upper:]')

                if [ "$WHD_LETTER" = "0" ]; then
                    case "$first" in
                        [A-Z]) continue ;;
                    esac
                else
                    if [ "$first" != "$WHD_LETTER" ]; then
                        continue
                    fi
                fi

                slave=$(find "$d" -maxdepth 2 -type f -iname "*.slave" | head -1)
                if [ -z "$slave" ]; then
                    continue
                fi

                MENU_ITEMS+=("$i" "$name")
                GAME_DIRS+=("$d")
                i=$((i+1))
            done < <(find "$WHD_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

            if [ "${#MENU_ITEMS[@]}" -eq 0 ]; then
                whiptail --msgbox "Brak gier WHDLoad dla litery $WHD_LETTER." 8 50
                continue
            fi

            CHOICE=$(whiptail \
                --title "WHDLoad - $WHD_LETTER" \
                --menu "Wybierz gre:" 24 70 16 \
                "${MENU_ITEMS[@]}" \
                3>&1 1>&2 2>&3)

            if [ -z "$CHOICE" ]; then
                continue
            fi

            IDX=$((CHOICE-1))
            GAME_DIR="${GAME_DIRS[$IDX]}"
            GAME_NAME=$(basename "$GAME_DIR")

            SLAVE_PATH=$(find "$GAME_DIR" -maxdepth 2 -type f -iname "*.slave" | head -1)

            if [ -z "$SLAVE_PATH" ]; then
                whiptail --msgbox "Brak pliku .Slave dla $GAME_NAME" 8 50
                continue
            fi

            SLAVE_NAME=$(basename "$SLAVE_PATH")

            printf "%s\n" \
                "C:Assign ENV: RAM:" \
                "C:Assign T: RAM:" \
                "C:Assign WHDLoadSave: DH0:" \
                "" \
                "CD DH1:" \
                "DH0:C/WHDLoad \"$SLAVE_NAME\" PRELOAD SPLASHDELAY=0" \
                "" \
                "C:Wait 15" \
                > /home/maniek/amiga/harddrive/a1200/S/startup-sequence

            clear

            amiberry-lite \
              --model A1200 \
              -r /home/maniek/amiga/system/kickstart31.rom \
              -m DH0:/home/maniek/amiga/harddrive/a1200 \
              -m "DH1:$GAME_DIR" \
              -s fastmem_size=8 \
              -G
        done

        continue
    fi
