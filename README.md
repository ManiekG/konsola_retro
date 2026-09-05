# SAM Coupé / Retro Emulation na Raspberry Pi Zero 2W

Dokumentacja budowy dedykowanej maszynki retro na Raspberry Pi Zero 2W —
bezpośredni boot do SimCoupe (emulator SAM Coupé) z konsoli tekstowej,
bez X11/desktopu, plus rozbudowa o dodatkowe emulatory (Atari 8-bit i inne).

## Sprzęt

- Raspberry Pi Zero 2W (4× Cortex-A53 @1GHz, 512MB RAM, WiFi)
- Karta SD
- Monitor HDMI
- Klawiatura USB (przez hub OTG micro-USB)
- Opcjonalnie: joystick/gamepad USB do Atari/SAM

## System

- Raspberry Pi OS Lite (Trixie / Debian 13), 32-bit
- Bez środowiska graficznego — emulatory renderują bezpośrednio przez
  SDL2 + KMS/DRM na konsoli tekstowej (tty1)

## Struktura repo

- [`SETUP.md`](SETUP.md) — pełna instrukcja od zera: flashowanie karty,
  SSH, kompilacja SimCoupe, autologin, autostart
- [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) — wszystkie napotkane
  problemy i ich rozwiązania (chronologicznie)
- [`EMULATORS.md`](EMULATORS.md) — status poszczególnych emulatorów
  (SimCoupe, Atari800, plany na Spectrum/inne) i menu wyboru
- [`HARDWARE-NOTES.md`](HARDWARE-NOTES.md) — notatki z researchu
  sprzętowego (dlaczego Pi Zero 2W, a nie ESP32/Pico/RetroPie)

## Status na teraz

- ✅ SimCoupe skompilowany i działający, autoboot gier z dysku
- ✅ Autologin + autostart z konsoli (bez X11)
- ✅ Klawiatura USB działa (po znalezieniu właściwego portu danych)
- 🔄 Atari800 — w trakcie kompilacji ze źródeł (pakiet apt niedostępny
  w repo Trixie)
- 📋 Planowane: proste menu tekstowe wyboru emulatora, obsługa joysticka
