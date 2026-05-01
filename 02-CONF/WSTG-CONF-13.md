# WSTG-CONF-13 — Test Path Confusion

## Cel

Wykrycie różnic w interpretacji ścieżek między reverse proxy a backendem (path normalization differences) oraz Web Cache Deception. Atakujący wykorzystuje różnice (`..;`, `%252e`, double-slash) do bypassu auth lub kradzieży cached authenticated content.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-13-path-confusion.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-13.jsonl
```

Szablon w 3 grupach: Cache Deception (`/me/x.css`, `/account/x.js` — authenticated content z static-like extension), Path normalization bypass (URL encoding, double-slash, backslash), Matrix params (`;jsessionid=`, `..;/`).

### Dodatkowe oficjalne szablony Nuclei

```bash
# Path traversal misconfigurations
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/ -tags traversal,path

# Cache poisoning / deception
nuclei -l burp-export.xml -im burp \
       -tags cache,deception
```

### Suplementarne narzędzia

```bash
# Param Miner (Burp ext) - zaawansowane cache poisoning detection
# https://github.com/PortSwigger/param-miner

# WebCacheVulnerabilityScanner
go install github.com/Hackmanit/Web-Cache-Vulnerability-Scanner/cmd/wcvs@latest
wcvs -u target.com
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Cache Deception (static ext na dynamic content) | ✓ | — |
| URL encoding bypass (%2e, %252e) | ✓ | — |
| Double-slash, backslash | ✓ | — |
| Matrix params (;jsessionid, ..;/) | ✓ | — |
| Tomcat path bypass `/admin/..;/public/` | ✓ | — |
| Cache key normalization differences | częściowe | wymaga multi-request differential |
| HTTP/2 desync via path | — | osobno → INPV-16 |
| Web Cache Poisoning (header-based) | — | Param Miner / WCVS |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Identify caching**: które responses mają `X-Cache: HIT`, `Age`, `Cache-Control: public`.
2. **Cache Deception probe**: dla każdego authenticated endpoint (`/me`, `/account`, `/profile`) testować `<endpoint>/<canary>.css` — czy zwraca user content z `Content-Type: text/html`?
3. **Cache verification**: jeśli sukces, sprawdzić z innego User-Agent czy cached version dostępna anonymously.
4. **Path normalization bypass**: na każdym chronionym endpoint (auth-required) testować encoding warianty.
5. **Tomcat-specific `..;/` bypass**: jeśli Tomcat backend, klasyczny `/admin/..;/public/`.
6. **Reverse proxy + backend differential**: porównanie responses na dziwne paths z Cloudflare/Akamai vs direct backend (jeśli możliwe).

### Co MUSI być sprawdzone (10 punktów)

- [ ] Cache Deception: `/me/<random>.css` zwraca dynamic content?
- [ ] Cache Deception: `<endpoint>/<random>.{js,png,jpg,json,html}`
- [ ] URL encoding bypass: `/admin/..%2f`, `%2e%2e/admin`
- [ ] Double URL encoding: `%252e%252e/admin`
- [ ] Double slash: `/admin//`, `//admin/`
- [ ] Backslash: `/admin\..`, `\admin`
- [ ] Self-reference: `/admin/./`
- [ ] Tomcat matrix params: `/admin/..;/public/`
- [ ] jsessionid matrix: `/admin;jsessionid=x`
- [ ] Trailing dot/space: `/admin.`, `/admin%20`

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Path confusion — mechanizm

- Różnice w interpretacji ścieżek między **reverse proxy** (Nginx, Apache) a **backendem** (Tomcat, Node.js, Spring)
- Proxy może uznać ścieżkę za publiczną, a backend interpretuje ją jako dostęp do chronionego zasobu
- Kluczowe: normalizacja URL odbywa się w różnych momentach na różnych komponentach

### Techniki path confusion

| Technika | Przykład | Cel |
|----------|---------|-----|
| Path traversal | `/public/../admin` | Ominięcie kontroli dostępu |
| Semicolon (Tomcat/Jetty) | `/admin/..;/public` | Tomcat traktuje `;` jako separator parametrów ścieżki |
| Double URL encoding | `%252e%252e%252f` | Bypass WAF — dekodowanie odbywa się dwukrotnie |
| Null byte | `/admin%00.jpg` | Starsze serwery obcinają po null byte |
| Backslash | `/admin\..\/public` | Windows IIS interpretuje `\` jak `/` |
| UTF-8 overlong | `%c0%af` = `/` | Bypass filtrów ASCII |
| Trailing dot/space | `/admin.` lub `/admin%20` | IIS ignoruje trailing dot/space |
| Double slash | `//admin` | Niektóre proxy pomijają reguły dla podwójnego slasha |

