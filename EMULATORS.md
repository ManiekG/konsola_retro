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

## Atari800 (Atari 8-bit: 400/800/XL/XE) — ✅ działa

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

**ROM-y systemowe** (OS + BASIC) NIE są dołączone (prawa autorskie) —
własne pliki wgrane do `~/.atari800/`:
```bash
mkdir -p ~/.atari800
scp ATARIXL.ROM ATARIBAS.ROM <user>@<IP>:~/.atari800/
```

Skonfigurowane pliki: `ATARIXL.ROM` (16KB, OS dla XL/XE),
`ATARIBAS.ROM` (8KB, kartridż BASIC). Zapasowo dostępne też
`ATARIOSB.ROM`, `Atariosa.rom`, `atari5200.rom` (nieużywane na razie).

### Konfiguracja `~/.atari800.cfg`

`atari800 -configure` tworzy szkielet configu z **pustymi** ścieżkami
ROM-ów — trzeba je wpisać ręcznie. Kluczowe wpisy:

```ini
ROM_XL/XE_CUSTOM=/home/<user>/.atari800/ATARIXL.ROM
OS_XL/XE_VERSION=CUSTOM
ROM_BASIC_CUSTOM=/home/<user>/.atari800/ATARIBAS.ROM
BASIC_VERSION=CUSTOM
VIDEOMODE_WINDOWED=0
VIDEO_ACCEL=0
```

`VIDEO_ACCEL=0` jest krytyczne — domyślnie `1` (OpenGL), co na GPU
vc4 (Pi Zero 2W, OpenGL ES a nie pełny OpenGL) kończy się błędem
`EGL_BAD_MATCH` przy starcie. Po ustawieniu na `0` emulator wraca do
zwykłego renderowania SDL2 i startuje poprawnie (potwierdzone:
`Video Mode: 1024x768x32 fullscreen`, bez błędów).

Katalog na obrazy dysków/kaset (jeszcze nieużywany): `~/atari/disks/`

## Menu wyboru emulatora — ✅ wdrożone

Zamiast pełnego RetroPie (cięższy, wolniejszy boot), prosty skrypt
bash wybierający między zainstalowanymi emulatorami. `~/.profile`
wywołuje `~/menu.sh` zamiast wprost jednego emulatora.

`~/menu.sh`:
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
    1)
        simcoupe autoboot -disk1 "/home/maniek/samcoupe/disks/dyski_sam/prince_of_persia.dsk" -fullscreen
        ;;
    2)
        atari800
        ;;
    0)
        exec bash
        ;;
    *)
        echo "Nieznana opcja"
        sleep 2
        ;;
esac

exec ~/menu.sh
```

`~/.profile` (ostatnia linia):
```bash
if [ -z "$SSH_CONNECTION" ] && [ "$(tty)" = "/dev/tty1" ]; then ~/menu.sh; fi
```

**Uwaga przy tworzeniu plików wieloliniowych przez SSH:** heredoc
bash (`cat > plik << 'EOF' ... EOF`) bywa zawodny przy wklejaniu przez
sesję SSH — potrafi się przerwać w trakcie i zostawić urwany plik ze
słowem `EOF`/`SCRIPT` wyświetlonym jako nierozpoznana komenda.
Bezpieczniejsza metoda: heredoc Pythona z `open()/write()`, mniej
podatny na rozjazdy przy wklejaniu długich bloków.

## Rozważane, nie zrealizowane

- **ZX Spectrum (`fuse-emulator-sdl`)** — pakiet dostępny w apt,
  jeszcze niezainstalowany/niedodany do menu.
- **Commodore 64 (`vice`/`x64sc`)** — pakiet `vice` niedostępny pod tą
  nazwą w repo Trixie; zamiennik: **Atari 800XE** (zrealizowany).
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
Atari800: obsługa wbudowana w `.atari800.cfg`
(`SDL2_JOY_PORT_*` — domyślnie już skonfigurowane pod klawiaturę
jako joystick 1, sprzętowy pad jeszcze nietestowany).

## Commodore 64 (VICE / x64sc) — ✅ działa

Pakiet `vice` niedostępny w repo Trixie → budowa ze źródeł (mirror
GitHub, ponieważ oficjalne repo jest na SourceForge SVN):

```bash
sudo apt install -y libpng-dev libjpeg-dev flac libflac-dev libvorbis-dev \
    libpcap-dev portaudio19-dev texinfo dos2unix xa65 bison flex \
    libcurl4-openssl-dev
git clone --depth 1 https://github.com/VICE-Team/svn-mirror.git vice-source
cd vice-source/vice
./autogen.sh
./configure --enable-sdl2ui --without-oss --disable-catweasel \
    --disable-parsid --without-libcurl
make -j1   # NIE -j4 na 512MB RAM — ryzyko OOM i zawieszenia systemu
```

**Kluczowe pułapki:**
- Domyślny `configure` wymaga `libcurl` (>= 7.66.0) nawet z
  zainstalowanym `libcurl4-openssl-dev` — `pkg-config` go nie widział
  mimo obecności pakietu. Najprostsze obejście: `--without-libcurl`
  (curl służy tylko do sprawdzania aktualizacji, nie do emulacji).
- **`make install` nie generuje właściwej reguły** w tym buildzie
  (`No rule to make target 'install'`) — binarkę trzeba skopiować
  ręcznie:
  ```bash
  sudo cp src/x64sc /usr/local/bin/
  sudo chmod +x /usr/local/bin/x64sc
  ```
- Kompilacja z `-j4` na Pi Zero 2W (512MB RAM) ryzykuje zawieszenie
  całego systemu (WiFi/SSH przestaje odpowiadać) — używać `-j1`.

Katalog na obrazy dysków: `~/c64/disks/`

## Amstrad CPC 6128 (Caprice32) — ✅ działa

Repo ma folder `build/`, co myląco sugeruje CMake — **to zwykły
projekt Makefile** (plik `makefile` w katalogu głównym, bez wielkiej
litery, bez `CMakeLists.txt` nigdzie w drzewie):

```bash
sudo apt install -y libsdl1.2-dev libfreetype-dev zlib1g-dev libpng-dev
git clone https://github.com/ColinPitrat/caprice32.git
cd caprice32
make WITHOUT_GL=TRUE
sudo cp cap32 /usr/local/bin/
sudo chmod +x /usr/local/bin/cap32
```

`WITHOUT_GL=TRUE` jest ważne — domyślnie próbuje użyć pełnego OpenGL,
którego GPU vc4 (Pi Zero 2W) nie ma (tylko OpenGL ES).

**Uwaga o segfaultach kompilatora:** podczas pierwszego podejścia (na
karcie SD, która później okazała się uszkodzona) kompilacja wielokrotnie
kończyła się `internal compiler error: Segmentation fault` dokładnie
w tym samym miejscu (`src/fdc.cpp`), mimo reinstalacji GCC i zmiany
flag optymalizacji. Na zdrowej karcie SD build przechodzi bez
problemu — jeśli GCC segfaultuje deterministycznie w tym samym miejscu
kompilacji, to przede wszystkim podejrzewać kartę SD/pamięć, nie kod
(patrz `TROUBLESHOOTING.md`).

ROM-y CPC 6128 (własne, nie dołączone): `~/.capriceConfig/`
Katalog na obrazy dysków: `~/cpc/disks/`
