# templates/ — Szablony Nuclei dla WSTG Suite

## Mapa szablonów per WSTG ID

| WSTG ID | Szablon | Status | Severity | Performance |
|---|---|---|---|---|
| **WSTG-INFO** (10 testów - Information Gathering) |||||
| INFO-02 | `wstg-info-02-fingerprint-server.yaml` | ✓ NOWY | info | very low (~5 req) |
| INFO-03 | `wstg-info-03-metafiles.yaml` | ✓ NOWY | info | very low (~30 req) |
| INFO-04 | `wstg-info-04-attack-surface.yaml` | ✓ NOWY | medium | medium (~80 req) |
| INFO-05 | `wstg-info-05-content-leakage.yaml` | ✓ NOWY | medium | very low (~3 req) |
| INFO-08 | `wstg-info-08-framework-fingerprint.yaml` | ✓ NOWY | info | very low (~1 req) |
| INFO-09 | `wstg-info-09-app-version.yaml` | ✓ NOWY | medium | low (~25 req) |
| **WSTG-CONF** (14 testów - Configuration) |||||
| CONF-02 | `wstg-conf-02-platform-config.yaml` | ✓ NOWY | medium | low (~50 req) |
| CONF-03 | `wstg-conf-03-file-extensions.yaml` | ✓ NOWY | high | low (~50 req) |
| CONF-06 | `wstg-conf-06-http-methods.yaml` | ✓ NOWY | medium | low (~10 req) |
| CONF-07 | `wstg-conf-07-hsts.yaml` | ✓ NOWY | low | very low (~1 req) |
| CONF-10 | `wstg-conf-10-subdomain-takeover.yaml` | ✓ NOWY | high | very low (~1 req) |
| CONF-11 | `wstg-conf-11-cloud-storage.yaml` | ✓ NOWY | high | very low (~5 req) |
| CONF-12 | `wstg-conf-12-csp.yaml` | ✓ NOWY | medium | very low (~1 req) |
| CONF-13 | `wstg-conf-13-path-confusion.yaml` | ✓ NOWY | high | low (~30 req) |
| CONF-14 | `wstg-conf-14-security-headers.yaml` | ✓ NOWY | medium | very low (~1 req) |
| **WSTG-IDNT** (5 testów - Identity) |||||
| IDNT-04 | `wstg-idnt-04-account-enumeration.yaml` | ✓ NOWY | medium | very low (~1 req) |
| **WSTG-ATHN** (11 testów - Authentication) |||||
| ATHN-01 | `wstg-athn-01-credentials-transport.yaml` | ✓ NOWY | high | very low |
| ATHN-02 | `wstg-athn-02-default-credentials.yaml` | ✓ NOWY | high | low |
| ATHN-06 | `wstg-athn-06-browser-cache.yaml` | ✓ NOWY | medium | very low |
| **WSTG-ATHZ** (5 testów - Authorization) |||||
| ATHZ-02 | `wstg-athz-02-bypass-headers.yaml` | ✓ NOWY | high | low (~30 req) |
| **WSTG-SESS** (11 testów - Session Management) |||||
| SESS-02 | `wstg-sess-02-cookie-attributes.yaml` | ✓ NOWY | medium | very low |
| SESS-05 | `wstg-sess-05-csrf.yaml` | ✓ NOWY | medium | very low |
| SESS-09 | `wstg-sess-09-session-hijacking.yaml` | ✓ NOWY | medium | very low |
| SESS-10 | `wstg-sess-10-jwt.yaml` | ✓ NOWY | high | very low |
| **WSTG-INPV** (20 testów - Input Validation) — review existing |||||
| INPV-01 | `wstg-inpv-01-reflected-xss.yaml` | ✓ POPRAWIONY (OOB matcher) | high | medium-high |
| INPV-03 | `wstg-inpv-03-verb-tampering.yaml` | ✓ ZACHOWANY | medium | low |
| INPV-04 | `wstg-inpv-04-hpp.yaml` | ✓ ZACHOWANY | medium | low |
| INPV-05 | `wstg-inpv-05-sqli-{error,boolean,time}-based.yaml` | ✓ POPRAWIONY (error+OOB) | critical | medium |
| INPV-06 | `wstg-inpv-06-ldap-injection.yaml` | ✓ ZACHOWANY | high | low |
| INPV-07 | `wstg-inpv-07-xml-injection.yaml` | ✓ POPRAWIONY (OOB) | high | medium |
| INPV-08 | `wstg-inpv-08-ssi-injection.yaml` | ✓ POPRAWIONY (OOB) | high | low |
| INPV-09 | `wstg-inpv-09-xpath-injection.yaml` | ✓ POPRAWIONY (OOB) | high | low |
| INPV-10 | `wstg-inpv-10-imap-smtp-injection.yaml` | ✓ POPRAWIONY (OOB) | medium | low |
| INPV-11 | `wstg-inpv-11-lfi-rfi.yaml` | ✓ POPRAWIONY (OOB) | high | medium |
| INPV-12 | `wstg-inpv-12-command-injection.yaml` | ✓ POPRAWIONY (OOB) | critical | high |
| INPV-13 | `wstg-inpv-13-format-string.yaml` | ✓ ZACHOWANY | low | low |
| INPV-15 | `wstg-inpv-15-http-splitting.yaml` | ✓ POPRAWIONY (OOB) | medium | low |
| INPV-16 | `wstg-inpv-16-http-smuggling.yaml` | ✓ ZACHOWANY | high | low |
| INPV-17 | `wstg-inpv-17-host-header.yaml` | ✓ POPRAWIONY (OOB) | medium | low |
| INPV-18 | `wstg-inpv-18-ssti.yaml` | ✓ ZACHOWANY | critical | medium |
| INPV-19 | `wstg-inpv-19-ssrf.yaml` | ✓ POPRAWIONY (OOB) | high | medium |
| INPV-20 | `wstg-inpv-20-mass-assignment.yaml` | ✓ ZACHOWANY | medium | low |
| **WSTG-ERRH** (2 testy - Error Handling) |||||
| ERRH-01 | `wstg-errh-01-error-page.yaml` | ✓ NOWY | medium | very low |
| ERRH-02 | `wstg-errh-02-stack-trace.yaml` | ✓ NOWY | medium | very low |
| **WSTG-CRYP** (4 testy - Cryptography) |||||
| CRYP-01 | `wstg-cryp-01-tls-config.yaml` | ✓ NOWY | medium | very low |
| CRYP-03 | `wstg-cryp-03-unencrypted-channels.yaml` | ✓ NOWY | high | very low |
| **WSTG-CLNT** (15 testów - Client-side) |||||
| CLNT-01 | `wstg-clnt-01-dom-xss.yaml` | ✓ NOWY | medium | very low |
| CLNT-03 | `wstg-clnt-03-html-injection.yaml` | ✓ NOWY | medium | low |
| CLNT-04 | `wstg-clnt-04-url-redirect.yaml` | ✓ NOWY | medium | low |
| CLNT-07 | `wstg-clnt-07-cors.yaml` | ✓ NOWY | high | low |
| CLNT-09 | `wstg-clnt-09-clickjacking.yaml` | ✓ NOWY | medium | very low |
| CLNT-13 | `wstg-clnt-13-xssi.yaml` | ✓ NOWY | medium | very low |
| CLNT-14 | `wstg-clnt-14-reverse-tabnabbing.yaml` | ✓ NOWY | low | very low |
| CLNT-15 | `wstg-clnt-15-csti.yaml` | ✓ NOWY | high | low |
| **WSTG-APIT** (3 testy - API Testing) |||||
| APIT GraphQL | `wstg-apit-graphql.yaml` | ✓ NOWY | medium | very low |

