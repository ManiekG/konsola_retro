# Update 2026-09-08 — Amiga 1200 / WHDLoad

Pakiet uzupełniający do repo `ManiekG/konsola_retro`. To jest nowsza wersja wcześniejszego pakietu, którego jeszcze nie było pushowane.

## Co zostało potwierdzone

- Amiga 1200 działa w `Amiberry-Lite 5.9.2` na Raspberry Pi Zero 2 W / Raspberry Pi OS Trixie 32-bit.
- WHDLoad działa z istniejącej biblioteki `/home/maniek/amiga/harddrive/a1200` bez duplikowania gier.
- `Arkanoid`, `IK+` i `Elvira` uruchamiają się poprawnie.
- Dźwięk działa; w Arkanoidzie klawisz `A` przełącza dźwięk gry.
- `Savegames` jest przypisane przez `WHDLoadSave: DH0:`.
- Stary `Devs/system-configuration` powodował czarny ekran i pozostaje jako `system-configuration.old`.
- Kill switch przez Scroll Lock obejmuje `amiberry-lite`.

## Nowa organizacja WHDLoad w menu

Naprawiono koncepcję pickera dla A1200. Zamiast uruchamiania starego FS-UAE bez listy gier, menu WHDLoad przegląda katalogi bezpośrednio z:

`/home/maniek/amiga/harddrive/a1200`

Biblioteka jest teraz dzielona logicznie na litery:

`A -> gry na A`, `B -> gry na B`, ... `Z -> gry na Z`, `0-9 / inne`.

Nie są tworzone fizyczne katalogi A-Z i nie są przenoszone gry. Filtrowanie odbywa się dynamicznie po nazwie katalogu gry.

Katalogi techniczne są pomijane: `C`, `Devs`, `Libs`, `S`, `WHDBooter`, `Savegames`.

Wybrany katalog gry jest montowany jako `DH1`, a system WHDLoad jako `DH0`. Picker wyszukuje `*.slave` bez rozróżniania wielkości liter i generuje prosty `S/startup-sequence` dla wybranej gry.

## Elvira — DOS-Error #205

`Elvira` zgłaszała DOS-Error #205 mimo prawidłowej lokalizacji `Elvira.Slave`. Przyczyną był brak dodatkowego Kickstartu wymaganego przez konkretny slave WHDLoad.

README Elviry wymaga A500 Kickstart 1.3 rev. 34.5 jako:

`/home/maniek/amiga/harddrive/a1200/Devs/Kickstarts/kick34005.A500`

oraz odpowiadającego pliku:

`kick34005.A500.RTB`

Po dodaniu ROM-u Elvira działa. Nie oznacza to zmiany emulowanej maszyny na A500: Amiberry nadal uruchamia A1200 z Kickstartem 3.1, a ROM A500 jest używany przez WHDLoad/kickemu tylko dla gier, które go wymagają.

## Pliki w tym pakiecie

- `docs/AMIGA-AMIBERRY.md` — pełna zaktualizowana dokumentacja.
- `scripts/amiga_picker_whdload_block.sh` — aktualny, przetestowany blok logiki WHDLoad do włączenia w `~/amiga_picker.sh`.

Pakiet nie nadpisuje wcześniejszych zmian repo (LinApple, ZX80/ZX81, overscan, troubleshooting SD/dpkg itd.).

Po skopiowaniu plików do repo:

```bash
git add docs/AMIGA-AMIBERRY.md scripts/amiga_picker_whdload_block.sh UPDATE_NOTES.md
git commit -m "Amiga 1200: WHDLoad picker A-Z, Amiberry i Kickstart 1.3"
git push origin main
```
