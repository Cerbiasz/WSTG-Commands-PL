# WSTG-CONF-14 — Test Other HTTP Security Header Misconfigurations

## Cel

Sprawdzenie konfiguracji nagłówków bezpieczeństwa HTTP innych niż HSTS i CSP: X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, Cross-Origin-* (COOP/COEP/CORP), Cache-Control. Każdy brakujący/słaby nagłówek otwiera klasyczny atak (clickjacking, MIME sniffing, data leakage przez Referer).

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-14-security-headers.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-14.jsonl
```

Szablon w jednym requeście z 11 matcherami: X-Frame-Options brak/weak, X-Content-Type-Options brak, Referrer-Policy brak/weak, Permissions-Policy brak, COOP/CORP brak, X-XSS-Protection legacy enabled, Server version disclosure, Cache-Control: public na dynamic, Cache-Control brak.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Security headers misconfiguration (compleksowy)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/http-missing-security-headers.yaml

# Per-header dedicated:
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/missing-x-frame-options.yaml \
       -t resources/nuclei-templates/http/misconfiguration/clickjacking-detection.yaml
```

### Suplementarne narzędzia

```bash
# securityheaders.com - automatic grading
curl -s "https://securityheaders.com/?q=https://target.com&hide=on&followRedirects=on"

# Mozilla Observatory
curl -s "https://http-observatory.security.mozilla.org/api/v1/analyze?host=target.com" -X POST
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| X-Frame-Options brak / weak | ✓ | — |
| X-Content-Type-Options nosniff | ✓ | — |
| Referrer-Policy brak / weak | ✓ | — |
| Permissions-Policy brak | ✓ | granular per-feature → manual |
| COOP / COEP / CORP brak | ✓ | — |
| Cache-Control public na dynamic | ✓ | per-endpoint analysis → manual |
| X-XSS-Protection legacy 1 | ✓ | — |
| Server version disclosure | ✓ | (cross WSTG-INFO-02) |
| HSTS | — | osobno → CONF-07 |
| CSP | — | osobno → CONF-12 |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Baseline pull**: GET `/` + ekstrakcja wszystkich security headers.
2. **Per-endpoint check**: niektóre endpointy (login, profile) wymagają stricter headers (Cache-Control: no-store dla login responses).
3. **Tools cross-check**: securityheaders.com + Mozilla Observatory dla automated grading.
4. **Clickjacking test**: tworzy `<iframe src="https://target.com/sensitive">` w test page → czy się ładuje (no X-Frame-Options/CSP frame-ancestors).
5. **Per-stack hardening verification**: framework default settings (Spring Security, Helmet.js Express, Django SecurityMiddleware).

### Co MUSI być sprawdzone (12 punktów)

- [ ] X-Frame-Options DENY/SAMEORIGIN obecny LUB CSP frame-ancestors
- [ ] X-Content-Type-Options: nosniff
- [ ] Referrer-Policy ustawiony (preferowane: strict-origin-when-cross-origin)
- [ ] Permissions-Policy obecny z restrictive defaults
- [ ] COOP: same-origin (jeśli aplikacja używa OAuth popups)
- [ ] CORP: same-origin (dla static assets sensitive)
- [ ] Cache-Control: no-store na authenticated responses
- [ ] X-XSS-Protection: 0 (legacy disabled, nie 1)
- [ ] Server header bez wersji (cross WSTG-INFO-02)
- [ ] X-Powered-By header brak (lub fake)
- [ ] HSTS (cross WSTG-CONF-07)
- [ ] CSP (cross WSTG-CONF-12)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTTP_Headers_Cheat_Sheet.md

### Nagłówki bezpieczeństwa — kompletna lista

| Nagłówek | Wartość | Cel |
|----------|---------|-----|
| `X-Content-Type-Options` | `nosniff` | Blokuje MIME sniffing |
| `X-Frame-Options` | `DENY` / `SAMEORIGIN` | Ochrona przed clickjacking |
| `Content-Security-Policy` | Restrykcyjna polityka | XSS, injection prevention |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Wymuszanie HTTPS |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Kontrola Referer header |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Blokada API przeglądarki |
| `Cross-Origin-Opener-Policy` | `same-origin` | Izolacja okna przeglądarki |
| `Cross-Origin-Resource-Policy` | `same-origin` | Blokada cross-origin read |
| `Cross-Origin-Embedder-Policy` | `require-corp` | Wymaganie CORP na zasobach |
| `Cache-Control` | `no-store` (wrażliwe dane) | Zapobieganie cache'owaniu |

### Nagłówki do USUNIĘCIA (information disclosure)

| Nagłówek | Przykład | Ryzyko |
|----------|---------|--------|
| `Server` | `Apache/2.4.51` | Ujawnia technologie i wersje |
| `X-Powered-By` | `PHP/8.1.0` | Ujawnia język programowania |
| `X-AspNet-Version` | `4.0.30319` | Ujawnia wersję .NET |
| `X-AspNetMvc-Version` | `5.2` | Ujawnia wersję MVC |
| `X-Generator` | `WordPress 6.0` | Ujawnia CMS |
| `X-Runtime` | `0.012345` | Ujawnia czas przetwarzania (timing attack) |

### Referrer-Policy — opcje (od najbardziej restrykcyjnej)

- `no-referrer` — nigdy nie wysyłaj Referer
- `same-origin` — wysyłaj tylko do tego samego origin
- `strict-origin` — wysyłaj origin (bez path) tylko przez HTTPS→HTTPS
- `strict-origin-when-cross-origin` — **REKOMENDOWANE** — pełny URL same-origin, origin cross-origin
- `no-referrer-when-downgrade` — domyślne, nie wysyłaj przy HTTPS→HTTP

### Permissions-Policy — ważne dyrektywy

- `camera=()` — zablokuj dostęp do kamery
- `microphone=()` — zablokuj dostęp do mikrofonu
- `geolocation=()` — zablokuj dostęp do lokalizacji
- `payment=()` — zablokuj Payment Request API
- `usb=()` — zablokuj WebUSB
- `display-capture=()` — zablokuj Screen Capture API

### Cross-Origin headers (COOP/COEP/CORP)

- **COOP** (`same-origin`): izoluje okno przeglądarki — blokuje cross-origin window references
- **CORP** (`same-origin`): blokuje cross-origin read zasobów (obrazy, skrypty, fonty)
- **COEP** (`require-corp`): wymaga CORP na wszystkich załadowanych zasobach
- Razem włączają **cross-origin isolation** — wymagane dla SharedArrayBuffer, high-res timers

### Testowanie nagłówków

- Sprawdź https://securityheaders.com — automatyczna ocena
- Porównaj nagłówki na różnych endpointach — muszą być spójne
- Sprawdź nagłówki na HTTP vs HTTPS — mogą się różnić
- Testuj clickjacking: stwórz iframe z TARGET — sprawdź czy się ładuje

## Pentesterskie deep dive

### Mniej znane techniki

- **X-Frame-Options ALLOW-FROM deprecated** — przeglądarki ignorują (Chrome i Firefox); jeśli aplikacja używa, ochrona przeciwko clickjacking nie działa. Migracja do `Content-Security-Policy: frame-ancestors`.
- **Spectre / Side-channel via brak COOP**: brak `Cross-Origin-Opener-Policy: same-origin` umożliwia cross-origin window references → potencjalne side-channel attacks.
- **X-XSS-Protection: 1; mode=block bypass**: legacy header (deprecated w nowoczesnych przeglądarkach) — niektóre warianty `1; report=...` mogą ujawniać lokalne paths.
- **Cache-Control: public na auth response**: response z user-specific data (po `Authorization: Bearer ...`) z `Cache-Control: public` = atakujący może kraść z shared CDN cache (XS-Leak).
- **Permissions-Policy bypass via iframe**: iframe ze swoim `allow="camera"` może override parent policy → testowanie iframe restrictions.
- **Server timing attacks via X-Runtime**: precyzyjny czas (ms) ujawnia wewnętrzny processing time → enable timing attacks na auth (różny czas valid vs invalid user).

### Common pitfalls

- **CSP frame-ancestors zastępuje X-Frame-Options ALE w starszych przeglądarkach (IE/legacy mobile) X-Frame-Options dalej potrzebny**: defense in depth = oba.
- **Per-page security headers inconsistency**: login page ma stricter Cache-Control niż homepage. Jeśli middleware globalny ustawia `Cache-Control: public` to override naivenie.
- **CDN może strip headers**: niektóre CDN configs nie passing custom security headers → różnica między origin response i delivered response.

### Świeżynki z research

- **XS-Leaks (cross-site leaks)**: https://xsleaks.dev/ — szeroki katalog technik wykorzystujących missing security headers.
- **OWASP Secure Headers Project**: https://owasp.org/www-project-secure-headers/ — pełny katalog + recommended values.
- **Mozilla Observatory**: https://observatory.mozilla.org/ — A+ grading
- **securityheaders.com**: https://securityheaders.com/ — szybki check + grading

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Detekcja information leakage w headerach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| HTTP Security Headers | Pasywny check headers | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/14-Test_Other_HTTP_Security_Header_Misconfigurations
- OWASP HTTP Headers Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
- OWASP Secure Headers Project: https://owasp.org/www-project-secure-headers/
- securityheaders.com: https://securityheaders.com/
- Mozilla Observatory: https://observatory.mozilla.org/
- Mozilla Web Security Guidelines: https://infosec.mozilla.org/guidelines/web_security
- XS-Leaks Wiki: https://xsleaks.dev/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.1 | Configuration (L1) | Web tier configured to serve HTTP responses with safe Content-Type. |
| V14.4.7 | Configuration (L2) | Application sets sufficient anti-caching headers for sensitive data. |
| V14.5.1 | Configuration (L1) | HTTP request methods, including OPTIONS and TRACE, are documented. |
