# WSTG-INFO-03 — Review Webserver Metafiles for Information Leakage

## Cele

- Identify hidden paths via metadata files (robots.txt, sitemap.xml, .well-known, security.txt)
- Extract information about disallowed or hidden directories and endpoints
- Find sensitive paths that administrators tried to hide from crawlers

## KOMENDY

### robots.txt

```bash
curl -s https://TARGET/robots.txt | tee output_robots.txt
curl -s http://TARGET/robots.txt | tee output_robots_http.txt

```

### sitemap.xml

```bash
curl -s https://TARGET/sitemap.xml | tee output_sitemap.xml
curl -s https://TARGET/sitemap_index.xml | tee output_sitemap_index.xml
curl -s https://TARGET/sitemaps.xml | tee output_sitemaps.xml

```

### security.txt (.well-known)

```bash
curl -s https://TARGET/.well-known/security.txt | tee output_security.txt
curl -s https://TARGET/security.txt | tee output_security2.txt

```

### Inne pliki .well-known

```bash
curl -s https://TARGET/.well-known/openid-configuration | tee output_openid.txt
curl -s https://TARGET/.well-known/assetlinks.json | tee output_assetlinks.json
curl -s https://TARGET/.well-known/apple-app-site-association | tee output_apple_asa.json
curl -s https://TARGET/.well-known/change-password
curl -s https://TARGET/.well-known/dnt-policy.txt

```

### humans.txt

```bash
curl -s https://TARGET/humans.txt | tee output_humans.txt

```

### Parsero - parser robots.txt

```bash
parsero -u https://TARGET -o -sb | tee output_parsero.txt

```

### Sprawdzenie META tagów w kodzie strony

```bash
curl -s https://TARGET | grep -iE "<meta" | tee output_meta_tags.txt
curl -s https://TARGET | grep -iE "robots|noindex|nofollow" | tee output_robots_meta.txt

```

### Wyciaganie linkow z sitemap

```bash
curl -s https://TARGET/sitemap.xml | grep -oP "(?<=<loc>).*?(?=</loc>)" | tee output_sitemap_urls.txt

```

### Sprawdzenie Disallow z robots.txt i testowanie sciezek

```bash
curl -s https://TARGET/robots.txt | grep -i "Disallow:" | awk '{print $2}' | while read path; do echo "Sprawdzam: https://TARGET$path"; curl -sI "https://TARGET$path" | head -1; done | tee output_robots_check.txt

```

## KOMENDY Z WORDLISTAMI

### Brute-force popularnych plikow metadanych

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -mc 200 -o output_ffuf_common.json

```

### Wordlista do fuzzowania plikow konfiguracyjnych serwera

```bash
gobuster dir -u https://TARGET -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -o output_gobuster_common.txt

```

### Predictable filepaths z fuzzdb

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/KitchensinkDirectories.txt -mc 200,301,302,403 -o output_ffuf_predictable.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz przegladarke i wejdz na https://TARGET/robots.txt - przeanalizuj Disallow/Allow
2. Sprawdz https://TARGET/sitemap.xml - wylistuj wszystkie URL-e
3. Sprawdz https://TARGET/.well-known/security.txt
4. W Burp Suite: przejrzyj Site Map po spiderowaniu - porownaj z robots.txt
5. Sprawdz kazdy wpis Disallow z robots.txt - czy prowadzi do wrazliwych zasobow
6. Sprawdz tagi META robots w kodzie zrodlowym strony (noindex, nofollow)
7. Poszukaj linkow do sitemap w robots.txt
8. Sprawdz czy istnieja alternatywne sitemapy (sitemap-news.xml, sitemap-images.xml)

