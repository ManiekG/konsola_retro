#!/bin/bash
# ============================================================
# Konsola Retro - skrypt instalacyjny od zera
# Raspberry Pi Zero 2W, Raspberry Pi OS Lite (Trixie/Debian 13)
# SAM Coupe / Atari 800XL / ZX Spectrum / C64 / CPC 6128 / Atari ST
# ============================================================
# Uruchom jako zwykly user (NIE root), skrypt sam uzywa sudo tam gdzie trzeba:
#   chmod +x install_retro.sh
#   ./install_retro.sh
#
# Skrypt jest odporny na bledy pojedynczych emulatorow - jesli
# ktorys sie nie zbuduje, reszta i tak jedzie dalej. Na koncu
# dostajesz podsumowanie co sie udalo.
# ============================================================

set +e  # nie przerywamy calego skryptu na pojedynczym bledzie

HOME_DIR="$HOME"
USER_NAME="$(whoami)"
LOG_FILE="$HOME_DIR/retro_install.log"
declare -A STATUS

log() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

ok() {
    STATUS["$1"]="OK"
    log "OK: $1"
}

fail() {
    STATUS["$1"]="BLAD"
    log "BLAD: $1 -- $2"
}

section() {
    echo ""
    echo "============================================================"
    echo " $1"
    echo "============================================================"
    log "=== $1 ==="
}

# ------------------------------------------------------------
section "1. Aktualizacja systemu i pakiety bazowe"
# ------------------------------------------------------------
log "Szybki test zdrowia karty SD przed rozpoczeciem (zapis/odczyt testowego pliku)..."
dd if=/dev/zero of="$HOME_DIR/sdtest.tmp" bs=1M count=200 conv=fsync 2>>"$LOG_FILE"
sync
if dd if="$HOME_DIR/sdtest.tmp" of=/dev/null bs=1M 2>>"$LOG_FILE"; then
    log "Test zapisu/odczytu 200MB przeszedl bez oczywistych bledow"
else
    log "UWAGA: test zapisu/odczytu zglosil problem - sprawdz dmesg przed kontynuacja"
fi
rm -f "$HOME_DIR/sdtest.tmp"
dmesg | tail -20 | grep -iE "ext4.*error|checksum invalid" && \
    log "UWAGA: dmesg pokazuje bledy ext4 JUZ TERAZ - rozwaz przerwanie i wymiane karty" || \
    log "dmesg czysty, brak bledow ext4 na starcie"

sudo apt update && sudo apt full-upgrade -y
if sudo apt install -y git build-essential cmake pkg-config \
    libsdl2-dev libsdl2-image-dev zlib1g-dev libgtk-3-dev \
    libpng-dev libglib2.0-dev autoconf automake libtool \
    fuse-emulator-sdl spectrum-roms joystick \
    libcurl4-openssl-dev libsdl1.2-dev libfreetype-dev; then
    ok "pakiety_bazowe"
else
    fail "pakiety_bazowe" "apt install nie przeszlo w calosci"
fi

# ------------------------------------------------------------
section "2. Wlaczenie KMS (dtoverlay=vc4-kms-v3d)"
# ------------------------------------------------------------
CONFIG_TXT="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_TXT" ]; then
    CONFIG_TXT="/boot/config.txt"
fi
if grep -q "^dtoverlay=vc4-kms-v3d" "$CONFIG_TXT" 2>/dev/null; then
    log "KMS juz wlaczone w $CONFIG_TXT"
    ok "kms_overlay"
else
    if sudo sh -c "echo 'dtoverlay=vc4-kms-v3d' >> $CONFIG_TXT"; then
        ok "kms_overlay"
        log "Dopisano dtoverlay do $CONFIG_TXT -- WYMAGANY REBOOT po instalacji"
    else
        fail "kms_overlay" "nie udalo sie zapisac do $CONFIG_TXT"
    fi
fi

# ------------------------------------------------------------
section "3. SimCoupe (SAM Coupe)"
# ------------------------------------------------------------
cd "$HOME_DIR" || exit 1
if [ ! -d simcoupe ]; then
    git clone https://github.com/simonowen/simcoupe.git
fi
if [ -d simcoupe ]; then
    cd simcoupe && mkdir -p build && cd build
    if cmake .. -DCMAKE_BUILD_TYPE=Release && make -j4 && sudo make install && sudo ldconfig; then
        ok "simcoupe"
    else
        fail "simcoupe" "blad kompilacji/instalacji"
    fi
    cd "$HOME_DIR"