### Reverse proxy + backend — niespójności

| Scenariusz | Proxy widzi | Backend widzi |
|-----------|-------------|---------------|
| `/public/..;/admin` | `/public/..;/admin` (publiczne) | `/admin` (chronione) |
| `/admin/./` | `/admin/./` (block) | `/admin/` (normalizacja) |
| `/Admin` | `/Admin` (nie matchuje regule `/admin`) | `/admin` (case insensitive) |
| `//admin` | `//admin` (pomija regułę) | `/admin` (normalizacja) |

### Konfiguracja — jak zapobiegać

**Nginx + backend:**
```
# Normalizuj ścieżki PRZED przekazaniem do backendu
merge_slashes on;  # domyślnie włączone
# Blokuj path traversal
location ~* /\.\./ { return 403; }
# Blokuj semicolon
location ~* ; { return 403; }
```

**Apache:**
```
# Włącz AllowEncodedSlashes Off (domyślnie)
AllowEncodedSlashes Off
# mod_security: blokuj path traversal
SecRule REQUEST_URI "\.\./" "id:1,deny,status:403"
```

### Obrona

- **Normalizuj ścieżki** na proxy/WAF PRZED przekazaniem do backendu
- Testuj te same reguły dostępu na proxy I backendzie — nie polegaj na jednej warstwie
- Blokuj znaki specjalne w ścieżkach: `..`, `;`, `%00`, `%2e`, `%2f` na wejściu
- Użyj **allowlist** ścieżek zamiast denylist
- Upewnij się że proxy i backend używają tego samego algorytmu normalizacji URL
- Testuj case sensitivity — jeśli proxy jest case-sensitive a backend nie, to vulnerability

## Pentesterskie deep dive

### Mniej znane techniki

- **Web Cache Deception 2.0** (Omer Gil + community research): nowe warianty wykorzystują CDN URL normalization. CloudFront/Akamai mogą cache `/api/me/secret.css` jako static jeśli backend zwraca user content. Testować z różnymi extensions per CDN.
- **Cache key vs Cache-Control mismatch**: `/api/me?cache=true` może być cached publicly nawet gdy `Cache-Control: private` (cache key includes query).
- **Tomcat AJP bypass via `..;/`** (CVE-2020-1938 Ghostcat): related path bypass + AJP attack chain.
- **Spring Security `;` bypass**: starsze wersje Spring Security ignorują matrix params w URL matching → `/admin/x;/public` może bypassować admin auth filter.
- **Cache poisoning via Vary**: `Vary: User-Agent` + atakujący sets `User-Agent: <attack>` → cached version z atak content dla wszystkich users z tym samym UA.
- **HTTP/2 path normalization differences**: HTTP/2 frontend → HTTP/1 backend conversion może zmienić path encoding.

### Common pitfalls

- **Cache deception wymaga dynamic content + cacheable**: jeśli Cache-Control: private/no-store, deception nie działa. Cross-check.
- **Burp Cache Extension nie testuje wszystkich extensions**: `.css`, `.js` typowe; ale `.png`, `.json`, `.svg`, `.ico` też cached publicly w wielu CDN.
- **Different per region**: ten sam target może mieć różne cache rules per CDN region — test multi-IP.

### Świeżynki z research

- **PortSwigger Web Cache Deception research**: https://portswigger.net/research/practical-web-cache-poisoning
- **Web Cache Vulnerability Scanner**: https://github.com/Hackmanit/Web-Cache-Vulnerability-Scanner
- **Smashing the State Machine** (James Kettle): https://portswigger.net/research/smashing-the-state-machine
- **HackTricks Cache Deception**: https://book.hacktricks.xyz/pentesting-web/cache-deception
- **Spring Security path bypass research** (Orange Tsai): https://blog.orange.tw/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Param Miner | Cache poisoning + hidden parameter discovery | [GitHub](https://github.com/PortSwigger/param-miner) |
| HTTP Request Smuggler | HTTP/2 desync, path confusion vectors | [GitHub](https://github.com/PortSwigger/http-request-smuggler) |
| Hackvertor | URL encoding manipulation | [GitHub](https://github.com/PortSwigger/hackvertor) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/13-Test_for_Path_Confusion
- PortSwigger Web Cache Poisoning: https://portswigger.net/research/practical-web-cache-poisoning
- HackTricks Cache Deception: https://book.hacktricks.xyz/pentesting-web/cache-deception
- Web Cache Vulnerability Scanner: https://github.com/Hackmanit/Web-Cache-Vulnerability-Scanner
- Orange Tsai research: https://blog.orange.tw/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.1.1 | Generic Web Service (L1) | Same parsing logic for all endpoints. |
| V13.1.5 | Generic Web Service (L2) | Strict input validation including path normalization. |
