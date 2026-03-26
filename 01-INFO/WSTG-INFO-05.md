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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Secrets_Management_Cheat_Sheet.md

### Wycieki informacji — co szukac

| Typ wycieku | Gdzie szukac | Przyklad |
|------------|-------------|---------|
| Klucze API | Pliki JS, komentarze HTML | `apiKey: "AIzaSy..."`, `aws_access_key_id` |
| Wewnetrzne IP | Komentarze, naglowki, JS | `10.0.0.x`, `192.168.x.x`, `172.16.x.x` |
| Adresy email | Komentarze, meta tagi | `dev@company.com`, `admin@internal.com` |
| Sciezki plikow | Stack traces, komentarze | `/var/www/html/`, `C:\inetpub\wwwroot\` |
| Wersje oprogramowania | META generator, komentarze | `WordPress 6.2`, `Drupal 9.5` |
| Dane debugowe | Console.log, komentarze | `// DEBUG:`, `// TODO: remove before deploy` |
| Tokeny sesji | URL, JavaScript | `?token=`, `sessionId` w URL |
| Credentials | JavaScript, komentarze | `password: "admin123"`, `// test account` |

### Komentarze developerskie — wzorce

```
<!-- TODO: fix authentication bypass -->
<!-- HACK: temporary workaround -->
<!-- FIXME: SQL injection here -->
<!-- username: admin, password: test123 -->
<!-- DEBUG: remove before production -->
/* API endpoint: https://internal-api.company.com */
```

### Source maps — ryzyko

- Pliki `.js.map` zawieraja **oryginalny kod zrodlowy** (przed minifikacja/bundlowaniem)
- Sprawdz: `//# sourceMappingURL=app.js.map` na koncu plikow JS
- Ujawniaja: nazwy zmiennych, komentarze, structure kodu, nazwy plikow
- **Obrona**: nie deployuj source map na produkcje, lub ogranicz dostep (403)

### Hardcoded secrets — regexy do wyszukiwania

| Secret | Regex |
|--------|-------|
| AWS Access Key | `AKIA[0-9A-Z]{16}` |
| AWS Secret Key | `[0-9a-zA-Z/+]{40}` |
| Google API Key | `AIza[0-9A-Za-z\\-_]{35}` |
| GitHub Token | `gh[pousr]_[A-Za-z0-9_]{36,}` |
| Slack Token | `xox[baprs]-[0-9a-zA-Z-]+` |
| JWT | `eyJ[A-Za-z0-9-_]+\.eyJ[A-Za-z0-9-_]+` |
| Private Key | `-----BEGIN (RSA\|EC\|DSA) PRIVATE KEY-----` |
| Generic password | `(password\|passwd\|pwd)\s*[:=]\s*['"][^'"]+` |

### Obrona

- **Nigdy nie hardcoduj** kluczy API, hasel, tokenow w kodzie frontendowym
- Uzyj zmiennych srodowiskowych lub secrets management (Vault, AWS Secrets Manager)
- Dodaj pre-commit hooks z narzedziem `truffleHog` lub `git-secrets` aby blokowac commity z secretami
- Nie deployuj source map na produkcje
- Usuwaj komentarze debugowe przed deploymentem (build pipeline)
- Uzyj CSP aby ograniczyc do jakich domen JS moze sie komunikowac

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp JS Miner | Automatyczne wyciaganie interesujacych danych z plikow JS i JSON | [GitHub](https://github.com/minamo7sen/burp-JS-Miner) |
| Secret Finder | Odkrywanie kluczy API, tokenow i wrazliwych danych w odpowiedziach | [GitHub](https://github.com/m4ll0k/BurpSuite-Secret_Finder) |
| Sensitive Discoverer | Wykrywanie wrazliwych informacji w wiadomosciach HTTP | [GitHub](https://github.com/CYS4srl/SensitiveDiscoverer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.5 | Unintended Information Leakage | Verify that documentation (such as for internal APIs) and monitoring endpoints are not exposed unless explicitly intended. |
| V16.5.1 | Error Handling | Verify that a generic message is returned to the consumer when an unexpected or security-sensitive error occurs, ensuring no exposure of sensitive internal system data such as stack traces, queries, secret keys, and tokens. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Unintended Information Leakage | Verify that the application does not expose detailed version information of backend components. |
