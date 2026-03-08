# WSTG-INFO-09 — Fingerprint Web Application

## Cele

- Identify the web application and version
- Determine exact version of deployed application to search for known CVEs
- Differentiate between custom and off-the-shelf applications

## KOMENDY

### WhatWeb - identyfikacja aplikacji i wersji

```bash
whatweb https://TARGET -v -a 3 | tee output_whatweb.txt
whatweb https://TARGET --log-json=output_whatweb.json

```

### Nmap - skrypty identyfikacji aplikacji

```bash
nmap --script http-generator -p 80,443 TARGET -oN output_nmap_generator.txt
nmap --script http-enum -p 80,443 TARGET -oN output_nmap_enum.txt
nmap --script http-wordpress-enum -p 80,443 TARGET -oN output_nmap_wp.txt
nmap --script http-drupal-enum -p 80,443 TARGET -oN output_nmap_drupal.txt

```

### cURL - sprawdzenie META generator

```bash
curl -s https://TARGET | grep -iE "meta.*generator" | tee output_generator_tag.txt
curl -s https://TARGET | grep -iE "meta.*version" | tee output_version_tag.txt

```

### Nuclei - szablony identyfikacji

```bash
nuclei -u https://TARGET -tags tech,detect -o output_nuclei_detect.txt
nuclei -u https://TARGET -t technologies/ -o output_nuclei_tech.txt

```

### Sprawdzenie pliku CHANGELOG / README

```bash
curl -s https://TARGET/CHANGELOG.txt | head -30 | tee output_changelog.txt
curl -s https://TARGET/README.txt | head -30 | tee output_readme.txt
curl -s https://TARGET/readme.html | head -30 | tee output_readme_html.txt
curl -s https://TARGET/RELEASE_NOTES.txt | head -30 | tee output_release_notes.txt
curl -s https://TARGET/VERSION | tee output_version.txt
curl -s https://TARGET/version.txt | tee output_version2.txt

```

### WordPress specifics

```bash
curl -s https://TARGET/wp-links-opml.php | grep -i "generator" | tee output_wp_version.txt
curl -s https://TARGET/feed/ | grep -i "generator" | tee output_wp_feed_version.txt

```

### Sprawdzenie plikow statycznych i ich wersji

```bash
curl -s https://TARGET | grep -oE "(jquery|bootstrap|angular|react|vue)[.-]([0-9]+\.)+[0-9]+" | sort -u | tee output_lib_versions.txt

```

### Porownanie hash plikow statycznych

```bash
curl -s https://TARGET/wp-includes/css/dashicons.min.css | md5sum
curl -s https://TARGET/misc/drupal.js | md5sum

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - narzedzia maja wbudowane bazy sygnatur
# Identyfikacja odbywa sie na podstawie sygnatur, hashów i wzorcow w odpowiedziach

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz kod zrodlowy strony - tag <meta name="generator">
2. Sprawdz RSS/Atom feed - czesto zawiera informacje o generatorze
3. Uzyj Wappalyzer/BuiltWith w przegladarce
4. Porownaj pliki statyczne (CSS, JS) z wersjami referencyjnymi znanych aplikacji
5. Sprawdz komentarze HTML - czesto zawieraja wersje
6. Przeanalizuj sciezki URL specyficzne dla danej aplikacji
7. Sprawdz strony bledow - mogą ujawnic framework i wersje
8. W DevTools > Network - sprawdz wersje zaladowanych bibliotek JS


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CMS Scanner | Wykrywanie podatnosci w popularnych systemach CMS | [BApp Store](https://portswigger.net/bappstore/1bf95d0be40c447b94981f5696b1a18e) |
| Detect Dynamic JS | Porownywanie plikow JS w celu wykrycia dynamicznej zawartosci | [BApp Store](https://portswigger.net/bappstore/4a657674ebe3410b92280613aa512304) |
