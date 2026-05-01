# WSTG-CONF-08 — Test RIA Cross Domain Policy

## Cel

Sprawdzenie polityki cross-domain dla legacy RIA (Rich Internet Applications) — Flash (`crossdomain.xml`), Silverlight (`clientaccesspolicy.xml`). Mimo że Flash jest EOL od 2020, te pliki nadal istnieją na produkcji i z `domain="*"` umożliwiają pełny cross-origin read.

> Test częściowo automatyzowany — `crossdomain.xml` jest sprawdzany w **WSTG-INFO-03 metafiles**. Tu MD koncentruje się na analizie polityki + nowoczesnym CORS (cross-ref WSTG-CONF-14).

## Automatyzacja Nuclei

```bash
# WSTG-INFO-03 zawiera test crossdomain.xml + clientaccesspolicy.xml
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-03-metafiles.yaml

# CORS misconfiguration (modern equivalent)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/cors-misconfiguration/

# Manual CORS testing per endpoint
nuclei -l burp-export.xml -im burp \
       -tags cors,misconfig
```

## Coverage Matrix

| Wymiar | Pokryte przez | Notka |
|---|---|---|
| crossdomain.xml exists + content | WSTG-INFO-03 | nasz szablon |
| clientaccesspolicy.xml | WSTG-INFO-03 | nasz szablon |
| `domain="*"` wildcard | WSTG-INFO-03 (extractor) | + manual analysis |
| CORS Access-Control-Allow-Origin reflection | http/misconfiguration/cors-* | manual + scanner |
| `Allow-Credentials: true` z luźnym ACAO | manual | klasyczna luka |
| Origin: null bypass | manual | iframe sandbox technique |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Pull crossdomain.xml + clientaccesspolicy.xml**: WSTG-INFO-03 robot.
2. **Analyze content**: każdy `<allow-access-from domain>` → ocena czy domena zaufana.
3. **CORS test per endpoint**: dla każdego `/api/*` wysłać `Origin: https://evil.com` i sprawdzić `Access-Control-Allow-Origin`.
4. **Origin reflection test**: `Origin: https://attacker.target.com.evil.com` — czy backend whitelistuje suffix lub prefix.
5. **Credentials misuse**: `Allow-Credentials: true` z reflected origin = data exfil.

### Co MUSI być sprawdzone (8 punktów)

- [ ] `/crossdomain.xml` content
- [ ] `/clientaccesspolicy.xml` content
- [ ] Wildcard `domain="*"` w polityce
- [ ] Wszystkie wpisy `<allow-access-from>` — sprawdź zaufanie
- [ ] CORS `Access-Control-Allow-Origin` reflection per endpoint
- [ ] `Access-Control-Allow-Credentials: true` w połączeniu z luźnym ACAO
- [ ] `Origin: null` bypass test
- [ ] Subdomain bypass (`evil.target.com`, `target.com.evil.com`)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md, REST_Security_Cheat_Sheet.md

### Cross-domain policy — niebezpieczne konfiguracje

| Konfiguracja | Ryzyko | Poprawna wersja |
|-------------|--------|-----------------|
| `allow-access-from domain="*"` | Dowolna domena może czytać dane | Ogranicz do konkretnych domen |
| `<allow-http-request-headers-from domain="*">` | Dowolne nagłówki z dowolnej domeny | Tylko zaufane domeny |
| `Access-Control-Allow-Origin: *` + credentials | Nie działa w przeglądarce, ale świadczy o złej konfiguracji | Konkretna domena, nie wildcard |
| Reflected Origin w ACAO | Atakujący może czytać dane ofiary | Whitelist dozwolonych origin |
| `Access-Control-Allow-Origin: null` | Bypass przez iframe sandbox | Nie akceptuj null origin |

### CORS — poprawna konfiguracja

- **Whitelist origin**: sprawdzaj Origin z listą dozwolonych domen — nie odbijaj dynamicznie
- **Credentials**: `Access-Control-Allow-Credentials: true` wymaga konkretnego origin (nie `*`)
- **Metody**: ogranicz `Access-Control-Allow-Methods` do potrzebnych (GET, POST)
- **Nagłówki**: ogranicz `Access-Control-Allow-Headers` do minimum
- **Max-Age**: ustaw `Access-Control-Max-Age` aby zmniejszyć preflight requests
- **Expose-Headers**: nie ujawniaj wrażliwych nagłówków

