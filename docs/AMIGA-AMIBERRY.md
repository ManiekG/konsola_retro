# Amiga 1200 / Amiberry-Lite / WHDLoad

Stan zweryfikowany na Raspberry Pi Zero 2 W, Raspberry Pi OS Lite Trixie 32-bit (armhf).

## Dlaczego Amiberry-Lite

FS-UAE 3.1.66 na tej konfiguracji wykazywał problemy z audio (PipeWire/OpenAL, underruny) i niestabilność. Dla Amigi 1200/WHDLoad wybrano Amiberry-Lite. Amiga 500 może na razie pozostać na FS-UAE.

## Emulator

Działa Amiberry-Lite 5.9.2. Oficjalny pakiet Trixie ARMHF wymagał dostosowania nazw zależności do wariantów t64:

- libmpg123-0 -> libmpg123-0t64
- libpng16-16 -> libpng16-16t64
- libpcap0.8 -> libpcap0.8t64

Binarka: `/usr/bin/amiberry-lite`.

## Kickstart

Główny ROM A1200:

`/home/maniek/amiga/system/kickstart31.rom`

CRC32: `1483a091` (Kickstart 3.1 rev. 40.68 A1200).

Dla WHDLoad utworzono również:

```bash
ln -sf /home/maniek/amiga/system/kickstart31.rom \
  /home/maniek/amiga/harddrive/a1200/Devs/Kickstarts/kick40068.A1200
```

## Ważna poprawka obrazu AmigaDOS

Stary plik:

`/home/maniek/amiga/harddrive/a1200/Devs/system-configuration`

powodował czarny/niewidoczny ekran po zamontowaniu prawdziwego DH0. Został zachowany jako:

`system-configuration.old`

Nie przywracać go bez potrzeby.

## Układ danych

System/booter i biblioteka WHDLoad znajdują się pod:

`/home/maniek/amiga/harddrive/a1200`

Gry są katalogami, np.:

- `Arkanoid/Arkanoid.Slave`
- `IK+/IK+.slave`
- `ColonizationAGA/`
- `IndianaJonesAtlantisAdv/`

Nie należy duplikować tej biblioteki. Picker powinien wskazywać istniejące katalogi.

## Sprawdzony sposób uruchamiania WHDLoad

System jest montowany jako DH0, a wybrany katalog gry jako DH1. Przykład Arkanoid:

```bash
amiberry-lite \
  --model A1200 \
  -r /home/maniek/amiga/system/kickstart31.rom \
  -m DH0:/home/maniek/amiga/harddrive/a1200 \
  -m DH1:/home/maniek/amiga/harddrive/a1200/Arkanoid \
  -s fastmem_size=8 \
  -G
```

Minimalny startup dla bezpośredniego startu gry:

```text
C:Assign ENV: RAM:
C:Assign T: RAM:
C:Assign WHDLoadSave: DH0:

CD DH1:
DH0:C/WHDLoad Arkanoid.Slave PRELOAD SPLASHDELAY=0

C:Wait 15
```

Katalog zapisów:

```bash
mkdir -p /home/maniek/amiga/harddrive/a1200/Savegames
```

Bez `WHDLoadSave:` WHDLoad może zgłaszać DOS-Error #218 przy `WHDLoadSave:Savegames/`.

## Audio — wynik diagnostyki

HDMI/ALSA działa prawidłowo. `speaker-test` na `vc4-hdmi` daje dźwięk, a Amiberry otwiera urządzenie SDL2 poprawnie.

IK+ uruchomiony przez WHDLoad ma dźwięk. Oznacza to, że Amiberry, SDL, HDMI, ALSA i emulacja Paula działają.

Arkanoid początkowo był niemy, ale nie był to błąd emulatora. Dokumentacja instalacji WHDLoad podaje:

`A - toggle sound on/off`

Po naciśnięciu `A` dźwięk w Arkanoidzie działa.

Wniosek: nie zmieniać globalnych ustawień ALSA/SDL z powodu ciszy w pojedynczej grze; najpierw sprawdzić README/tooltypes konkretnego slave'a.

## CPU / RAM