else
    fail "simcoupe" "git clone nie powiodl sie"
fi

# ------------------------------------------------------------
section "4. Atari800 (Atari 800XL/XE)"
# ------------------------------------------------------------
cd "$HOME_DIR" || exit 1
if [ ! -d atari800 ]; then
    git clone https://github.com/atari800/atari800.git
fi
if [ -d atari800 ]; then
    cd atari800
    if ./autogen.sh && ./configure --target=default && make -j4 && sudo make install; then
        ok "atari800"
        mkdir -p "$HOME_DIR/.atari800"
        mkdir -p "$HOME_DIR/atari/disks"
        log "UWAGA: wgraj wlasne ROM-y Atari (ATARIXL.ROM, ATARIBAS.ROM) do ~/.atari800/"
        log "       i skonfiguruj ~/.atari800.cfg (VIDEO_ACCEL=0, ROM_XL/XE_CUSTOM=..., OS_XL/XE_VERSION=CUSTOM)"
    else
        fail "atari800" "blad kompilacji/instalacji"
    fi
    cd "$HOME_DIR"
else
    fail "atari800" "git clone nie powiodl sie"
fi

# ------------------------------------------------------------
section "5. ZX Spectrum (fuse-emulator-sdl)"
# ------------------------------------------------------------
if which fuse-sdl > /dev/null 2>&1; then
    ok "spectrum"
    mkdir -p "$HOME_DIR/spectrum/disks"
else
    fail "spectrum" "fuse-sdl nie zainstalowal sie poprawnie (sprawdz krok 1)"
fi

# ------------------------------------------------------------
section "6. Commodore 64 (VICE / x64sc)"
# ------------------------------------------------------------
if sudo apt install -y vice 2>>"$LOG_FILE"; then
    ok "c64"
    mkdir -p "$HOME_DIR/c64/disks"
else
    log "Pakiet 'vice' niedostepny w apt, probuje kompilacje ze zrodel (moze potrwac 15-30 min)..."
    cd "$HOME_DIR" || exit 1
    sudo apt install -y libpng-dev libjpeg-dev flac libflac-dev libvorbis-dev \
        libpcap-dev portaudio19-dev texinfo dos2unix xa65 bison flex 2>>"$LOG_FILE"
    if [ ! -d vice-source ]; then
        git clone --depth 1 https://github.com/VICE-Team/svn-mirror.git vice-source 2>>"$LOG_FILE"
    fi
    if [ -d vice-source/vice ]; then
        cd vice-source/vice
        if ./autogen.sh >>"$LOG_FILE" 2>&1 && \
           ./configure --enable-sdl2ui --without-oss --disable-catweasel --disable-parsid >>"$LOG_FILE" 2>&1 && \
           make -j4 >>"$LOG_FILE" 2>&1; then
            # UWAGA: 'make install' nie generuje wlasciwej reguly w tym buildzie -
            # kopiujemy binarke recznie
            if [ -f src/x64sc ] && sudo cp src/x64sc /usr/local/bin/ && sudo chmod +x /usr/local/bin/x64sc; then
                ok "c64"
                mkdir -p "$HOME_DIR/c64/disks"
            else
                fail "c64" "binarka x64sc nie powstala mimo udanego make - zobacz $LOG_FILE"
            fi
        else
            fail "c64" "kompilacja VICE ze zrodel nie powiodla sie - zobacz $LOG_FILE"
        fi
        cd "$HOME_DIR"
    else
        fail "c64" "nie udalo sie pobrac zrodel VICE"
    fi
fi

# ------------------------------------------------------------
section "7. Amstrad CPC 6128 (Caprice32)"
# ------------------------------------------------------------
cd "$HOME_DIR" || exit 1
if [ ! -d caprice32 ]; then
    git clone https://github.com/ColinPitrat/caprice32.git 2>>"$LOG_FILE"
fi
if [ -d caprice32 ]; then
    cd caprice32
    if make WITHOUT_GL=TRUE >>"$LOG_FILE" 2>&1 && [ -f cap32 ]; then
        sudo cp cap32 /usr/local/bin/ 2>>"$LOG_FILE"
        sudo chmod +x /usr/local/bin/cap32
        ok "cpc6128"
        mkdir -p "$HOME_DIR/.capriceConfig"
        mkdir -p "$HOME_DIR/cpc/disks"
        log "UWAGA: wgraj wlasne ROM-y CPC 6128 do ~/.capriceConfig/ (cpc6128.rom itp.)"
    else
        fail "cpc6128" "blad kompilacji Caprice32 - zobacz $LOG_FILE (jesli 'internal compiler error segfault' - to problem sprzetu/karty SD, nie kodu)"
    fi
    cd "$HOME_DIR"
