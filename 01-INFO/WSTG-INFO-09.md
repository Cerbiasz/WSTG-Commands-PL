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

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Vulnerable_Dependency_Management_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Identyfikacja wersji aplikacji — techniki

| Technika | Opis | Niezawodnosc |
|----------|------|-------------|
| Meta generator tag | `<meta name="generator" content="WordPress 6.2">` | Wysoka (jesli nie usuniete) |
| Pliki wersji | `/CHANGELOG.txt`, `/VERSION`, `/readme.html` | Wysoka |
| RSS/Atom feed | `<generator>` w feedzie | Srednia |
| Hash plikow statycznych | MD5 CSS/JS vs baza referencyjnych hashów | Wysoka |
| Error pages | Stack trace, domyslne strony bledow | Srednia |
| HTTP headers | `X-Generator`, `X-Powered-By` | Srednia (moze byc sfalsowane) |
| Favicon hash | Hash favicony → identyfikacja technologii | Niska-srednia |
| URL patterns | Struktura URL specyficzna dla aplikacji | Srednia |

### Off-the-shelf vs custom application

| Cecha | Off-the-shelf (CMS, framework) | Custom application |
|-------|-------------------------------|-------------------|
| Identyfikacja | Latwa — znane sygnatury | Trudna — brak publicznych sygnatur |
| CVE search | Mozliwy po ustaleniu wersji | Nie dotyczy |
| Testowanie | Znane podatnosci + konfiguracja | Pelny pentest wymagany |
| Exploit availability | Publiczne exploity (Metasploit, ExploitDB) | Brak — wymaga wlasnego development |

### Po identyfikacji wersji — nastepne kroki

1. **Szukaj CVE**: `searchsploit wordpress 6.2`, NVD, Vulners, Snyk DB
2. **Sprawdz ExploitDB**: `searchsploit -m <exploit_id>` — gotowe exploity
3. **Nuclei templates**: `nuclei -u target -tags cve` — automatyczne testowanie
4. **Porownaj z latest**: czy wersja jest aktualna? ile wersji za najnowsza?
5. **Sprawdz pluginy/moduły**: WPScan, JoomScan — podatnosci w dodatkach

### Baza wersji — narzedzia

| Narzedzie | Uzycie |
|-----------|--------|
| WPScan | `wpscan --url target` — WordPress (wersja, pluginy, tematy, uzytkownicy) |
| JoomScan | `joomscan -u target` — Joomla |
| Droopescan | `droopescan scan drupal -u target` — Drupal |
| CMSeek | `cmseek -u target` — uniwersalny CMS scanner |
| retire.js | Podatne wersje bibliotek JS |

### Obrona

- **Aktualizuj regularnie** — wiekszosci exploitow dotyczy starych wersji
- Usun pliki ujawniajace wersje: `CHANGELOG.txt`, `readme.html`, `VERSION`
- Usun lub zmien meta tag `generator`
- Wdróż **patch management process** — testuj i wdrazaj aktualizacje bezpieczenstwa
- Monitoruj advisories bezpieczenstwa dla uzywanych technologii
- Uzyj WAF jako tymczasowa ochrone (virtual patching) przed wdrozeniem aktualizacji

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CMS Scanner | Wykrywanie podatnosci w popularnych systemach CMS | [BApp Store](https://portswigger.net/bappstore/1bf95d0be40c447b94981f5696b1a18e) |
| Detect Dynamic JS | Porownywanie plikow JS w celu wykrycia dynamicznej zawartosci | [BApp Store](https://portswigger.net/bappstore/4a657674ebe3410b92280613aa512304) |