Próba wymuszenia 68000 zakończyła się komunikatem, że system wymaga 68020. Konfiguracja robocza pozostaje A1200/68020 z Fast RAM; 8 MB działa poprawnie.

## Stary WHDBooter

Oryginalny `S/startup-sequence` pochodzi ze środowiska WHDBooter i zakłada kilka wolumenów (DH0/DH1/DH2), m.in. `WHDLoadGame:`, `WHDLoadSave:` i `Devs/Kickstarts`. Nie należy bezrefleksyjnie używać go jako prostego startupu dla pojedynczej gry.

## Integracja z menu — docelowo

Menu pozostaje:

```text
Amiga
├── Amiga 500 (OCS)
└── Amiga 1200 (AGA)
```

Plan:

- A500: na razie FS-UAE.
- A1200: Amiberry-Lite.
- `Amiga 1200 -> WHDLoad` ma wyświetlać katalogi gier bezpośrednio z `/home/maniek/amiga/harddrive/a1200` i po wyborze montować katalog jako DH1.
- katalogi techniczne (`C`, `Devs`, `Libs`, `S`, `WHDBooter`, `Savegames`) muszą być odfiltrowane.
- dla wybranej gry picker powinien wykryć `*.Slave`/`*.slave` i wygenerować/wykorzystać prosty startup uruchamiający `DH0:C/WHDLoad`.
- istniejąca biblioteka nie może być kopiowana ani przenoszona.

## Scroll Lock / kill switch

`kill_emulator.sh` zawiera `amiberry-lite` w PATTERN, więc istniejący mechanizm zamykania emulatora obejmuje również Amiberry-Lite.

## Stan końcowy pickera WHDLoad — 2026-09-08

Pierwotny blok dla opcji `H` w `amiga_picker.sh` uruchamiał tylko:

```bash
fs-uae "${BASE_ARGS[@]}"
```

Dlatego menu `Amiga 1200 -> WHDLoad` nie pokazywało katalogów gier.

Zastąpiono tę logikę dynamicznym pickerem WHDLoad. Picker:

1. Czyta katalogi bezpośrednio z `/home/maniek/amiga/harddrive/a1200`.
2. Pomija katalogi techniczne: `C`, `Devs`, `Libs`, `S`, `WHDBooter`, `Savegames`.
3. Pokazuje najpierw litery A-Z oraz `0-9 / inne`.
4. Po wyborze litery pokazuje tylko gry zaczynające się od tej litery.
5. Wymaga obecności pliku `*.slave`/`*.Slave`.
6. Montuje wybraną grę jako `DH1`.
7. Generuje minimalny `S/startup-sequence` i startuje `amiberry-lite` jako A1200.

Dzięki temu nawet duża biblioteka WHDLoad pozostaje czytelna bez przenoszenia plików do fizycznych katalogów A-Z.

### Elvira i dodatkowy Kickstart A500 1.3

Elvira początkowo kończyła się `DOS-Error #205`. Sam `Elvira.Slave` był obecny bezpośrednio w katalogu gry. README instalacji wskazał właściwą przyczynę: ta wersja slave używa kickemu i wymaga obrazu A500 Kickstart 1.3 rev. 34.5.

Wymagane pliki:

```text
/home/maniek/amiga/harddrive/a1200/Devs/Kickstarts/kick34005.A500
/home/maniek/amiga/harddrive/a1200/Devs/Kickstarts/kick34005.A500.RTB
```

Po dodaniu ROM-u `kick34005.A500` Elvira uruchamia się poprawnie.

To nie zmienia głównego modelu emulacji. A1200 nadal startuje przez:

```bash
amiberry-lite \
  --model A1200 \
  -r /home/maniek/amiga/system/kickstart31.rom \
  -m DH0:/home/maniek/amiga/harddrive/a1200 \
  -m "DH1:$GAME_DIR" \
  -s fastmem_size=8 \
  -G
```

Kickstart A500 jest dodatkowym ROM-em używanym przez WHDLoad tylko dla wybranych starszych gier.

### Gry zweryfikowane

- Arkanoid — działa; dźwięk przełączany klawiszem `A`.
- IK+ — działa z dźwiękiem.
- Elvira — działa po dodaniu `kick34005.A500`.
