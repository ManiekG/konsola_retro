# Emulatory — status i konfiguracja

## SimCoupe (SAM Coupé) — ✅ działa

Zbudowany ze źródeł (patrz `SETUP.md`). ROM dołączony w repo źródłowym,
instaluje się automatycznie.

Obrazy dysków: `~/samcoupe/disks/dyski_sam/`
(pliki `.dsk` — format Amstrad/Spectrum Extended DSK)

Uruchomienie ręczne:
```bash
simcoupe autoboot -disk1 "/home/<user>/samcoupe/disks/dyski_sam/gra.dsk" -fullscreen
```

## Atari800 (Atari 8-bit: 400/800/XL/XE) — ✅ skompilowany

Pakiet apt niedostępny w repo Trixie → budowa ze źródeł.

```bash
sudo apt install -y libsdl2-dev zlib1g-dev libpng-dev autoconf automake libtool
cd ~
git clone https://github.com/atari800/atari800.git
cd atari800
./autogen.sh
./configure --target=default
make -j4
sudo make install
```

**Uwaga:** ROM-y systemowe Atari (OS + BASIC) NIE są dołączone
(prawa autorskie) — trzeba mieć własne pliki (np. `atarixl.rom`,
`atarixlbas.rom`) i wgrać do `~/.atari800/`:
```bash
mkdir -p ~/.atari800
scp atarixl.rom atarixlbas.rom <user>@<IP>:~/.atari800/
```

Katalog na obrazy dysków/kaset: `~/atari/disks/`

## Plan: menu tekstowe wyboru emulatora

Zamiast pełnego RetroPie (cięższy, wolniejszy boot), prosty skrypt
bash wybierający między zainstalowanymi emulatorami. Podmienia
pojedynczą komendę SimCoupe w `~/.profile` na wywołanie skryptu.

Szkic `~/menu.sh`:
```bash
#!/bin/bash
clear
echo "=================================="
echo "   RETRO MENU"
echo "=================================="
echo "1) SAM Coupe - Prince of Persia"
echo "2) Atari 800 XE"
echo "0) Powloka (bash)"
echo "=================================="
read -p "Wybierz: " choice

case $choice in
    1) simcoupe autoboot -disk1 "/home/<user>/samcoupe/disks/dyski_sam/prince_of_persia.dsk" -fullscreen ;;
    2) atari800 ;;
    0) exec bash ;;
    *) echo "Nieznana opcja"; sleep 2; exec bash ;;
esac

exec ~/menu.sh   # po zamknięciu emulatora wróć do menu
```

`~/.profile`:
```bash
if [ -z "$SSH_CONNECTION" ] && [ "$(tty)" = "/dev/tty1" ]; then ~/menu.sh; fi
```

## Rozważane, nie zrealizowane

- **ZX Spectrum (`fuse-emulator-sdl`)** — pakiet dostępny w apt,
  zainstalowany, nieprzetestowany jeszcze w menu.
- **Commodore 64 (`vice`/`x64sc`)** — pakiet `vice` niedostępny pod tą
  nazwą w repo Trixie; zamiennik: **Atari 800XE** (użytkownik
  zdecydował się na Atari zamiast C64).
- **Pełny RetroPie** — rozważony jako alternatywa, odrzucony na rzecz
  lekkiego, szybko bootującego setupu bez X11/frontendu.

## Joystick / gamepad

Plan (niezrealizowany jeszcze): pad USB przez hub OTG, wykrywany jako
`/dev/input/js0` przez sterownik `joydev` — zero dodatkowej
konfiguracji systemowej. Test:
```bash
sudo apt install -y joystick
jstest /dev/input/js0
```
Alternatywa: oryginalny joystick retro (DB9, Atari/Competition
Pro/Amiga/C64) przez adapter USB.

SimCoupe: konfiguracja joysticka w menu **F10 → Options → Joystick**.
Atari800: obsługa wbudowana, flaga uruchomieniowa do potwierdzenia.
