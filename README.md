# Retro Computing Setup

Dokumentacja całego systemu retro-emulacji — od researchu sprzętowego,
przez budowę dedykowanej maszynki na Raspberry Pi Zero 2W, po
konfigurację 11 emulatorów retro-platform z bibliotekami gier.

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

## Status na teraz — 11 platform w pelni dzialajacych

- ✅ **SAM Coupé** (SimCoupe) — 1314 gier
- ✅ **Atari 800XL** (Atari800) — 5647 gier
- ✅ **Sinclair — ZX Spectrum 48K/+3** (fuse-sdl, submenu) — 17867 plikow (DSK/TAP/TZX)
- ✅ **Atari 1040ST** (Hatari) — ~173 gry
- ✅ **MSX** (openMSX)
- ✅ **Amiga 500** (fs-uae) — 15804 gry (z 26373 w pelnej kolekcji TOSEC — reszta wymaga wiekszej karty)
- ✅ **Commodore — C64/C128/VIC-20/Plus4-C16** (VICE, submenu):
  C64 8323 gier, C128 64 pliki, VIC-20 3503 gry, Plus4/C16 2623 gry
- ✅ **Amstrad CPC 6128** (Caprice32) — 5745 gier + 40 kompilacji dwustronnych
- ✅ **Apple II** (LinApple) — 1094 gry

**Zmagazynowane, czekaja na emulator (Fuse nie wspiera tych platform):**
- 📦 **ZX81** — 1171 gier w `~/zx81/disks/`
- 📦 **ZX80** — 70 plikow w `~/zx80/disks/`
- Kandydat na emulator: **ZEsarUX** (obsluguje ZX80/ZX81/Spectrum w jednym, SDL, bez X11)

**Menu:** przebudowane na graficzne (`whiptail`) z zagniezdzonymi podmenu
(Commodore, Sinclair) zamiast plaskiej listy 11 pozycji. Gotowe skrypty
w [`scripts/`](scripts/).

**Lacznie: ~62 000 plikow gier** na 11 dzialajacych platformach.

## Znane problemy sprzetowe/systemowe rozwiazane po drodze

- **Overscan na HDMI** (lewa krawedz obrazu ucieta) — naprawione przez
  parametr `video=HDMI-A-1:1920x1080M@60,margin_left=40,...` w
  `/boot/firmware/cmdline.txt`. Stare `overscan_left/right/top/bottom`
  w `config.txt` NIE dzialaja w pelnym KMS (`disable_fw_kms_setup=1`).
- **Karta SD zbyt mala na pelne kolekcje** — 29GB karta osiagnela 82%
  zapelnienia po dodaniu wszystkich bibliotek; pelna kolekcja Amigi
  (23.8GB samodzielnie) musiala zostac przycieta do 60%. Wiekszy
  card = 64GB+ zalecany przy dalszej rozbudowie.
- **Zawieszony `dpkg` przetrwal `kill -9`** podczas instalacji
  ImageMagick (zaleznosc LinApple) — naprawione czystym `sudo reboot`
  + `sudo dpkg --configure -a`. `dmesg` byl czysty (nie byl to
  nawrot uszkodzenia karty).

## Backup karty SD

Pelny, zweryfikowany obraz karty (29GB → 12.3GB skompresowany) zrobiony
przez `dd | pv | gzip` z Maca na udzial Samby:
```bash
sudo dd if=/dev/rdiskN bs=4m | pv -s <ROZMIAR_BAJTY> | gzip > backup.img.gz
```
Odtworzenie:
```bash
gzip -dc backup.img.gz | sudo dd of=/dev/rdiskN bs=4m
```

## Planowane

- Obsługa joysticka/gamepada USB (`/dev/input/js0`, sterownik `joydev`)
- Docelowo: archiwizacja oryginalnych dyskietek SAM przez Greaseweazle
