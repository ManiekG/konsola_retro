# Napotkane problemy i rozwiązania (chronologicznie)

## 1. `Host key verification failed`
**Przyczyna:** stary klucz SSH w `known_hosts` z poprzedniej instalacji
karty pod tym samym IP.
**Rozwiązanie:**
```bash
ssh-keygen -R <IP>
```

## 2. `Permission denied` przy loginie SSH
**Przyczyna:** nowsze wersje Raspberry Pi Imager nie tworzą domyślnego
użytkownika `pi` — trzeba się logować na użytkownika ustawionego
w Imagerze (np. `maniek`).
**Rozwiązanie:** `ssh <faktyczny_user>@<IP>`

## 3. `cmake: command not found`
**Przyczyna:** brak pakietu na świeżym Pi OS Lite.
**Rozwiązanie:** `sudo apt install -y cmake`

## 4. `error while loading shared libraries: libSAASound.so.3`
**Przyczyna:** biblioteka zainstalowana do `/usr/local/lib`, ale cache
linkera (`ldconfig`) nie odświeżony.
**Rozwiązanie:** `sudo ldconfig`

## 5. `simcoupe --version` wisi bez odpowiedzi
**Przyczyna:** SDL2 przez KMS/DRM próbuje przejąć fizyczną konsolę
(tty1), ale komenda była odpalona przez SSH — proces czeka na dostęp
do ekranu, którego sesja SSH nie ma.
**Rozwiązanie:** testować z lokalnej konsoli (monitor+klawiatura
podłączone bezpośrednio do Pi), albo skonfigurować od razu autostart
i obserwować efekt na monitorze.

## 6. `error: SDL init failed: kmsdrm not available`
**Przyczyna:** brakuje `/dev/dri/card0` — sterownik `vc4-kms-v3d`
(pełny KMS/mode-setting) nie był włączony w konfiguracji bootloadera.
Widoczny był tylko `renderD128` (render-node bez KMS).
**Rozwiązanie:**
```bash
sudo sh -c 'echo "dtoverlay=vc4-kms-v3d" >> /boot/firmware/config.txt'
sudo reboot
```
Po restarcie `/dev/dri/` powinno zawierać `card0` obok `renderD128`.

## 7. Ekran startowy pokazuje się, ale gra się nie ładuje
**Przyczyna:** brak flagi `autoboot` — bez niej SimCoupe zostaje na
ekranie startowym BASIC zamiast bootować dysk automatycznie. Zła
składnia flag (`--disk1` zamiast `-disk1`) też może mieć znaczenie
w zależności od wersji.
**Rozwiązanie:** użyć dokładnie takiej składni jak moduł RetroPie:
```
simcoupe autoboot -disk1 "sciezka.dsk" -fullscreen
```

## 8. Uszkodzone linie w `.bashrc` / `.profile` po edycji przez `sed`/`echo`
**Przyczyna:** nieostrożne użycie `sed`/`echo` z zagnieżdżonymi
cudzysłowami rozbiło jedną logiczną linię komendy na kilka linii
tekstu, co dawało błędy typu `-bash: .../.bashrc: line 115:
'fullscreen; fi'`.
**Rozwiązanie:** znaleźć wszystkie fragmenty przez `grep -n <fraza>
~/.bashrc`, usunąć każdą pasującą linię numerem (`sed -i 'Nd'
~/.bashrc`), zweryfikować `tail -5` na czysto, i wstawić poprawną
komendę na nowo — najlepiej całościowo przez Python/heredoc zamiast
serii `sed`, żeby uniknąć powtórki problemu.

## 9. Autostart w `.bashrc` nie uruchamia się mimo poprawnego autologinu
**Przyczyna:** standardowy Debianowy `.bashrc` zaczyna się od:
```bash
case $- in
    *i*) ;;
      *) return;;
esac
```
Ten `return` przerywa dalsze wykonanie pliku w kontekście, w jakim
`agetty --autologin` uruchamia powłokę — linia dopisana na końcu
pliku nigdy się nie wykonuje.
**Rozwiązanie:** przenieść komendę autostartu z `.bashrc` do
`~/.profile`, który nie ma takiego warunku i wykonuje się niezawodnie
przy każdym login shellu.

## 10. Klawiatura USB nie działa (SimCoupe nie reaguje na klawisze)
**Przyczyna:** klawiatura (przez hub OTG) była podłączona do portu
micro-USB **PWR IN** (tylko zasilanie), zamiast do portu **USB**
(dane). Potwierdzone przez `lsusb` — widoczny był tylko wewnętrzny
root hub, żadne zewnętrzne urządzenie.
**Rozwiązanie:** podłączyć hub do środkowego portu micro-USB (dane),
zasilanie zostawić w porcie skrajnym (PWR IN). Diagnostyka:
```bash
lsusb                        # czy w ogóle widać urządzenie na magistrali
cat /proc/bus/input/devices  # czy widać realne urządzenie klawiatury
groups <user>                 # czy user ma grupy video/render/input
```

## 11. `sudo apt install atari800` → `Unable to locate package`
**Przyczyna:** system na świeżym Raspberry Pi OS **Trixie** (Debian
13) — repo Trixie jest bardzo młode i część pakietów (w tym
`atari800` z sekcji `contrib`) jeszcze tam nie dojechała, mimo że
istnieje w Debian bookworm/sid.
**Rozwiązanie:** budowa ze źródeł (patrz `EMULATORS.md`).

## 12. `./configure --target=sdl` → błąd, zła nazwa targetu
**Przyczyna:** `sdl` nie jest poprawną nazwą targetu w configure
skrypcie Atari800; dokumentacja BUILD.RPI wskazuje, że dla Pi OS
Bullseye i nowszych (w tym Trixie) właściwy jest target `default`
(autodetekcja bibliotek graficznych przez KMS) — stary target `rpi`
jest tylko dla Stretch/Buster i zależy od wycofanych bibliotek
Broadcom.
**Rozwiązanie:** `./configure --target=default`
