# WSTG-CONF-04 — Review Old Backup and Unreferenced Files

## Cel

Identyfikacja plików backup, niereferencjonowanych zasobów (orphaned files), starych wersji aplikacji w katalogu webowym. Klasyczny pivot — dev zostawia `index.php.bak` po refactor, atakujący czyta surowy kod.

## Automatyzacja Nuclei

Test pokrywa się z **WSTG-CONF-03** (file extensions) i **WSTG-INFO-04** (attack surface). Używamy tych samych szablonów:

```bash
# WSTG-CONF-03 dla typowych backup paths
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-03-file-extensions.yaml

# WSTG-INFO-04 dla unreferenced admin / config / source paths
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-04-attack-surface.yaml

# Oficjalne backup discovery
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/backups/

# Brute-force comprehensive
ffuf -u https://target/FUZZ \
     -w resources/seclists/Discovery/Web-Content/raft-large-files.txt \
     -mc 200,206 -fs <baseline_size>
```

## Coverage Matrix

| Wymiar | Pokryte przez | Notka |
|---|---|---|
| Backup pliki (.bak/.old/~) | WSTG-CONF-03 | nasz szablon |
| Niereferencjonowane admin paths | WSTG-INFO-04 | nasz szablon |
| Niereferencjonowane source files | WSTG-CONF-03 | wzorce z source disclosure |
| Stare wersje aplikacji w `/old/` | manual + ffuf | brute-force discovery |
| Orphaned uploads w `/uploads/` | manual | wymaga directory listing lub guess |
| `Copy of`, Windows artifacts | manual | rzadkie, ale możliwe |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Sample test**: WSTG-CONF-03 + WSTG-INFO-04 templates dla typowych wzorców.
2. **Catalog brute-force**: ffuf z wordlistą `/old/`, `/backup/`, `/archive/`, `/temp/`, `/dev/`, `/staging/`.
3. **Pattern fuzzing**: dla każdej znanej nazwy pliku (z robots/sitemap/crawl) test warianty `<filename>.bak`, `<filename>~`, `<filename>.old`, `Copy of <filename>`.
4. **Wayback diff**: porównanie aktualnego sitemap z historical Wayback URLs — różnice ujawniają usunięte pliki które nadal mogą być serwowane.
5. **Date-stamped backups**: `db.sql.20240101`, `backup_2024-08.zip` — wzorce używane przez admins.

### Co MUSI być sprawdzone (8 punktów)

- [ ] WSTG-CONF-03 paths (backup extensions)
- [ ] `/old/`, `/backup/`, `/archive/`, `/dev/`, `/staging/` — directory existence
- [ ] Date-stamped variants per known filename
- [ ] Wayback Machine: `gau target.com | grep -E "\.(bak|old|sql|zip)$"`
- [ ] Common log paths (`/log/`, `/logs/`, `/error.log`)
- [ ] Sample/example files (`/example/`, `/test/`, `/sample/`)
- [ ] Documentation paths (`/docs/`, `/README.md`, `/CHANGELOG.md`)
- [ ] `Copy of <filename>` Windows convention

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Pliki backup i artefakty — co szukać

| Wzorzec nazwy | Przykład | Opis |
|--------------|---------|------|
| `file.ext.bak` | `config.php.bak` | Kopia zapasowa z kodem źródłowym |
| `file.ext~` | `index.php~` | Backup edytora (vim, emacs) |
| `file.ext.old` | `web.config.old` | Stara wersja |
| `#file.ext#` | `#config.py#` | Emacs auto-save |
| `.file.ext.swp` | `.config.php.swp` | Vim swap file |
| `file.ext.YYYYMMDD` | `db.sql.20240101` | Backup z datą |
| `file.ext.orig` | `settings.py.orig` | Oryginał przed zmianą |
| `Copy of file.ext` | `Copy of web.config` | Windows copy |
| `file.ext.dist` | `config.yml.dist` | Dystrybucyjny szablon |

### Niereferencjonowane zasoby

- `/backup/`, `/old/`, `/archive/`, `/tmp/` — katalogi z backupami
- `/.git/`, `/.svn/`, `/.hg/` — systemy kontroli wersji
- `/phpinfo.php`, `/info.php`, `/test.php` — pliki diagnostyczne
- `/README.md`, `/CHANGELOG.md`, `/TODO` — dokumentacja developerska
- `/.env`, `/wp-config.php.bak` — konfiguracja z credentials

### Obrona

- Nigdy nie tworzyć backupów w katalogach webowych
- Dodaj do `.gitignore` pliki tymczasowe i backup
- Regularnie skanuj katalogi webowe pod kątem niepotrzebnych plików
- Blokuj dostęp do katalogów VCS (`.git`, `.svn`) na serwerze

## Pentesterskie deep dive

### Mniej znane techniki

- **Wayback Machine "phantom files"**: pliki usunięte z aktualnej aplikacji ale wciąż serwowane przez backend (route bez delete). `gau target.com | grep -v "<current_paths>"` pokazuje phantom URLs.
- **Backup w nietypowych lokalizacjach**: `/var/log/`, `/etc/backup/` — teoretycznie poza webroot, ale błędne aliasy `/log/` lub volume mount mogą je ujawnić.
- **`.dist` / `.example` configs**: `composer.json.dist`, `config/parameters.yml.dist` — szkielety konfiguracji często ujawniają nazwy ENV vars i strukturę.
- **Compressed sitemap**: `sitemap.xml.gz` zawierający ścieżki do orphaned files — Skanery Burp domyślnie nie dekompresują.
- **HTTP/1.0 vs HTTP/1.1 difference**: niektóre serwery dla HTTP/1.0 pokazują listę katalogów nawet gdy HTTP/1.1 jest zhardenowany.

### Common pitfalls

- **WAF rule blocking `/old`, `/backup`**: bypass przez encoding (`/o%6Cd`) lub case (`/Old`).
- **Catch-all 200**: SPA może serwować index.html dla każdego path → matchery wymagają body content patterns.
- **Skanner ignorujący 206 Partial Content**: niektóre serwery zwracają 206 dla zip files — Nuclei domyślnie nie traktuje jako finding.

### Świeżynki z research

- **Massive `.git/` exposure surveys** — community reports; tysiące orgs ze zniepublicznych repo deploys.
- **Wayback CDX API** — programatyczny pull historical URLs: `https://web.archive.org/cdx/search/cdx?url=target.com/*&output=json`
- **PortSwigger Academy — Information disclosure labs**: https://portswigger.net/web-security/information-disclosure

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backup Finder | Wyszukiwanie plików backup | [GitHub](https://github.com/moeinfatehi/Backup-Finder) |
| Wayback Burp | Pull historical URLs | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/04-Review_Old_Backup_and_Unreferenced_Files_for_Sensitive_Information
- Wayback Machine CDX API: https://archive.org/help/wayback_api.php
- gau (GetAllUrls): https://github.com/lc/gau
- waybackurls: https://github.com/tomnomnom/waybackurls

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.1.5 | Configuration (L2) | Build pipeline removes development artifacts before deployment. |
| V13.4.7 | Information Leakage (L3) | Web tier serves only specific file extensions. |
