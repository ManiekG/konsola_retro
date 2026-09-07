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

## 13. `OpenGL context could not be created: EGL_BAD_MATCH` (Atari800)
**Przyczyna:** Atari800 domyślnie próbuje użyć akceleracji OpenGL
(`VIDEO_ACCEL=1` w configu), ale GPU vc4 na Pi Zero 2W udostępnia
tylko OpenGL ES, nie pełny OpenGL — kontekst EGL się nie tworzy.
Flaga uruchomieniowa `-no-opengl` NIE nadpisuje ustawienia zapisanego
w `~/.atari800.cfg`.
**Rozwiązanie:** edytować config bezpośrednio:
```
VIDEO_ACCEL=0
```
Po zmianie emulator wraca do zwykłego renderowania SDL2 (potwierdzone:
`Video Mode: 1024x768x32 fullscreen`, bez błędu).

## 14. Puste ścieżki ROM-ów po `atari800 -configure`
**Przyczyna:** `-configure` tworzy tylko szkielet pliku konfiguracyjnego
ze wszystkimi kluczami `ROM_*=` pustymi — nie skanuje automatycznie
systemu w poszukiwaniu plików ROM.
**Rozwiązanie:** ręcznie wpisać ścieżki do własnych plików ROM oraz
ustawić odpowiadające pola wersji na `CUSTOM`:
```
ROM_XL/XE_CUSTOM=/home/<user>/.atari800/ATARIXL.ROM
OS_XL/XE_VERSION=CUSTOM
ROM_BASIC_CUSTOM=/home/<user>/.atari800/ATARIBAS.ROM
BASIC_VERSION=CUSTOM
```

## 15. Heredoc bash (`cat > plik << 'EOF' ... EOF`) urywa się w trakcie wklejania przez SSH
**Przyczyna:** przy wklejaniu długiego wieloliniowego bloku do sesji
SSH terminal bywa zawodny — połączenie/bufor gubi część linii,
zamykające słowo heredoc (`EOF`, `SCRIPT`) ląduje jako osobna,
niepowiązana komenda (`-bash: SCRIPT: command not found`), a plik
wynikowy jest niekompletny.
**Rozwiązanie:** używać heredoc Pythona z jawnym `open()/write()`
zamiast heredoc bashowego — mniej podatny na tego typu rozjazdy przy
wklejaniu przez SSH. Zawsze weryfikować `cat <plik>` po zapisie, zanim
plik zostanie użyty (np. `chmod +x` i uruchomienie).

## 16. Epopeja uszkodzonej karty SD — objawy, diagnoza, decyzja

Po kilku godzinach intensywnych kompilacji (SimCoupe, Atari800, VICE)
Pi przestało wstawać rano ("Pi nie wstaje", dioda zielona miga krótko
i zostaje zapalona na stałe, zero obrazu na HDMI).

**Diagnoza krok po kroku:**
1. Sprawdzenie diod PWR/ACT — zasilanie OK, karta czytana ale system
   nie startuje w pełni.
2. Wyjęcie karty, montaż na Macu przez czytnik USB — partycja `bootfs`
   (FAT32) okazała się w pełni sprawna, wszystkie pliki rozruchowe
   (`bootcode.bin`, `start.elf`, `kernel.img`, `.dtb`) obecne i
   niezerowe.
3. `config.txt` i `cmdline.txt` sprawdzone ręcznie — poprawne,
   `PARTUUID` w `cmdline.txt` zgodny z prawdziwą sygnaturą dysku MBR
   (zweryfikowane przez odczyt bajtów offsetu 440 sektora MBR: `sudo dd
   if=/dev/rdiskN bs=512 count=1 | xxd -s 440 -l 4`).
4. Naprawa systemu plików ext4 z Maca przez Homebrew:
   ```bash
   brew install e2fsprogs
   diskutil unmountDisk /dev/diskN
   sudo /usr/local/opt/e2fsprogs/sbin/fsck.ext4 -f -y /dev/rdiskNs2
   ```
   Znaleziono i naprawiono osierocone i-węzły oraz uszkodzone ekstenty
   (głównie w plikach `linux-headers-.../include/config/`). Końcowy
   błąd `Invalid argument` przy zapisie informacji o systemie plików
   to najpewniej ograniczenie czytnika USB na macOS przy zapisie
   surowych metadanych — nieszkodliwe, drugi przebieg `fsck` pokazywał
   już tylko kosmetyczne niezgodności liczników.
5. Mimo naprawy struktury systemu plików, Pi **nadal się nie
   uruchamiało** i nie odpowiadało na ping — potwierdzenie, że problem
   był głębszy niż sama struktura ext4.
6. Zdecydowano się na **pełny reflash na nowej karcie** zamiast
   dalszego dochodzenia — zabezpieczono wcześniej to, co miało
   realną wartość czasową (skompilowana binarka `x64sc`, ROM-y).