else
    fail "cpc6128" "git clone nie powiodl sie"
fi

# ------------------------------------------------------------
section "8. Atari 1040ST (Hatari)"
# ------------------------------------------------------------
if sudo apt install -y hatari 2>>"$LOG_FILE"; then
    ok "atari_st"
    mkdir -p "$HOME_DIR/atarist/disks"
else
    log "Pakiet 'hatari' niedostepny w apt, probuje kompilacje ze zrodel..."
    cd "$HOME_DIR" || exit 1
    sudo apt install -y libreadline-dev libpng-dev zlib1g-dev libsdl2-dev 2>>"$LOG_FILE"
    if [ ! -d hatari ]; then
        git clone https://github.com/hatari/hatari.git 2>>"$LOG_FILE"
    fi
    if [ -d hatari ]; then
        cd hatari
        mkdir -p build && cd build
        if cmake .. >>"$LOG_FILE" 2>&1 && make -j4 >>"$LOG_FILE" 2>&1 && sudo make install >>"$LOG_FILE" 2>&1; then
            ok "atari_st"
            mkdir -p "$HOME_DIR/atarist/disks"
            log "UWAGA: wgraj wlasny obraz TOS (np. tos.img) - Hatari zapyta o niego przy pierwszym starcie"
        else
            fail "atari_st" "kompilacja Hatari nie powiodla sie - zobacz $LOG_FILE"
        fi
        cd "$HOME_DIR"
    else
        fail "atari_st" "nie udalo sie pobrac zrodel Hatari"
    fi
fi

# ------------------------------------------------------------
section "9. MSX (openMSX z apt - bez kompilacji, za ciezkie na Pi Zero)"
# ------------------------------------------------------------
if sudo apt install -y openmsx 2>>"$LOG_FILE"; then
    ok "msx"
    mkdir -p "$HOME_DIR/msx/disks"
else
    fail "msx" "pakiet openmsx niedostepny w apt - kompilacja ze zrodel pominieta (bardzo dlugi build na tym CPU), zrob to recznie pozniej jesli chcesz"
fi

# ------------------------------------------------------------
section "10. Amiga 500 (fs-uae z apt - bez kompilacji, ryzyko wydajnosciowe)"
# ------------------------------------------------------------
if sudo apt install -y fs-uae 2>>"$LOG_FILE"; then
    ok "amiga"
    mkdir -p "$HOME_DIR/amiga/disks"
    log "UWAGA: fs-uae wymaga wlasnego pliku Kickstart ROM (np. kick13.rom) - dodaj recznie"
else
    fail "amiga" "pakiet fs-uae niedostepny w apt - pominieto (Amiga na Pi Zero 2W to i tak eksperyment wydajnosciowy)"
fi

# ------------------------------------------------------------
section "11. Autologin na konsoli (tty1)"
# ------------------------------------------------------------
if sudo raspi-config nonint do_boot_behaviour B2 2>>"$LOG_FILE"; then
    ok "autologin"
else
    fail "autologin" "raspi-config nonint nie zadzialalo - ustaw recznie: sudo raspi-config -> System Options -> Boot/Auto Login -> Console Autologin"
fi

# ------------------------------------------------------------
section "12. Generowanie menu.sh na podstawie tego co sie zainstalowalo"
# ------------------------------------------------------------
MENU_PATH="$HOME_DIR/menu.sh"