### crossdomain.xml (Flash) — status

- Flash Player oficjalnie wycofany (EOL grudzień 2020)
- Pliki `crossdomain.xml` nadal mogą istnieć na serwerach — usuń je
- Jeśli konieczny dla legacy: `allow-access-from domain="specific.domain.com"`, **nigdy** `domain="*"`

### clientaccesspolicy.xml (Silverlight) — status

- Silverlight oficjalnie wycofany (EOL październik 2021)
- Usuń pliki `clientaccesspolicy.xml` z serwerów produkcyjnych
- Legacy Silverlight apps powinny być zmigrowane

### Testowanie CORS — payloady

```
Origin: https://evil.com                    # Podstawowy test
Origin: null                                # Iframe sandbox bypass
Origin: https://target.com.evil.com         # Subdomena atakującego
Origin: https://eviltarget.com              # Suffix match bypass
Origin: https://target.com%60.evil.com      # Backtick bypass
Origin: https://sub.target.com              # Subdomena target
```

### Obrona

- Usuń `crossdomain.xml` i `clientaccesspolicy.xml` jeśli nie są potrzebne
- Implementuj CORS whitelist na serwerze — nie odbijaj Origin dynamicznie
- Nie łącz `Allow-Credentials: true` z luźnymi origin rules
- Testuj CORS na każdym endpoincie API osobno — konfiguracja może się różnić
- Użyj CSP `connect-src` jako dodatkowa warstwę ochrony

## Pentesterskie deep dive

### Mniej znane techniki

- **CORS Origin parser confusion**: backend może parsować Origin jako `target.com.evil.com` → suffix match daje `target.com`. Frans Rosén research.
- **`Origin: null` via sandboxed iframe**: data: URI iframe ma `Origin: null`. Aplikacje akceptujące null = pełny CSRF z dowolnego sandboxed contextu.
- **Wildcard subdomain takeover + CORS**: `target.com` whitelistuje `*.target.com`, ale `staging.target.com` nie żyje (subdomain takeover), atakujący przejmuje → CORS umożliwia data exfil.
- **CORS via 3xx redirect**: redirect z origin-A na origin-B z CORS pre-flight może być wykorzystany do bypassu (community pattern).
- **PostMessage misuse + CORS**: aplikacje używające `postMessage` cross-origin często nie weryfikują origin w handler — JavaScript-side bypass.

### Common pitfalls

- **`Access-Control-Allow-Origin: *` z `Allow-Credentials: true` jest IGNOROWANY przez przeglądarkę**: błąd konfiguracji ale nie real-world exploit (chyba że wykorzystany przez non-browser HTTP client).
- **Pre-flight cache**: `Access-Control-Max-Age: 86400` cache'uje CORS decision — testy muszą używać unique origins.
- **Vary: Origin missing**: cache shared między różnymi origin → poison cache z atak origin → victim dostaje cached response.

### Świeżynki z research

- **CORS misconfiguration enumeration via HTTP/2** (community) — niektóre warianty bypass z HTTP/2.
- **Frans Rosén CORS research**: classic patterns: https://hackerone.com/reports/235200
- **PortSwigger Academy — CORS**: https://portswigger.net/web-security/cors
- **HackTricks CORS Bypass**: https://book.hacktricks.xyz/pentesting-web/cors-bypass

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| CORS* | Active CORS testing | [GitHub](https://github.com/PortSwigger/cors-additional-checks) |
| Param Miner | Hidden header discovery | [GitHub](https://github.com/PortSwigger/param-miner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/08-Test_RIA_Cross_Domain_Policy
- OWASP REST Security Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html
- PortSwigger CORS Lab: https://portswigger.net/web-security/cors
- HackTricks CORS Bypass: https://book.hacktricks.xyz/pentesting-web/cors-bypass

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.5.3 | Configuration (L1) | CORS Access-Control-Allow-Origin uses explicit list, no wildcards. |
| V14.5.4 | Configuration (L2) | HTTP request methods authenticated and authorized. |
