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

