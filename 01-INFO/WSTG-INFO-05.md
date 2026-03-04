# WSTG-INFO-05 — Review Web Page Content for Information Leakage

## Cele

- Review comments, metadata, JS files, source maps for information leakage
- Find sensitive data in HTML comments, JavaScript code, meta tags
- Identify API keys, tokens, internal paths, developer comments

## KOMENDY

### Wyciaganie komentarzy HTML

```bash
curl -s https://TARGET | grep -oE "<!--.*?-->" | tee output_html_comments.txt
curl -s https://TARGET | grep -oP "<!--[\s\S]*?-->" | tee output_html_comments_multi.txt

```

### Wyciaganie tagow META

```bash
curl -s https://TARGET | grep -iE "<meta[^>]+>" | tee output_meta_tags.txt

```

### Wyciaganie linkow do plikow JS

```bash
curl -s https://TARGET | grep -oE 'src="[^"]*\.js[^"]*"' | tee output_js_files.txt
curl -s https://TARGET | grep -oE "src='[^']*\.js[^']*'" | tee output_js_files2.txt

```

### Hakrawler - crawler do zbierania URL-ow

```bash
echo https://TARGET | hakrawler -d 3 | tee output_hakrawler.txt
echo https://TARGET | hakrawler -d 3 -subs | tee output_hakrawler_subs.txt

```

### GAU (Get All URLs)

```bash
echo TARGET | gau --threads 5 | tee output_gau.txt
echo TARGET | gau --threads 5 | grep -iE "\.js(\?|$)" | tee output_gau_js.txt

```

### LinkFinder - wyszukiwanie endpointow w plikach JS

```bash
python3 linkfinder.py -i https://TARGET -d -o output_linkfinder.html
python3 linkfinder.py -i https://TARGET/js/app.js -o cli | tee output_linkfinder_app.txt

```

### Secretfinder - szukanie sekretow w JS

```bash
python3 secretfinder.py -i https://TARGET -e -o output_secretfinder.html

```

### Nuclei - skanowanie wycieku informacji

```bash
nuclei -u https://TARGET -t exposures/ -o output_nuclei_exposures.txt
nuclei -u https://TARGET -t technologies/ -o output_nuclei_tech.txt
nuclei -u https://TARGET -tags exposure,token,secret -o output_nuclei_secrets.txt

```

### Sprawdzanie source map

```bash
curl -s https://TARGET/js/app.js | grep -i "sourceMappingURL" | tee output_sourcemaps.txt
curl -s https://TARGET/js/app.js.map | tee output_sourcemap_content.txt

```

### Wyciaganie emaili

```bash
curl -s https://TARGET | grep -oE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" | sort -u | tee output_emails.txt

```

### Szukanie kluczy API i tokenow w zrodle

```bash
curl -s https://TARGET | grep -iE "(api[_-]?key|api[_-]?secret|access[_-]?token|auth[_-]?token|client[_-]?secret)" | tee output_api_keys.txt

```

### Szukanie wewnetrznych sciezek i IP

```bash
curl -s https://TARGET | grep -oE "(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3})" | sort -u | tee output_internal_ips.txt

```

## KOMENDY Z WORDLISTAMI

### Fuzzowanie plikow JS i zasobow

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -mc 200 -e .js,.json,.map -o output_ffuf_js.json

```

### Szukanie plikow konfiguracyjnych

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/config.txt -mc 200 -o output_ffuf_config.json

```

### Szukanie wyciekow plikow

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/all-files-leaked.txt -mc 200 -o output_ffuf_leaked.json

```

### Szukanie dotfiles

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/dotfiles.txt -mc 200 -o output_ffuf_dotfiles.json

```

### Fuzzowanie endpointow API

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api.txt -mc 200,301,302 -o output_ffuf_api.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz DevTools (F12) > zakladka Sources > przejrzyj wszystkie pliki JS
2. Szukaj komentarzy developerskich (TODO, FIXME, HACK, XXX, password, secret)
3. Sprawdz zakladke Network > szukaj zapytan do API i analizuj odpowiedzi
4. W zakladce Console sprawdz czy sa wypisywane informacje debugowe
5. Uzyj rozszerzenia Wappalyzer do identyfikacji technologii
6. Sprawdz kod zrodlowy strony (Ctrl+U) pod katem komentarzy i ukrytych pol
7. W Burp Suite: przejrzyj odpowiedzi pod katem wrazliwych naglowkow
8. Sprawdz czy pliki JS maja source mapy (.js.map) - moga ujawnic oryginalny kod
9. Szukaj hardcoded credentials w plikach JavaScript

