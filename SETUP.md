# Setup od zera — Raspberry Pi Zero 2W + SimCoupe

## 1. Flashowanie karty SD

Raspberry Pi Imager → wybierz **Raspberry Pi OS Lite (32-bit)**.
Przed flashowaniem: ikonka zębatki (Ctrl+Shift+X) →
- ustaw hostname (np. `samcoupe`)
- włącz SSH (hasło lub klucz)
- skonfiguruj WiFi (SSID + hasło)
- ustaw użytkownika (uwaga: nowsze wersje Imagera nie tworzą już
  domyślnego konta `pi` — sam wybierasz nazwę użytkownika, np. `maniek`)

## 2. Połączenie SSH

```bash
ssh <user>@<hostname>.local
# lub po IP:
ssh <user>@192.168.x.x
```

Jeśli pojawi się `Host key verification failed` (np. po ponownym
flashowaniu karty na ten sam IP):
```bash
ssh-keygen -R <IP>
```

## 3. Aktualizacja i zależności do budowy SimCoupe

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y git build-essential cmake libsdl2-dev libsdl2-image-dev \
    zlib1g-dev libgtk-3-dev pkg-config
```

## 4. Kompilacja SimCoupe

```bash
git clone https://github.com/simonowen/simcoupe.git
cd simcoupe
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j4
sudo make install
sudo ldconfig   # odśwież cache linkera po instalacji do /usr/local/lib
```

ROM SAM Coupé (`samcoupe.rom`) jest dołączony w źródłach SimCoupe i
instaluje się automatycznie do `/usr/local/share/simcoupe/`.

## 5. Włączenie sterownika KMS (jeśli `/dev/dri/card0` nie istnieje)

```bash
grep vc4 /boot/firmware/config.txt
# jeśli brak wpisu:
sudo sh -c 'echo "dtoverlay=vc4-kms-v3d" >> /boot/firmware/config.txt'
sudo reboot
```

## 6. Katalog na obrazy dysków

```bash
mkdir -p ~/samcoupe/disks
```

Transfer plików z komputera (nowe okno terminala, NIE sesja SSH do Pi):
```bash
scp -r /sciezka/do/dyski_sam <user>@<IP>:~/samcoupe/disks/
```

## 7. Autologin na konsoli

```bash
sudo raspi-config
```
→ System Options → Boot / Auto Login → **Console Autologin** → Finish

## 8. Autostart SimCoupe

**Ważne:** użyj `~/.profile`, NIE `~/.bashrc`. Standardowy `.bashrc`
na Debianie ma na górze:
```bash
case $- in
    *i*) ;;
      *) return;;
esac
```
co przerywa wykonanie dla nie-interaktywnych/login shelli uruchamianych
przez `agetty --autologin` — linia dopisana na końcu `.bashrc` się nie
wykona. `.profile` działa niezawodnie.

```bash
echo 'if [ -z "$SSH_CONNECTION" ] && [ "$(tty)" = "/dev/tty1" ]; then simcoupe autoboot -disk1 "/home/<user>/samcoupe/disks/dyski_sam/gra.dsk" -fullscreen; fi' >> ~/.profile
```

Kluczowe flagi komendy (identyczne jak w oficjalnym module RetroPie):
- `autoboot` — bootuje dysk automatycznie zamiast zostawiać na ekranie
  startowym BASIC
- `-disk1 "ścieżka"` — obraz do stacji 1
- `-fullscreen` — pełny ekran

## 9. Restart i test

```bash
sudo reboot
```

Po restarcie Pi powinno zalogować się automatycznie i wystartować
prosto w SimCoupe z załadowaną grą.

## Sterowanie w SimCoupe

| Klawisz | Akcja |
|---|---|
| F1 | Otwórz/zmień dysk w stacji 1 |
| Shift+F1 | Wysuń dysk ze stacji 1 |
| F2 | To samo dla stacji 2 |
| F12 | Reset (wraca do ekranu startowego / rebootuje dysk jeśli autoboot) |
| F10 | Menu opcji |
| F8 | Przełącz fullscreen/okno |
| Ctrl+F12 | Wyjście z emulatora |
| Numpad 0-9 (z NumLock) | Klawisze funkcyjne samego SAM-a (F0-F9) |

Sekwencja zmiany gry: `Shift+F1` (wysuń) → `F1` (wybierz nowy plik) →
`F12` (reset, autoboot załaduje nową grę).