**Powtórka na "nowej" karcie tego samego dnia:** po kilku godzinach
dalszych kompilacji (VICE ponownie, Caprice32) ta sama karta zaczęła
wykazywać identyczne objawy: uszkodzona baza `dpkg` (`/var/lib/dpkg/status`
— naprawiona z automatycznego backupu w `/var/backups/dpkg.status.0`),
uszkodzony plik `.pyc` (`apt-listchanges`), i **deterministyczny**
`internal compiler error: Segmentation fault` w GCC zawsze w tym samym
miejscu (`src/fdc.cpp` przy kompilacji Caprice32) — powtórzony
identycznie po reinstalacji GCC i zmianie flag optymalizacji na
`DEBUG=TRUE`.

**Rozstrzygający dowód:** `dmesg | grep -iE "error|ext4"` pokazał
świeże, generowane w czasie rzeczywistym błędy:
```
EXT4-fs error (device mmcblk0p2): ext4_lookup:1787: inode #16704: comm mandb: iget: checksum invalid
```
To jądro aktywnie zgłaszające uszkodzenie w locie, nie coś
historycznego z przeszłości — przy zdrowym RAM (`free -h` czysty) to
jednoznacznie wskazuje na **fizyczne uszkodzenie karty SD** (złe
sektory/degradacja flash), którego `fsck` nie jest w stanie trwale
naprawić (naprawia tylko strukturę metadanych, nie zawartość ani
fizyczny nośnik).

**Decyzja: wymiana karty, bez dalszego ratowania.** Nawet karty znanych
marek (SanDisk/Samsung) mogą być podróbkami albo mieć wadę fabryczną —
test weryfikujący prawdziwą pojemność/kondycję: `brew install f3`,
`f3write`/`f3read` na całej pojemności karty.

**Pełny obraz karty przed wymianą** (zabezpieczenie danych do
ewentualnego późniejszego odzyskania), skompresowany w locie na
udział sieciowy, z paskiem postępu:
```bash
brew install pv
sudo dd if=/dev/rdiskN bs=4m | pv -s <ROZMIAR_W_BAJTACH> | gzip > "/sciezka/backup_$(date +%Y%m%d).img.gz"
```
Odtworzenie: `gzip -dc backup.img.gz | sudo dd of=/dev/rdiskN bs=4m`

**Wniosek do `install_retro.sh`:** dodano wbudowany test
zapisu/odczytu 200MB + sprawdzenie `dmesg` na samym początku skryptu,
żeby złapać umierającą kartę od razu, zamiast po wielu godzinach
kompilowania.

## 17. Utrata łączności WiFi podczas długiej kompilacji

**Objaw:** po zakończeniu (lub w trakcie) długiej kompilacji (`make -j4`
na 512MB RAM) SSH przestawał odpowiadać (`Operation timed out`),
`ping` też nie dostawał odpowiedzi ("Host is down" / "Destination
Host Unreachable"), mimo że lokalnie na konsoli Pi (klawiatura+monitor
podłączone bezpośrednio) system działał normalnie, `sshd` był
`active (running)` bez przerwy, i `uptime` pokazywał ciągłą pracę
(zero restartów).

**Diagnoza:** to nie był crash systemu ani awaria SSH — to **karta
WiFi utraciła łączność radiową z routerem** pod wpływem wysokiego
obciążenia CPU podczas kompilacji (`load average` >2.0 na 4-rdzeniowym
Pi Zero 2W). Potwierdzone przez `arp -a` na Macu pokazujące wpis
"(incomplete)" dla IP Pi — czyli żadnej odpowiedzi na poziomie ARP,
mimo że interfejs `wlan0` na samym Pi pokazywał `state UP` i miał
przypisany prawidłowy adres IP.

**Rozwiązanie:** zwykły `sudo reboot` z lokalnej konsoli (klawiatura
podłączona bezpośrednio do Pi) przywracał łączność. Podczas długich
kompilacji, jeśli utrata SSH nie jest krytyczna, prościej jest po
prostu kontynuować pracę lokalnie na konsoli niż walczyć z
`wpa_supplicant`/`dhclient` (które na systemie z NetworkManagerem
mogą się wzajemnie blokować i wisieć bez odpowiedzi).

**Dostęp z Windows** (gdy trzeba się przełączyć z Maca): wbudowany
klient `ssh`/`scp` w PowerShell działa identycznie jak na macOS/Linux,
alternatywnie PuTTY + WinSCP graficznie.

## 18. Wklejanie wieloliniowych bloków przez PuTTY/inne terminale

**Objaw:** wklejenie wieloliniowego heredoc (`python3 - <<'EOF' ...`)
do sesji SSH przez PuTTY (lub podobny klient) urywa się w połowie,
zostawiając widoczną sekwencję `^[[200~` (kod "bracketed paste") jako
nierozpoznaną komendę, i/lub aplikuje tę samą zmianę wielokrotnie przy
kolejnych próbach (duplikaty linii w plikach wynikowych).

