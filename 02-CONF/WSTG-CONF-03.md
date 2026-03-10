# WSTG-CONF-03 — Test File Extensions Handling for Sensitive Information

## Cele

- Enumerate sensitive file extensions that may reveal source code or config
- Identify server behavior for different file extensions
- Find files with backup/temporary extensions (.bak, .old, .swp, etc.)

## KOMENDY

### ffuf - fuzzowanie rozszerzen plikow

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/web-extensions.txt -mc 200,301,302 -o output_ffuf_extensions.json

```

### gobuster z rozszerzeniami

```bash
gobuster dir -u https://TARGET -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -x php,asp,aspx,jsp,html,js,txt,xml,bak,old,conf,config,sql,log,zip,tar,gz -o output_gobuster_ext.txt

```

### dirsearch z rozszerzeniami

```bash
dirsearch -u https://TARGET -e php,asp,aspx,jsp,html,txt,xml,bak,old,conf,sql,log,zip -o output_dirsearch.txt

```

### Testowanie interpretacji rozszerzen

```bash
curl -sI https://TARGET/index.php | head -5
curl -sI https://TARGET/index.php.bak | head -5
curl -sI https://TARGET/index.php.old | head -5
curl -sI https://TARGET/index.php~ | head -5
curl -sI https://TARGET/index.php.swp | head -5
curl -sI https://TARGET/index.php.save | head -5
curl -sI https://TARGET/index.php.orig | head -5
curl -sI https://TARGET/index.php.dist | head -5
curl -sI https://TARGET/.index.php.swp | head -5

```

### Testowanie podwojnych rozszerzen

```bash
curl -sI https://TARGET/test.php.jpg | head -5
curl -sI https://TARGET/test.asp;.jpg | head -5
curl -sI https://TARGET/test.php%00.jpg | head -5

```

### Wfuzz - testowanie rozszerzen

```bash
wfuzz -c -z file,Desktop/WSTG/SecLists-master/Discovery/Web-Content/web-extensions.txt --hc 404 https://TARGET/index.FUZZ

```

### Sprawdzenie source code disclosure

```bash
curl -s https://TARGET/index.phps | head -30
curl -s "https://TARGET/index.php::$DATA" | head -30
curl -s https://TARGET/index.inc | head -30

```

## KOMENDY Z WORDLISTAMI

### SecLists web extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/web-extensions.txt -mc 200 -o output_ffuf_webext.json

```

### SecLists web extensions big

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/web-extensions-big.txt -mc 200 -o output_ffuf_webext_big.json

```

### Raft extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/raft-large-extensions.txt -mc 200 -o output_ffuf_raft_ext.json

ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/raft-medium-extensions.txt -mc 200 -o output_ffuf_raft_ext_med.json

ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/raft-small-extensions.txt -mc 200 -o output_ffuf_raft_ext_small.json

```

### fuzzdb common extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/filename-dirname-bruteforce/Extensions.Common.txt -mc 200 -o output_ffuf_fuzzdb_ext_common.json

```

### fuzzdb backup extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/filename-dirname-bruteforce/Extensions.Backup.txt -mc 200 -o output_ffuf_fuzzdb_ext_backup.json

```

### fuzzdb most common extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/filename-dirname-bruteforce/Extensions.Mostcommon.txt -mc 200 -o output_ffuf_fuzzdb_ext_mostcommon.json

```

### fuzzdb compressed extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/filename-dirname-bruteforce/Extensions.Compressed.txt -mc 200 -o output_ffuf_fuzzdb_ext_compressed.json

```

### Bug-Bounty-Wordlists extensions

```bash
ffuf -u https://TARGET/index.FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/extensions.txt -mc 200 -o output_ffuf_bbw_ext.json

```

### Content discovery z rozszerzeniami

```bash
gobuster dir -u https://TARGET -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -x bak,old,swp,save,orig,dist,tmp,conf,config,sql,zip,tar.gz,7z -o output_gobuster_backup_ext.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zmien rozszerzenie znanych plikow na .bak, .old, .swp, .orig i sprawdz odpowiedz
2. W Burp Intruder: ustaw payload na rozszerzenia i testuj na znanych sciezkach
3. Sprawdz czy serwer interpretuje pliki z podwojnym rozszerzeniem (file.php.jpg)
4. Testuj null byte injection w rozszerzeniach (file.php%00.jpg)
5. Sprawdz czy pliki .inc, .phps, .bkp sa serwowane jako tekst
6. Przetestuj case sensitivity rozszerzen (.PHP, .Php, .pHP)
7. Sprawdz czy serwer IIS obsluguje ::$DATA trick
8. Szukaj edytor backup files (.swp, .swo, ~, .save)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Niebezpieczne rozszerzenia plikow

| Rozszerzenie | Ryzyko |
|-------------|--------|
| `.bak`, `.old`, `.orig`, `.save` | Kopia zapasowa — moze zawierac kod zrodlowy |
| `.swp`, `.swo`, `.tmp` | Pliki tymczasowe edytora (vim swap) |
| `.config`, `.env`, `.ini`, `.yml` | Pliki konfiguracyjne z credentials |
| `.sql`, `.db`, `.sqlite` | Bazy danych z danymi |
| `.log` | Logi — moga zawierac tokeny, hasla, dane uzytkownikow |
| `.git/`, `.svn/` | Repozytorium kodu zrodlowego |
| `.DS_Store`, `Thumbs.db` | Metadane systemu plikow — ujawniaja strukture katalogow |
| `.php~`, `.php.bak` | Backup PHP — serwer moze zwrocic kod zrodlowy zamiast wykonac |

### Obrona

- **Blokuj dostep** do plikow z niebezpiecznymi rozszerzeniami na serwerze webowym
- Apache: `<FilesMatch "\.(bak|old|swp|env|log|sql|git)$"> Require all denied </FilesMatch>`
- Nginx: `location ~* \.(bak|old|swp|env|log|sql)$ { deny all; }`
- Nie pozostawiaj plikow backup/tymczasowych w katalogu webowym
- Skanuj regularnie: `find /var/www -name "*.bak" -o -name "*.old" -o -name "*.swp"`

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Upload Scanner | Testy bezpieczenstwa uploadu plikow HTTP | [GitHub](https://github.com/modzero/mod0BurpUploadScanner) |
| Backup Finder | Wyszukiwanie plikow kopii zapasowych na serwerze | [GitHub](https://github.com/moeinfatehi/Backup-Finder) |
