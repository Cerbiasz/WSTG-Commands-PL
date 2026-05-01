# WSTG-CONF-03 — Test File Extensions Handling for Sensitive Information

## Cel

Wykrycie błędów obsługi rozszerzeń plików: backupy (`.bak`/`.old`/`~`), źródła (`.phps`/`.inc`), config (`.env`/`.yml`), DB dumps (`.sql`), logi, IDE artifacts (`.git/`, `.DS_Store`). Najczęstszy single-finding krytyczny w pentestingu — `.env` z hasłami DB to typowy initial access.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-03-file-extensions.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-03.jsonl
```

Szablon w 5 grupach: backup files (index.php.bak, wp-config.bak, database.sql, backup.zip), source disclosure (.phps/.inc), config files (.env warianty, database.yml, application.properties), IDE leftovers (.idea/, .vscode/, .DS_Store), log files (laravel.log, production.log).

### Dodatkowe oficjalne szablony Nuclei + ffuf

```bash
# Exposed files / configs
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/files/ \
       -t resources/nuclei-templates/http/exposures/configs/ \
       -t resources/nuclei-templates/http/exposures/backups/

# Pełna wordlista przez ffuf
ffuf -u https://target/FUZZ \
     -w resources/seclists/Discovery/Web-Content/raft-large-files.txt \
     -mc 200 -fs <baseline_size>
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Backup extensions (.bak/.old/~/.swp/.save) | ✓ | — |
| Source code (.phps/.inc/.source) | ✓ | — |
| Config files (.env/.yml/.json/.xml/.ini/.properties) | ✓ | — |
| IDE leftovers (.idea/.vscode/.DS_Store/Thumbs.db) | ✓ | — |
| Log files (.log/laravel.log/production.log) | ✓ | — |
| Pełna brute-force wordlista | — | ffuf z SecLists |
| Archive files (.zip/.tar.gz) z deep content | częściowe | manual investigation |
| Encoding bypass (`%2e`, `%00`) | — | manual / ffuf |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Sample test**: nasz Nuclei szablon (~30 typowych paths) jako quick win.
2. **Deep brute-force**: ffuf z `Discovery/Web-Content/raft-large-files.txt` (~50k entries).
3. **Per stack focus**: dla WordPress dodać wp-content/* paths; dla Laravel sprawdzić storage/logs/laravel.log; dla Rails — log/production.log.
4. **Encoding bypass**: jeśli WAF blokuje `.env`, próbować `%2e%65%6e%76`, `.env%00`, `.env/`, `.env?cb=1`.
5. **Content verification**: dla każdego found = pobrać + grep credentials/keys (cross-ref WSTG-INFO-05 hardcoded secrets).

### Co MUSI być sprawdzone (12 punktów)

- [ ] `.env`, `.env.bak`, `.env.local`, `.env.production`
- [ ] `wp-config.php.bak`, `wp-config.php~`, `wp-config.old`
- [ ] `web.config.bak`, `application.properties`, `application.yml`
- [ ] `composer.json`, `composer.lock`, `package.json`, `package-lock.json` (cross WSTG-INFO-09)
- [ ] `database.sql`, `dump.sql`, `backup.sql`
- [ ] `backup.zip`, `site.zip`, `<hostname>.zip`
- [ ] `index.php.bak`, `config.php.bak`
- [ ] `.git/HEAD`, `.git/config`, `.svn/entries`
- [ ] `.DS_Store`, `Thumbs.db`, `.idea/workspace.xml`
- [ ] Log files w typowych lokalizacjach
- [ ] phpinfo.php / info.php (cross WSTG-CONF-02)
- [ ] Server config: `httpd.conf`, `nginx.conf` (rzadkie ale możliwe)

### Per stack — typowe wycieki

| Stack | Charakterystyczny path |
|---|---|
| Laravel | `/.env`, `/storage/logs/laravel.log`, `/composer.lock` |
| WordPress | `/wp-config.php.bak`, `/wp-content/uploads/dump.sql`, `/readme.html` |
| Drupal | `/sites/default/files/dump.sql`, `/sites/default/private/` |
| Symfony | `/.env`, `/config/parameters.yml.bak` |
| Rails | `/config/database.yml`, `/log/production.log`, `/Gemfile.lock` |
| Spring Boot | `/application.properties`, `/application.yml`, `/META-INF/` |
| Django | `/settings.py`, `/local_settings.py`, `/db.sqlite3` |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Niebezpieczne rozszerzenia plików

| Rozszerzenie | Ryzyko |
|-------------|--------|
| `.bak`, `.old`, `.orig`, `.save` | Kopia zapasowa — może zawierać kod źródłowy |
| `.swp`, `.swo`, `.tmp` | Pliki tymczasowe edytora (vim swap) |
| `.config`, `.env`, `.ini`, `.yml` | Pliki konfiguracyjne z credentials |
| `.sql`, `.db`, `.sqlite` | Bazy danych z danymi |
| `.log` | Logi — mogą zawierać tokeny, hasła, dane użytkowników |
| `.git/`, `.svn/` | Repozytorium kodu źródłowego |
| `.DS_Store`, `Thumbs.db` | Metadane systemu plików — ujawniają strukturę katalogów |
| `.php~`, `.php.bak` | Backup PHP — serwer może zwrócić kod źródłowy zamiast wykonać |

### Obrona

- **Blokuj dostęp** do plików z niebezpiecznymi rozszerzeniami na serwerze webowym
- Apache: `<FilesMatch "\.(bak|old|swp|env|log|sql|git)$"> Require all denied </FilesMatch>`
- Nginx: `location ~* \.(bak|old|swp|env|log|sql)$ { deny all; }`
- Nie pozostawiaj plików backup/tymczasowych w katalogu webowym
- Skanuj regularnie: `find /var/www -name "*.bak" -o -name "*.old" -o -name "*.swp"`

## Pentesterskie deep dive

### Mniej znane techniki

- **`.git/` directory recovery**: nawet jeśli `.git/HEAD` zwraca 200, można rekonstruować pełen repo przez `git-dumper` (https://github.com/arthaud/git-dumper) — daje dostęp do całej historii kodu.
- **`.DS_Store` parsing**: `.DS_Store` (macOS metadata) zawiera nazwy plików w katalogu. `python ds_store_exp.py` wyciąga listę → discovery hidden paths.
- **PHP source disclosure via `.phps`**: Apache z mod_php konfigurowanym `AddType application/x-httpd-php-source .phps` serwuje highlighted source. Często leftover po debug.
- **Filename guessing per backup convention**: `<file>.<ext>.<date>` (np. `index.php.20230815`), `<file>.<ext>.bk1`, `<file>.<editor>.swp`, `~$<filename>.docx` (Office temp).
- **CDN cache replicating wrong content**: `.env` może być cached przez CDN nawet jeśli backend potem dodał regułę block. Cache-buster `?cb=1` jako bypass.

### Common pitfalls

- **WAF blocking common paths**: Cloudflare/AWS WAF mają reguły dla `.env`, `.git/`. Bypass: case (`/.ENV`), trailing chars (`/.env/`), encoding (`%2e%65%6e%76`).
- **SPA catch-all 200**: aplikacje SPA mogą zwracać index.html z kodem 200 dla każdego path → wymaga matcher na body content.
- **Compressed responses**: `.bak.gz` lub `.zip` mogą być serwowane z `Content-Encoding: gzip` — Nuclei radzi sobie ale ręczne pobranie wymaga `--compressed` w curl.
- **Symlink tricks**: w niektórych konfiguracjach `.env` to symlink do `/dev/null` — 200 z empty body, false negative.

### Świeżynki z research

- **Mass `.env` exposure** — community research (cyberresearch reports) — dziesiątki tysięcy publicly exposed Laravel `.env` ze stripe/aws keys.
- **`.git/` exploitation chain** — git-dumper → reconstruct → grep secrets → pivot. https://github.com/arthaud/git-dumper
- **`.DS_Store` enumeration** — https://github.com/lijiejie/ds_store_exp
- **PortSwigger File Upload + extension confusion**: https://portswigger.net/web-security/file-upload
- **HackTricks File Inclusion + sources**: https://book.hacktricks.xyz/pentesting-web/file-inclusion

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backup Finder | Wyszukiwanie plików kopii zapasowych | [GitHub](https://github.com/moeinfatehi/Backup-Finder) |
| Param Miner | Hidden parameter discovery + cache poisoning | [GitHub](https://github.com/PortSwigger/param-miner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/03-Test_File_Extensions_Handling_for_Sensitive_Information
- git-dumper: https://github.com/arthaud/git-dumper
- ds_store_exp: https://github.com/lijiejie/ds_store_exp
- SecLists Discovery: https://github.com/danielmiessler/SecLists/tree/master/Discovery/Web-Content

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.7 | Information Leakage (L3) | Web tier configured to only serve files with specific file extensions. |
| V13.4.1 | Information Leakage (L1) | No source control metadata (.git/.svn) deployed. |
