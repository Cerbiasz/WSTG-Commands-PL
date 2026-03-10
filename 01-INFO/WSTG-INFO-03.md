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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### robots.txt — co szukac

- **Disallow** wpisy ujawniaja ukryte sciezki — atakujacy sprawdzaja je w pierwszej kolejnosci
- Nie uzywaj `robots.txt` do ukrywania wrazliwych zasobow — to informacja publiczna
- `User-agent: *` + `Disallow: /admin/` = informacja dla atakujacego gdzie jest panel admina
- Sprawdz roznice miedzy wersjami HTTP i HTTPS robots.txt

### Typowe wycieki w robots.txt

| Wpis Disallow | Co ujawnia |
|--------------|-----------|
| `/admin/`, `/administrator/` | Panel administracyjny |
| `/backup/`, `/old/`, `/temp/` | Katalogi z backupami |
| `/api/`, `/api/v1/internal/` | Wewnetrzne endpointy API |
| `/staging/`, `/dev/`, `/test/` | Srodowiska deweloperskie |
| `/cgi-bin/`, `/scripts/` | Skrypty serwerowe |
| `/wp-admin/`, `/wp-includes/` | Struktura WordPress |

### sitemap.xml — informacje

- Zawiera pelna liste URL-ow strony — mapuje powierzchnie ataku
- Moze zawierac URL-e niedostepne z glownej nawigacji
- Sprawdz `sitemap_index.xml` — moze wskazywac na wiele sitemapów
- Porownaj URL-e z sitemap z wynikami crawlingu — roznice moga wskazywac na ukryte zasoby

### security.txt (RFC 9116)

- Lokalizacja: `/.well-known/security.txt`
- Zawiera: kontakt do zglaszania podatnosci, polityka, klucz PGP
- Moze ujawnic: adresy email, programy bug bounty, scope testow
- Sprawdz pole `Expires` — przestarzaly plik moze zawierac nieaktualne informacje

### .well-known — interesujace endpointy

| Endpoint | Co zawiera |
|----------|-----------|
| `/.well-known/openid-configuration` | Konfiguracja OAuth/OIDC — token endpoint, supported scopes |
| `/.well-known/assetlinks.json` | Powiazania Android App Links |
| `/.well-known/apple-app-site-association` | Powiazania iOS Universal Links |
| `/.well-known/change-password` | URL do zmiany hasla (jesli zaimplementowany) |
| `/.well-known/jwks.json` | Klucze publiczne JWT — weryfikacja tokenow |

### Obrona

- Nie polegaj na `robots.txt` jako mechanizmie bezpieczenstwa — to sugestia dla crawlerow
- Blokuj dostep do wrazliwych zasobow przez autentykacje i autoryzacje, nie robots.txt
- Nie umieszczaj wewnetrznych sciezek w robots.txt — uzyj `noindex` meta tag zamiast tego
- Regularnie przegladaj sitemap.xml — usuwaj sciezki ktore nie powinny byc publiczne

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AdminPanelFinder | Enumeracja interfejsow administracyjnych aplikacji | [GitHub](https://github.com/moeinfatehi/Admin-Panel_Finder) |
| Backup Finder | Wyszukiwanie plikow kopii zapasowych i tymczasowych na serwerze | [GitHub](https://github.com/moeinfatehi/Backup-Finder) |
