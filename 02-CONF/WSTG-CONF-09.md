# WSTG-CONF-09 — Test File Permission

## Cele

- Review file permissions on the web server
- Identify sensitive files accessible without proper authorization
- Find files that should not be publicly readable

## KOMENDY

### Nmap - skanowanie konfiguracji backupow

```bash
nmap --script http-config-backup -p 80,443 TARGET -oN output_nmap_config_backup.txt

```

### Nikto - skanowanie pod katem dostepnych plikow

```bash
nikto -h https://TARGET -o output_nikto.txt -Format txt
nikto -h https://TARGET -Tuning 4 -o output_nikto_info.txt

```

### Sprawdzenie typowych wrazliwych sciezek

```bash
curl -sI https://TARGET/.env | head -1
curl -sI https://TARGET/.git/config | head -1
curl -sI https://TARGET/.git/HEAD | head -1
curl -sI https://TARGET/.gitignore | head -1
curl -sI https://TARGET/.htaccess | head -1
curl -sI https://TARGET/.htpasswd | head -1
curl -sI https://TARGET/web.config | head -1
curl -sI https://TARGET/wp-config.php | head -1
curl -sI https://TARGET/config.php | head -1
curl -sI https://TARGET/database.yml | head -1
curl -sI https://TARGET/settings.py | head -1
curl -sI https://TARGET/application.properties | head -1
curl -sI https://TARGET/appsettings.json | head -1

```

### Sprawdzenie directory listing

```bash
curl -sI https://TARGET/images/ | head -5
curl -sI https://TARGET/uploads/ | head -5
curl -sI https://TARGET/css/ | head -5
curl -sI https://TARGET/js/ | head -5
curl -sI https://TARGET/includes/ | head -5
curl -sI https://TARGET/vendor/ | head -5
curl -sI https://TARGET/backup/ | head -5
curl -sI https://TARGET/logs/ | head -5

```

### Sprawdzenie logów

```bash
curl -sI https://TARGET/error.log | head -1
curl -sI https://TARGET/access.log | head -1
curl -sI https://TARGET/debug.log | head -1
curl -sI https://TARGET/logs/error.log | head -1
curl -sI https://TARGET/wp-content/debug.log | head -1

```

### Sprawdzenie SSH/kluczy

```bash
curl -sI https://TARGET/.ssh/id_rsa | head -1
curl -sI https://TARGET/.ssh/authorized_keys | head -1

```

## KOMENDY Z WORDLISTAMI

### SecLists quickhits - szybka lista popularnych plikow

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/quickhits.txt -mc 200 -o output_ffuf_quickhits.json

```

### Bug-Bounty-Wordlists config

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/config.txt -mc 200 -o output_ffuf_config.json

```

### Bug-Bounty-Wordlists dotfiles

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/dotfiles.txt -mc 200 -o output_ffuf_dotfiles.json

```

### Bug-Bounty-Wordlists env

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/env.txt -mc 200 -o output_ffuf_env.json

```

### Bug-Bounty-Wordlists leaked files

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/all-files-leaked.txt -mc 200 -o output_ffuf_leaked.json

```

### Bug-Bounty-Wordlists keys

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/keys.txt -mc 200 -o output_ffuf_keys.json

```

### fuzzdb Unix dotfiles

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/UnixDotfiles.txt -mc 200 -o output_ffuf_unix_dotfiles.json

```

### fuzzdb password locations

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/password-file-locations/Passwords.txt -mc 200 -o output_ffuf_passwords.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz czy pliki konfiguracyjne sa dostepne (.env, .git/config, wp-config.php)
2. Przetestuj directory listing na roznych katalogach
3. Sprawdz czy logi sa dostepne publicznie (error.log, access.log, debug.log)
4. Zweryfikuj uprawnienia do plikow uploadowanych przez uzytkownikow
5. Sprawdz czy pliki tymczasowe sa dostepne (.swp, .bak, ~)
6. W Burp Suite: przejrzyj Site Map pod katem wrazliwych plikow
7. Sprawdz czy private keys, certyfikaty, credentials nie sa dostepne publicznie
8. Przetestuj sciezki wzgledne (../) do uzyskania dostepu do plikow poza webroot


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Docker_Security_Cheat_Sheet.md

### Uprawnienia plikow — zasady

| Zasada | Opis |
|--------|------|
| Least Privilege | Pliki webowe: odczyt tylko dla procesu serwera, nie `777` |
| Separation of Duties | Uzytkownik serwera web ≠ wlasciciel plikow |
| No Execute on Uploads | Katalog uploadow: brak prawa execute, brak interpretacji skryptow |
| Config Files Protected | `.env`, `config.php`: `640` lub `600`, dostep tylko dla procesu serwera |
| Log Files | Logi: append-only, niedostepne przez HTTP |

### Typowe uprawnienia Linux — web server

| Zasob | Uprawnienia | Wlasciciel |
|-------|-------------|------------|
| Pliki PHP/Python/Ruby | `644` (rw-r--r--) | root:www-data |
| Katalogi aplikacji | `755` (rwxr-xr-x) | root:www-data |
| Pliki konfiguracyjne | `640` (rw-r-----) | root:www-data |
| Katalog uploadow | `750` (rwxr-x---) | www-data:www-data |
| Klucze prywatne/SSL | `600` (rw-------) | root:root |
| Logi aplikacji | `640` (rw-r-----) | www-data:adm |

### Pliki wrazliwe — co chronic

- **`.env`** — credentials, klucze API, connection strings
- **`.git/`** — pelne repozytorium kodu (git checkout pozwala odtworzyc pliki)
- **`wp-config.php`**, **`config.php`** — dane do bazy danych
- **`.htpasswd`** — hashe hasel
- **`id_rsa`**, **`*.pem`**, **`*.key`** — klucze prywatne
- **`*.sql`**, **`*.db`** — dumpy baz danych
- **`debug.log`**, **`error.log`** — moga zawierac tokeny, stack traces

### Konfiguracja serwera — blokowanie dostepu

**Apache:**
```
<FilesMatch "^\.">
    Require all denied
</FilesMatch>
<DirectoryMatch "/\.git">
    Require all denied
</DirectoryMatch>
```

**Nginx:**
```
location ~ /\. { deny all; }
location ~ /\.git { deny all; }
```

### Directory listing — wylaczenie

| Serwer | Konfiguracja |
|--------|-------------|
| Apache | `Options -Indexes` |
| Nginx | `autoindex off;` (domyslnie wylaczony) |
| IIS | Usun "Directory Browsing" z Feature Delegation |

### Obrona

- Regularnie skanuj webroot: `find /var/www -perm -o+w -type f` (pliki world-writable)
- Ustaw `umask 027` dla procesu serwera web
- Nie przechowuj kluczy, hasel, certyfikatow w katalogu webowym
- Uzyj `.gitignore` aby nie commitowac `.env`, `*.key`, `*.pem`
- Monitoruj zmiany plikow konfiguracyjnych (AIDE, Tripwire, OSSEC)

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp — test wymaga dostepu do systemu plikow serwera.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.1 | File Storage | Verify that files uploaded or generated by untrusted input and stored in a public folder, are not executed as server-side program code when accessed directly with an HTTP request. |
| V5.3.2 | File Storage | Verify that when the application creates file paths for file operations, instead of user-submitted filenames, it uses internally generated or trusted data, or if user-submitted filenames or file metadata must be used, strict validation and sanitization must be applied. This is to protect against path traversal, local or remote file inclusion (LFI, RFI), and server-side request forgery (SSRF) attacks. |