## Performance budget

| Performance | Liczba requestów | Czas (typical app) |
|---|---|---|
| very low | < 10 | < 30s |
| low | 10-100 | 30s - 5 min |
| medium | 100-500 | 5-15 min |
| high | 500-2000 | 15-30 min |

**Suma all templates**: ~3000-5000 requestów per host typical = ~30-60 min na typowej aplikacji z 50-100 endpointami w Burp export.

## ASVS Mapping

Każdy szablon ma odpowiednie tagi `asvs-vX.X.X` w `info.tags`. Dla raportu zgodności ASVS:

```bash
# Filter findings per ASVS control
nuclei -tags asvs-v5.3.4 -l burp.xml -im burp ...
```

## Coverage Matrix

Każdy szablon ma w komentarzu YAML:
- **Coverage Matrix**: które wymiary są pokryte (✓) a które wyłączone (✗)
- **Source mapping**: skąd pochodzą poszczególne checki (CHEATSHEET WSTG vs research)
- **Performance budget**: estymowany czas wykonania
- **Known limitations**: znane limity szablonu

## Manual-only tests

Nie wszystkie WSTG testy mają szablony Nuclei - manual-only:
- INFO: 01, 06, 07, 10
- CONF: 01, 04, 05, 08, 09
- IDNT: 01, 02, 03, 05
- ATHN: 03, 04, 05, 07, 08, 09, 10, 11
- ATHZ: 01, 03, 04, 05
- SESS: 01, 03, 04, 06, 07, 08, 11
- CRYP: 02, 04
- CLNT: 02, 05, 06, 08, 10, 11, 12
- BUSL: wszystkie 10 testów
- APIT: 02

Te testy są w plikach MD per-test (sekcja "Standard pentesterski") - bez sekcji "Automatyzacja Nuclei".

## Safety nets w szablonach

Każdy szablon (gdzie ma sens) implementuje:
1. **Pre-condition**: blocklist destrukcyjnych ścieżek (`/delete`, `/cancel`, etc.)
2. **OPTIONS/HEAD/DELETE skip** - tylko bezpieczne metody dla fuzzing
3. **Static asset filter**: pomija .js, .css, obrazki, woff
4. **Auth handling**: `-V auth_token` i `-V session_cookie` przekazywane przez wrapper
5. **Anti-FP matchers**: WAF block detection, CSRF rejection, 401 filter

Override blocklist destrukcyjnych: `--include-destructive` w `run-wstg-suite.sh`.

## Walidacja

```bash
# Sprawdź syntax wszystkich templates
nuclei -t templates/ -validate

# Test single template przeciwko local app
nuclei -t templates/wstg-conf-12-csp.yaml -u https://target.com
```
