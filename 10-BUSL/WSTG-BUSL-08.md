# WSTG-BUSL-08 — Test Upload of Unexpected File Types

## Cel

Wykrycie czy aplikacja akceptuje unexpected file types (np. `.php` zamiast oczekiwanego `.jpg`). Bypass via double extension, MIME spoofing, magic bytes manipulation, polyglots, .htaccess upload.

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify upload endpoints**: profil photo, document upload, attachments.
2. **Allowed types**: jakie typy aplikacja oficjalnie akceptuje?
3. **Bypass tests**: double extension (`shell.php.jpg`), MIME spoof, magic bytes spoof.
4. **Server interpretation**: jeśli `.php.jpg` uploaded, sprawdź czy serwowane jako PHP.
5. **.htaccess / web.config upload**: czy aplikacja akceptuje config files?

### Co MUSI być sprawdzone (12 punktów)

- [ ] Double extension bypass (`shell.php.jpg`)
- [ ] Alternative extensions (`.phtml`, `.phar`, `.php5`)
- [ ] Case manipulation (`.PhP`)
- [ ] Null byte (`shell.php%00.jpg`)
- [ ] MIME type spoofing
- [ ] Magic bytes manipulation
- [ ] Polyglot files (valid JPEG + PHP)
- [ ] .htaccess upload (Apache config override)
- [ ] web.config upload (IIS)
- [ ] Trailing chars (`shell.php.`, `shell.php::$DATA`)
- [ ] Filename special chars (path traversal `../../shell.php`)
- [ ] ZIP slip (zip with `../../shell.php`)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — File_Upload_Cheat_Sheet.md

### Walidacja typu pliku — wielowarstwowa

- **Warstwa 1 — Rozszerzenie**: allowlist dozwolonych (`.jpg`, `.png`, `.pdf`) — NIE denylist
- **Warstwa 2 — MIME type**: sprawdź `Content-Type` header — ALE łatwo sfałszywowalny
- **Warstwa 3 — Magic bytes**: sprawdź pierwsze bajty pliku (sygnatura) — trudniejsze do obejścia
- **Warstwa 4 — Zawartość**: re-enkoduj obrazy (PIL, ImageMagick) — usuń wbudowane payloady
- Sprawdzaj **WSZYSTKIE warstwy** — każda z osobna może być obejścia

### Techniki bypass filtrów uploadu

| Technika | Przykład | Opis |
|----------|---------|------|
| Podwójne rozszerzenie | `shell.php.jpg` | Serwer może interpretować jako PHP |
| Alternatywne rozszerzenia | `.phtml`, `.phar`, `.php5` | Mogą być interpretowane jako PHP |
| Case manipulation | `.PhP`, `.pHP`, `.Php` | Case-insensitive serwer może je przetworzyć |
| Null byte | `shell.php%00.jpg` | Starszy PHP obcina po null byte |
| MIME spoof | `Content-Type: image/jpeg` na .php | Filtr sprawdza MIME, nie zawartość |
| Polyglot | Prawidłowy JPEG z PHP w komentarzu | Przechodzi walidację obrazu |
| .htaccess upload | `AddType application/x-httpd-php .jpg` | Pliki .jpg interpretowane jako PHP |
| Trailing chars | `shell.php.`, `shell.php::$DATA` | Windows ignoruje trailing dot/ADS |

### Magic bytes — sygnatury plików

| Format | Magic bytes (hex) |
|--------|------------------|
| JPEG | `FF D8 FF` |
| PNG | `89 50 4E 47 0D 0A 1A 0A` |
| GIF | `47 49 46 38` |
| PDF | `25 50 44 46` |
| ZIP | `50 4B 03 04` |
| EXE | `4D 5A` |

### Obrona — przechowywanie

- Przechowuj pliki **POZA webroot** — brak bezpośredniego dostępu przez URL
- Zmień nazwę pliku: random UUID — eliminuje path traversal
- Osobna domena/CDN dla user-content
- Brak execute permission na uploaded files
- Skanuj antywirusem przed udostępnieniem

## Pentesterskie deep dive

### Mniej znane techniki

- **PHP wrappers via upload + LFI**: upload `shell.txt` + LFI `?file=upload/shell.txt` → RCE.
- **ZIP slip**: zip archive z `../../etc/passwd` extract path traversal.
- **Image polyglot RCE**: GIF89a magic + PHP w komentarzu = passes image validation, executes as PHP.
- **SVG XSS**: SVG z `<script>` - profile pic upload XSS gdy renderowane.
- **EXIF metadata injection**: image metadata zawiera PHP code, server reads metadata via exiftool.

### Common pitfalls

- **Allowlist on filename ale serwer interprets via Content-Type**: `image.jpg` z `Content-Type: application/x-httpd-php`.
- **MIME validation only**: trivial to spoof with curl.

### Świeżynki z research

- **PortSwigger File Upload Lab**: https://portswigger.net/web-security/file-upload
- **HackTricks File Upload**: https://book.hacktricks.xyz/pentesting-web/file-upload

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Upload Scanner | Active file upload testing |
| ZIP slip detector | Archive traversal |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/08-Test_Upload_of_Unexpected_File_Types
- OWASP File Upload CS: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- HackTricks File Upload: https://book.hacktricks.xyz/pentesting-web/file-upload

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V12.1.1 | File upload size limits. |
| V12.2.1 | File MIME validation. |
| V12.3.4 | File extensions allowlist. |
