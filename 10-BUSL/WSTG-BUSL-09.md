# WSTG-BUSL-09 — Test Upload of Malicious Files

## Cel

Wykrycie czy aplikacja akceptuje malicious files: web shells (PHP/JSP/ASP), polyglot files (legitimate format z embedded code), malware, EICAR test, SVG z XSS, file z malicious metadata (EXIF injection).

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Web shell upload**: upload `shell.php`, `shell.jsp`, `shell.aspx` - czy serwer interpretuje?
2. **Polyglot test**: upload polyglot (np. JPEG + PHP) - czy passes validation?
3. **EICAR test**: standard antivirus test file - czy AV scan?
4. **SVG XSS**: SVG z `<script>` - upload as profile pic - czy XSS w viewer?
5. **EXIF injection**: image z PHP code w EXIF - czy server processes EXIF (exiftool reads it)?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Web shell upload (PHP/JSP/ASP/CFM)
- [ ] Polyglot files
- [ ] EICAR test (antivirus scan present?)
- [ ] SVG with `<script>` XSS
- [ ] EXIF metadata injection
- [ ] ZIP slip (archive traversal)
- [ ] File outside webroot storage
- [ ] No execute permission on uploaded files
- [ ] Re-encoding images (strips embedded code)
- [ ] Random filenames (no name collision)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — File_Upload_Cheat_Sheet.md

### Walidacja przesyłanych plików — wielowarstwowa

- **Rozszerzenie pliku**: allowlist dozwolonych rozszerzeń (`.jpg`, `.png`, `.pdf`) — NIE denylist
- **MIME type**: sprawdź `Content-Type` header — ALE może być sfałszywowany
- **Magic bytes**: sprawdź pierwsze bajty pliku (np. `\xFF\xD8\xFF` = JPEG) — trudniejsze do obejścia
- **Zawartość**: re-enkoduj obrazy (ImageMagick, PIL) — usuń wbudowane payloady
- **Metadane**: usuń EXIF, komentarze, metadane — mogą zawierać code injection

### Przechowywanie plików — bezpieczne

- Przechowuj pliki **POZA webroot** — brak bezpośredniego dostępu przez URL
- **Zmień nazwę pliku**: losowa nazwa (UUID) — zapobiegaj path traversal i name collision
- **Osobna domena/CDN**: serwuj pliki z innej domeny — izoluj od głównej aplikacji (XSS protection)
- **Ogranicz uprawnienia**: pliki nie powinny mieć execute permission
- **Skanuj antywirusem**: sprawdź pliki przed zapisaniem

### Typowe ataki przez upload

- **Web shell**: PHP/JSP/ASP shell upload → RCE na serwerze
- **Podwójne rozszerzenie**: `shell.php.jpg` — serwer może interpretować jako PHP
- **Null byte**: `shell.php%00.jpg` — starsza PHP obcina po null byte
- **Polyglot**: prawidłowy JPEG/PDF z embedded PHP/JS payload
- **SVG XSS**: SVG z `<script>` — XSS gdy serwowane z `Content-Type: image/svg+xml`
- **ZIP slip**: zip extracted z path traversal (`../../etc/passwd`)
- **EXIF code injection**: PHP code w EXIF metadata pliku → RCE jeśli serwer reads EXIF

### Defense in depth

- **Allowlist file types**: only specific extensions allowed
- **Re-encode images**: PIL/ImageMagick re-encode → strips embedded code
- **Strip metadata**: exiftool -all=
- **Antivirus scan**: ClamAV, VirusTotal API
- **CSP**: prevent XSS jeśli SVG renders w main domain
- **Separate domain**: user-content na innym domain (np. `user-content.target.com`)

## Pentesterskie deep dive

### Mniej znane techniki

- **`.htaccess` upload**: jeśli aplikacja akceptuje, atakujący config Apache to interpret `.jpg` as PHP.
- **Image polyglot via JPEG comment**: `\xFF\xD8\xFF\xE0` + `<?php system($_GET['c']); ?>` w COM marker.
- **SVG with foreign object**: `<svg><foreignObject><iframe src="javascript:..."></iframe></foreignObject></svg>` - bypass niektórych SVG sanitizers.
- **PDF JS execution**: PDF z embedded JS, niektóre viewers wykonają.
- **ZIP slip with symlinks**: archive z symlink to `/etc/passwd` - extracted as readable.

### Common pitfalls

- **Allowlist filename ale brak deep content scan**: `image.jpg` z PHP body.
- **Antivirus run async**: file dostępne przed scan completion.

### Świeżynki z research

- **PortSwigger File Upload Lab**: https://portswigger.net/web-security/file-upload
- **HackTricks File Upload**: https://book.hacktricks.xyz/pentesting-web/file-upload
- **Polyglot file repository**: https://github.com/Polydet/polyglot-database

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Upload Scanner | Web shell upload testing |
| Hackvertor | Encoding manipulation |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/09-Test_Upload_of_Malicious_Files
- OWASP File Upload CS: https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html
- HackTricks File Upload: https://book.hacktricks.xyz/pentesting-web/file-upload

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V12.4.1 | Uploaded files not stored in webroot. |
| V12.4.2 | Antivirus scan on upload. |
| V12.5.1 | File extensions allowlist. |
