# Notatki z researchu sprzętowego

Podsumowanie rozważanych platform przed wyborem Raspberry Pi Zero 2W
jako docelowej maszynki do emulacji SAM Coupé.

## Raspberry Pi Pico / Pico 2 (RP2040 / RP2350) — odrzucone jako główna platforma

- "Pico 16MB" — te 16 MB to **flash** (na program + dane), nie RAM.
  SAM Coupé potrzebuje 256–512 KB **RAM**, więc flash nie rozwiązuje
  głównego ograniczenia.
- RP2040: 264 KB SRAM — za mało bez zewnętrznego PSRAM.
- RP2350 (Pico 2): 520 KB SRAM — mieści 256 KB spokojnie, 512 KB na
  styk/z PSRAM.
- Brak gotowego emulatora SAM Coupé na Pico — istnieją porty
  Spectrum/MSX/SMS/NES/PC-286, ale nie Sama. Wymagałoby portowania
  SimCoupe (duży kod C++) na bare-metal.
- **Rola docelowa:** peryferia w fazie FPGA (USB HID, SD, most
  klawiatury) — nie jako serce emulatora.

## ESP32 (moduł WROOM na płytce Wemos/LOLIN D1 R32) — odrzucone

- Istnieje dojrzały emulator ZX Spectrum na ESP32 — **ESPectrum**
  (płytki Lilygo TTGo VGA32, Olimex ESP32-SBC-FabGL) — ale nie ma
  gotowego portu na SAM Coupé.
- WROOM (bez PSRAM) nie udźwignie 256/512 KB RAM Sama — potrzebny
  WROVER z PSRAM (np. moduł 8MB jak w ESP32-SBC-FabGL).
- Płytka D1 R32 (format Arduino Uno) nie ma złączy VGA/PS2 jak
  dedykowane płytki retro — wymagałoby ręcznego okablowania.
- **Rola docelowa:** MCU peryferyjne — WiFi do wgrywania obrazów
  dysków, most klawiatury w fazie FPGA.

## Raspberry Pi Zero v1.3 — dobra platforma, ale bez WiFi

- Jednordzeniowy ARM11 @1GHz, 512MB RAM — SimCoupe działa natywnie
  (pełny Linux), zero portowania.
- Brak WiFi/BT (to nie wersja "W") — utrudnia wgrywanie obrazów przez
  sieć, wymaga dongla USB WiFi albo pendrive'a/karty SD.

## Raspberry Pi Zero 2 W — wybrane ✅

- 4× Cortex-A53 @1GHz, 512MB RAM, WiFi/BT wbudowane.
- SimCoupe działa natywnie (Linux), zero portowania — najszybsza
  droga do "grywalnie teraz".
- WiFi pozwala na wygodny transfer obrazów dysków przez SCP/Samba
  zamiast żonglowania nośnikami fizycznymi.
- Wystarczająca moc dla 8-bitowców (SAM, Spectrum, Atari 8-bit, C64) —
  NIE dla cięższych platform (Amiga, PSX).

## Stary laptop Core2Duo — rozważane jako platforma developerska

- x86, gotowe binarki SimCoupe (Windows/Linux/macOS) — zero
  kompilacji.
- Można postawić bez Windowsa (Debian netinst bez GUI + ten sam
  mechanizm autologin/autostart co na Pi) — "SimCoupe appliance"
  bootujący prosto w emulator.
- Nie nadaje się do wsadzenia w drukowaną obudowę Sama (to laptop, nie
  kompaktowa płytka).
- **Rola:** platforma testowa/developerska równolegle do docelowego
  Pi Zero 2W w obudowie.

## Archiwizacja oryginalnych dyskietek SAM Coupé

- **SAMdisk** (Simon Owen, autor SimCoupe) — czyta niestandardowy
  10-sektorowy format Sama z prawdziwej stacji dyskietek.
- Wymaga **prawdziwego kontrolera FDC** (34-pin na płycie głównej) —
  stacje USB NIE działają (nie czytają 10. sektora ścieżki).
- Pełny surowy dostęp do FDC wymaga sterownika **`fdrawcmd.sys`**,
  który jest **wyłącznie pod Windows**. Wersje SAMdisk na Linux/macOS
  pracują na gotowych obrazach, ale nie dają surowego dostępu do
  fizycznej stacji.
- **Decyzja:** zamiast dual-boot do Windows, użyć **Greaseweazle**
  (USB, natywne wsparcie Linux/Mac/Windows, odczyt na poziomie
  fluxu) — spójny, w pełni linuksowy workflow.
