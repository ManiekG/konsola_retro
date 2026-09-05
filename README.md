# Retro Computing Setup

Dokumentacja całego systemu retro-emulacji — od researchu sprzętowego,
przez budowę dedykowanej maszynki na Raspberry Pi Zero 2W, po
konfigurację poszczególnych emulatorów (SAM Coupé, Atari 8-bit i
kolejne).

Powiązany projekt: [`ManiekG/sam-coupe`](https://github.com/ManiekG/sam-coupe)
— osobne repo na sprzętową reimplementację SAM Coupé (FPGA/RTL/PCB).
To repo dotyczy strony **emulacyjnej/software'owej** — maszynki, która
ma działać już teraz, zanim (lub obok) powstanie wersja sprzętowa.

## Sprzęt — platforma docelowa

- **Raspberry Pi Zero 2W** (4× Cortex-A53 @1GHz, 512MB RAM, WiFi) —
  główna platforma, wybrana po researchu obejmującym Pico/RP2040,
  ESP32, Pi Zero v1.3 (bez WiFi) i stary laptop Core2Duo
  (patrz [`HARDWARE-NOTES.md`](HARDWARE-NOTES.md))
- Karta SD
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
  problemy i ich rozwiązania (chronologicznie)
- [`EMULATORS.md`](EMULATORS.md) — status poszczególnych emulatorów
  (SimCoupe, Atari800, plany na Spectrum/inne), menu wyboru, joystick
- [`HARDWARE-NOTES.md`](HARDWARE-NOTES.md) — pełny research sprzętowy:
  Pico/RP2040, ESP32, warianty Pi Zero, laptop x86, archiwizacja
  dyskietek (SAMdisk/Greaseweazle)

## Status na teraz

- ✅ SimCoupe (SAM Coupé) — skompilowany, działa, autoboot gier z dysku
- ✅ Autologin + autostart z konsoli (bez X11)
- ✅ Klawiatura USB działa (po znalezieniu właściwego portu danych)
- 🔄 Atari800 (Atari 8-bit XE) — w trakcie kompilacji ze źródeł (pakiet
  apt niedostępny w repo Trixie)
- 📋 Planowane: proste menu tekstowe wyboru emulatora (SAM / Atari /
  kolejne), obsługa joysticka/gamepada, docelowo archiwizacja
  oryginalnych dyskietek SAM przez Greaseweazle
