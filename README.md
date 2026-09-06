# Retro Computing Setup

Dokumentacja całego systemu retro-emulacji — od researchu sprzętowego,
przez budowę dedykowanej maszynki na Raspberry Pi Zero 2W, po
konfigurację 8 emulatorów retro-platform.

Powiązany projekt: [`ManiekG/sam-coupe`](https://github.com/ManiekG/sam-coupe)
— osobne repo na sprzętową reimplementację SAM Coupé (FPGA/RTL/PCB).
To repo dotyczy strony **emulacyjnej/software'owej** — maszynki, która
ma działać już teraz, zanim (lub obok) powstanie wersja sprzętowa.

## Sprzęt — platforma docelowa

- **Raspberry Pi Zero 2W** (4× Cortex-A53 @1GHz, 512MB RAM, WiFi) —
  główna platforma, wybrana po researchu obejmującym Pico/RP2040,
  ESP32, Pi Zero v1.3 (bez WiFi) i stary laptop Core2Duo
  (patrz [`HARDWARE-NOTES.md`](HARDWARE-NOTES.md))
- Karta SD (min. 32GB zalecane przy 8 emulatorach + ROM-y + narzędzia
  budowania)
- Monitor HDMI
- Klawiatura USB (przez hub OTG micro-USB — **musi być w porcie danych
  "USB", nie "PWR IN"**, patrz [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md))
- Opcjonalnie: joystick/gamepad USB

## System

- Raspberry Pi OS Lite (Trixie / Debian 13), 32-bit
- Bez środowiska graficznego — emulatory renderują bezpośrednio przez
  SDL2 + KMS/DRM na konsoli tekstowej (tty1), autologin + autostart
  zamiast pełnego frontendu (RetroPie rozważony i odrzucony na rzecz
  lekkości i szybkiego bootu)

## Struktura repo

- [`SETUP.md`](SETUP.md) — pełna instrukcja od zera: flashowanie karty,
  SSH, kompilacja SimCoupe, autologin, autostart
- [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) — wszystkie napotkane
  problemy i ich rozwiązania (chronologicznie), w tym cała epopeja z
  uszkodzoną kartą SD
- [`EMULATORS.md`](EMULATORS.md) — status wszystkich 8 emulatorów,
  menu wyboru, joystick
- [`HARDWARE-NOTES.md`](HARDWARE-NOTES.md) — pełny research sprzętowy:
  Pico/RP2040, ESP32, warianty Pi Zero, laptop x86, archiwizacja
  dyskietek (SAMdisk/Greaseweazle)
- [`install_retro.sh`](install_retro.sh) — zautomatyzowany skrypt
  instalujący wszystkie 8 emulatorów od zera na świeżo zaflashowanej
  karcie

## Status na teraz — 8/8 platform działa ✅

- ✅ **SAM Coupé** (SimCoupe) — autoboot gier z dysku
- ✅ **Atari 800XL** (Atari800) — własne ROM-y, `VIDEO_ACCEL=0` dla
  poprawnego działania na GPU vc4
- ✅ **ZX Spectrum** (fuse-sdl + spectrum-roms z apt)
- ✅ **Atari 1040ST** (Hatari) — TOS 2.06 (256KB, plik `.img` nie
  `.st` — uwaga na dyskietki mylnie nazwane jako ROM), config zapisany
  trwale przez `--saveconfig`
- ✅ **MSX** (openMSX, z apt — uniknięto wielogodzinnej kompilacji ze
  źródeł na słabym CPU)
- ✅ **Amiga 500** (fs-uae, z apt) — Kickstart 1.3 (256KB) + Workbench 1.3
  skonfigurowane, ładuje się automatycznie z menu
- ✅ **Commodore 64** (VICE/x64sc) — kompilacja ze źródeł, wymaga flagi
  `--without-libcurl` w configure i ręcznego kopiowania binarki
  (`make install` nie generuje właściwej reguły w tym buildzie)
- ✅ **Amstrad CPC 6128** (Caprice32) — kompilacja ze źródeł zwykłym
  `make` (NIE CMake — mylące, bo repo ma folder `build/` ale bez
  CMakeLists.txt), wymaga `libsdl1.2-dev`; ROM = OS+BASIC 1985
  połączone w jeden plik 32KB w `~/rom/cpc6128.rom`

Menu wyboru (`~/menu.sh`, wywoływane z `~/.profile` na tty1) pokazuje
wszystkie 8 opcji + wyjście do powłoki.

## Ważna lekcja: karty SD i weryfikacja zdrowia

W trakcie budowy tego setupu jedna karta SD uległa **stopniowej
degradacji** w ciągu jednego dnia — zaczęło się od zwykłego "Pi nie
wstaje", a skończyło na deterministycznym `internal compiler error:
segmentation fault` w GCC i błędach `EXT4-fs error... checksum
invalid` zgłaszanych przez jądro w czasie rzeczywistym. `fsck` naprawia
tylko **strukturę** systemu plików, nie gwarantuje integralności
**zawartości** plików ani nie naprawia fizycznie uszkodzonych sektorów
flash. Szczegóły w [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md).

**Wniosek na przyszłość:** `install_retro.sh` zawiera teraz wbudowany
test zapisu/odczytu 200MB + sprawdzenie `dmesg` na samym początku,
żeby złapać umierającą kartę w pierwszej minucie, nie po czterech
godzinach kompilowania.

## Planowane

- Obsługa joysticka/gamepada USB (`/dev/input/js0`, sterownik `joydev`)
- Docelowo: archiwizacja oryginalnych dyskietek SAM przez Greaseweazle