**Rozwiązanie:** unikać wieloliniowych heredoców w takich terminalach.
Zamiast tego zakodować całą zawartość pliku do **Base64** (przygotowane
z góry) i przesłać jako pojedynczą linię:
```bash
echo "<base64...>" | base64 -d > plik
```
Baza64 nie zawiera znaków specjalnych ani nowych linii w samym
przesyłanym tekście, więc jest odporna na problemy z wklejaniem,
niezależnie od klienta terminala.

## 19. Zawieszony `dpkg`, przetrwał `kill -9`

**Objaw:** instalacja `imagemagick` (zależność LinApple) utknęła
na pakiecie `netpbm` na ponad 9 minut bez żadnego postępu w
`/var/log/dpkg.log`, mimo że proces pokazywał stan `R (running)` i
aktywnie zużywał CPU. **`sudo kill -9 <PID>` nie zabił procesu** —
nadal widoczny w `ps aux` z rosnącym czasem CPU po komendzie kill.

**Diagnoza:** sprawdzono `dmesg | grep -iE "error|ext4"` — czysty,
co wykluczyło nawrót porannego uszkodzenia karty SD. `cat
/proc/<PID>/status | grep State` pokazywał `R`, nie `D`
(nieprzerywalny sen na I/O), ale rzeczywiste zachowanie sugerowało
bardzo szybkie przełączanie między stanami, którego `ps` nie łapał.

**Rozwiązanie:** zamiast dalej próbować zabić proces, wykonano
**czysty restart**:
```bash
sudo reboot
```
Po restarcie:
```bash
sudo dpkg --configure -a
```
Instalacja dokończyła się bezbłędnie za pierwszym razem po restarcie
— cała reszta pakietów `imagemagick` (fonty, ghostscript, itd.)
przeszła płynnie.

**Wniosek:** przy zawieszonym `dpkg`, który nie reaguje na `kill -9`,
sprawdź `dmesg` żeby wykluczyć uszkodzenie karty, potem po prostu
zrób czysty `sudo reboot` (bezpieczniejszy niż odcięcie zasilania) i
`sudo dpkg --configure -a` — to zwykle naprawia stan bez potrzeby
głębszej diagnostyki.

## 20. Overscan HDMI w pełnym trybie KMS

**Objaw:** lewa krawędź obrazu (menu, tekst) ucięta przez ekran —
na przenośnym monitorze bez własnej opcji "Just Scan"/wyłączenia
overscanu.

**Ważne:** standardowe parametry `overscan_left/right/top/bottom` w
`/boot/firmware/config.txt` **nie działają** w pełnym trybie KMS
(`dtoverlay=vc4-kms-v3d` + `disable_fw_kms_setup=1`) — te ustawienia
dotyczą tylko starszego, firmware'owego trybu inicjalizacji wideo.

**Rozwiązanie:** parametr `video=` dopisany do
`/boot/firmware/cmdline.txt` (musi zostać jedną linią — bez łamania
przez edytor):
```bash
sudo python3 -c "
path = '/boot/firmware/cmdline.txt'
with open(path) as f:
    content = f.read().strip()
video_param = 'video=HDMI-A-1:1920x1080M@60,margin_left=40,margin_right=0,margin_top=0,margin_bottom=0'
content = content + ' ' + video_param
with open(path, 'w') as f:
    f.write(content)
"
sudo reboot
```
Dostosuj wartość `margin_left` metodą prób i błędów (zacząć od 40,
zwiększać jeśli nadal ucina). Nazwa złącza to standardowo `HDMI-A-1`
na Pi Zero 2W (jedno wyjście HDMI) — można zweryfikować przez
`sudo modetest -M vc4 -c` jeśli pakiet `libdrm-tests` jest
zainstalowany.

## 21. Karta SD zbyt mała na pełne kolekcje TOSEC

**Objaw:** `7z x` na kolekcji Amiga (3.6GB skompresowane, 23.8GB po
rozpakowaniu) urwał się w połowie z `System ERROR: errno=28 : No
space left on device`, mimo świeżo wymienionej, "nowej" karty 29GB.

**Analiza:** suma wszystkich bibliotek gier (11 platform, TOSEC/DK-BIT)
znacznie przekracza pojemność standardowej karty 32GB — sama Amiga
(surowe obrazy `.adf`, słabo kompresowalne) to prawie tyle, co reszta
platform razem wzięta.

**Rozwiązanie zastosowane:** sprawdzono integralność częściowo
rozpakowanych plików (`find -size -880k` na `.adf`, tylko 31 z 15835
było uszkodzonych — 99.8% sprawnych), usunięto uszkodzone, zostawiono
**60% kolekcji Amigi** (15804 z 26373 gier) jako wystarczające,
zamiast ryzykować dalsze problemy z miejscem.

**Wniosek na przyszłość:** przy planowaniu pełnych kolekcji TOSEC dla
wielu platform naraz, **64GB+ karta** jest praktycznie konieczna.
Alternatywa: trzymać największe biblioteki (Amiga, Spectrum) na
Sambie i montować przez sieć zamiast lokalnie na karcie SD.