{
echo '#!/bin/bash'
echo 'clear'
echo 'echo "=================================="'
echo 'echo "   RETRO MENU"'
echo 'echo "=================================="'

OPT=1
declare -A OPT_MAP

if [ "${STATUS[simcoupe]}" == "OK" ]; then
    echo "echo \"$OPT) SAM Coupe\""
    OPT_MAP[$OPT]="simcoupe"
    OPT=$((OPT+1))
fi
if [ "${STATUS[atari800]}" == "OK" ]; then
    echo "echo \"$OPT) Atari 800XL\""
    OPT_MAP[$OPT]="atari800"
    OPT=$((OPT+1))
fi
if [ "${STATUS[spectrum]}" == "OK" ]; then
    echo "echo \"$OPT) ZX Spectrum\""
    OPT_MAP[$OPT]="spectrum"
    OPT=$((OPT+1))
fi
if [ "${STATUS[c64]}" == "OK" ]; then
    echo "echo \"$OPT) Commodore 64\""
    OPT_MAP[$OPT]="c64"
    OPT=$((OPT+1))
fi
if [ "${STATUS[cpc6128]}" == "OK" ]; then
    echo "echo \"$OPT) Amstrad CPC 6128\""
    OPT_MAP[$OPT]="cpc6128"
    OPT=$((OPT+1))
fi
if [ "${STATUS[atari_st]}" == "OK" ]; then
    echo "echo \"$OPT) Atari 1040ST\""
    OPT_MAP[$OPT]="atari_st"
    OPT=$((OPT+1))
fi
if [ "${STATUS[msx]}" == "OK" ]; then
    echo "echo \"$OPT) MSX\""
    OPT_MAP[$OPT]="msx"
    OPT=$((OPT+1))
fi
if [ "${STATUS[amiga]}" == "OK" ]; then
    echo "echo \"$OPT) Amiga 500\""
    OPT_MAP[$OPT]="amiga"
    OPT=$((OPT+1))
fi

echo 'echo "0) Powloka (bash)"'
echo 'echo "=================================="'
echo 'read -p "Wybierz: " choice'
echo ''
echo 'case $choice in'

for key in "${!OPT_MAP[@]}"; do
    emu="${OPT_MAP[$key]}"
    echo "    $key)"
    case "$emu" in
        simcoupe)
            echo '        simcoupe -fullscreen'
            ;;
        atari800)
            echo '        atari800'
            ;;
        spectrum)
            echo '        fuse-sdl'
            ;;
        c64)
            echo '        x64sc'
            ;;
        cpc6128)
            echo '        cap32'
            ;;
        atari_st)
            echo '        hatari'
            ;;
        msx)
            echo '        openmsx'
            ;;
        amiga)
            echo '        fs-uae'
            ;;
    esac
    echo '        ;;'
done

echo '    0)'
echo '        exec bash'
echo '        ;;'
echo '    *)'
echo '        echo "Nieznana opcja"'
echo '        sleep 2'
echo '        ;;'
echo 'esac'
echo ''
echo 'exec ~/menu.sh'
} > "$MENU_PATH"

chmod +x "$MENU_PATH"
ok "menu_sh"
log "Wygenerowano $MENU_PATH z $((OPT-1)) dzialajacymi emulatorami"

# ------------------------------------------------------------
section "13. Autostart w ~/.profile"
# ------------------------------------------------------------
PROFILE="$HOME_DIR/.profile"
MARKER='if [ -z "$SSH_CONNECTION" ]'
if grep -q "$MARKER" "$PROFILE" 2>/dev/null; then
    python3 - <<EOF
path = "$PROFILE"
with open(path) as f:
    lines = f.readlines()
marker = 'if [ -z "\$SSH_CONNECTION" ]'
lines = [l for l in lines if marker not in l]
lines.append('if [ -z "\$SSH_CONNECTION" ] && [ "\$(tty)" = "/dev/tty1" ]; then ~/menu.sh; fi\n')
with open(path, "w") as f:
    f.writelines(lines)
EOF
else
    echo 'if [ -z "$SSH_CONNECTION" ] && [ "$(tty)" = "/dev/tty1" ]; then ~/menu.sh; fi' >> "$PROFILE"
fi
ok "autostart_profile"

# ------------------------------------------------------------
section "PODSUMOWANIE"
# ------------------------------------------------------------
echo ""
echo "Wynik instalacji poszczegolnych emulatorow:"
echo ""
for key in simcoupe atari800 spectrum c64 cpc6128 atari_st msx amiga autologin menu_sh autostart_profile kms_overlay pakiety_bazowe; do
    status="${STATUS[$key]:-POMINIETO}"
    printf "  %-20s %s\n" "$key" "$status"
done
echo ""
echo "Pelny log: $LOG_FILE"
echo ""
echo "NASTEPNE KROKI:"
echo "  1. Wgraj wlasne ROM-y tam gdzie wymagane (Atari800, CPC, Atari ST, Amiga)"
echo "  2. Wgraj obrazy dyskow do odpowiednich folderow (~/samcoupe/disks, ~/c64/disks, itd.)"
echo "  3. Zrestartuj Pi: sudo reboot"
echo ""
