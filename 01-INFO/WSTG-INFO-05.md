# WSTG-INFO-05 — Review Web Page Content for Information Leakage

## Cel

Wykrycie wycieków informacji w treści serwowanej do klienta (HTML, JS, komentarze, meta tagi). Klucze API, hardcoded credentials, internalne URL, source maps, komentarze deweloperskie z TODO/FIXME — to materiał do dalszej eksploitacji albo do raportu bug bounty samego w sobie.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-05-content-leakage.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-info-05.jsonl
```

Szablon w jednym requeście (GET /) z wieloma matcherami: AWS keys (AKIA/ASIA), GCP API keys (AIza), GitHub tokens (gh[pousr]_), Stripe keys (sk_/pk_test|live), Slack tokens i webhooki, Twilio SID, SendGrid keys, Mailgun keys, JWT tokens, prywatne klucze (RSA/DSA/EC/OPENSSH), komentarze HTML z credentials/TODO/FIXME, internal IPs (RFC 1918 + 169.254), internal hostnames (.local/.internal/.corp), source map references, meta generator, stack trace fragments, filesystem paths, React/Webpack/Next.js debug markers, hardcoded internal API URLs.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Token leak detection
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/tokens/

# Generic file pattern matching
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/file/keys/ \
       -t resources/nuclei-templates/file/js/

# JS / source code analysis
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/files/

# Information disclosure misconfiguration
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/ -tags disclosure
```

### Suplementarne narzędzia (poza Nuclei)

```bash
# TruffleHog - dedykowany secret hunter (deep scan JS bundles)
trufflehog filesystem --directory ./js-bundles/

# GitLeaks
gitleaks detect --source ./js-bundles/

# linkfinder.py - extract endpoints from JS
python3 linkfinder.py -i https://target.com/static/main.js -o cli
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| AWS / GCP / Azure cloud keys | ✓ | — |
| GitHub / Stripe / Slack / Twilio / SendGrid / Mailgun keys | ✓ | — |
| JWT tokens leaked | ✓ | — |
| Private keys (RSA/DSA/EC/OPENSSH/PGP) | ✓ | — |
| HTML komentarze z credentials/TODO/FIXME | ✓ | — |
| Internal IPv4 (RFC 1918, 169.254 link-local) | ✓ | — |
| Internal hostnames (.local/.internal/.corp/.dev) | ✓ | — |
| Source map references (sourceMappingURL) | ✓ | — |
| Meta generator (CMS/framework version) | ✓ | — |
| Stack trace fragments | ✓ | — |
| Filesystem path disclosure | ✓ | — |
| React DevTools / Webpack / Next.js debug markers | ✓ | — |
| Deep JS bundle scan (lazy chunks) | — | wymaga TruffleHog/headless |
| OAuth client_id leak in mobile binaries | — | mobile-side test |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (7 kroków)

1. **Pull main page**: GET / + Save full HTML + każdy load referowany JS/CSS.
2. **Static regex scan**: TruffleHog/GitLeaks/manual regex (z naszego Nuclei) na zebranej zawartości.
3. **JS bundles deep dive**: dla każdego `.js`, `linkfinder.py` ekstraktuje endpointy; `JSScanner` pasywny scan przez Burp.
4. **Source map mining**: jeśli `.map` istnieje, pobrać i odzyskać oryginalny kod (`unwebpack-sourcemap`, `sourcemap-explorer`). Komentarze, nazwy zmiennych = goldmine.
5. **HTML comment harvesting**: `grep -E "<!--.*?(TODO|FIXME|HACK|XXX|password|api[_-]key|token|credential)"`
6. **Meta tag analysis**: `<meta name="generator">`, `<meta name="application-name">`, `<meta name="csrf-token">`.
7. **Differential test**: porównanie odpowiedzi anonymous vs authenticated — często JS `config` ma więcej kluczy gdy zalogowany.

### Co MUSI być sprawdzone (12 punktów)

- [ ] AWS Access Key ID (`AKIA[0-9A-Z]{16}`, `ASIA[0-9A-Z]{16}`)
- [ ] AWS Secret Access Key (40-char base64-like) — szukać w pobliżu `aws_secret`
- [ ] Google API Key (`AIza...`) — szukać w JS i HTML
- [ ] GitHub PAT/OAuth (`gh[pousr]_[A-Za-z0-9]{36,}`)
- [ ] Stripe key (`sk_(test|live)_...`, `pk_(test|live)_...`)
- [ ] Slack Webhook URL (`hooks.slack.com/services/...`)
- [ ] JWT tokens leaked w URL/HTML/JS
- [ ] Private keys (`-----BEGIN ... PRIVATE KEY-----`)
- [ ] Source map files (`.js.map`) — pobrać i zdekompilować
- [ ] HTML komentarze z TODO/FIXME/HACK + credentials/email/internal info
- [ ] Internal IP (10.x, 172.16-31, 192.168, 169.254 metadata)
- [ ] Stack traces / file paths w błędach 4xx/5xx

### Per stack — kluczowe różnice

| Stack | Charakterystyczny wyciek | Sposób wykrycia |
|---|---|---|
| React + Webpack | Komentarze `// TODO`, hardcoded API URL w `process.env.REACT_APP_*` | `grep "REACT_APP_" main.*.js` |
| Vue + Vite | `import.meta.env.VITE_*` w bundle | `grep "VITE_" assets/*.js` |
| Next.js | `__NEXT_DATA__` w HTML zawiera initial props i czasem secret config | parse JSON z `<script id="__NEXT_DATA__">` |
| Angular | `environment.prod.ts` często bundled - serwery API endpoints | `grep "apiUrl" *.js` |
| Laravel | `Mix-Manifest`, `app.js` z hardcoded URL | `grep "manifest.json" *.js` |
| WordPress | `wp_localize_script` wstrzykuje `<script>var foo = {ajaxUrl:..., nonce:...}` | parse `wp_*` w HTML |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Secrets_Management_Cheat_Sheet.md

### Wycieki informacji — co szukać

| Typ wycieku | Gdzie szukać | Przykład |
|------------|-------------|---------|
| Klucze API | Pliki JS, komentarze HTML | `apiKey: "AIzaSy..."`, `aws_access_key_id` |
| Wewnętrzne IP | Komentarze, nagłówki, JS | `10.0.0.x`, `192.168.x.x`, `172.16.x.x` |
| Adresy email | Komentarze, meta tagi | `dev@company.com`, `admin@internal.com` |
| Ścieżki plików | Stack traces, komentarze | `/var/www/html/`, `C:\inetpub\wwwroot\` |
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

- Pliki `.js.map` zawierają **oryginalny kod źródłowy** (przed minifikacją/bundlowaniem)
- Sprawdź: `//# sourceMappingURL=app.js.map` na końcu plików JS
- Ujawniają: nazwy zmiennych, komentarze, structure kodu, nazwy plików
- **Obrona**: nie deployuj source map na produkcję, lub ogranicz dostęp (403)

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

- **Nigdy nie hardcoduj** kluczy API, haseł, tokenów w kodzie frontendowym
- Użyj zmiennych środowiskowych lub secrets management (Vault, AWS Secrets Manager)
- Dodaj pre-commit hooks z narzędziem `truffleHog` lub `git-secrets` aby blokować commity z secretami
- Nie deployuj source map na produkcję
- Usuwaj komentarze debugowe przed deploymentem (build pipeline)
- Użyj CSP aby ograniczyć do jakich domen JS może się komunikować

## Pentesterskie deep dive

### Mniej znane techniki

- **Webpack source map deobfuscation**: `unwebpack-sourcemap` rekonstruuje katalog `src/` z `.map`. Jeśli source maps obecne, masz pełny kod aplikacji włącznie z komentarzami i `.env`-like config bundled.
- **AWS metadata via JS injection**: jeśli aplikacja ma SSRF, `http://169.254.169.254/latest/meta-data/` w JS (przez `fetch`) wyciąga IAM credentials — patrz INPV-19. Tu wykrywamy "leakage" gdy URL już jest w body.
- **Differential JS analysis**: różnice między `app.js` na produkcji a starszej wersji z Wayback Machine ujawniają zmiany w API. Czasem stare endpointy wciąż działają.
- **DOM XSS marker via comments**: `<!-- DEBUG: setHTML($input) -->` to bezpośredni wskaźnik DOM XSS — testować przez DOM Invader (Burp).
- **Algolia/Elastic public APIs**: `algolia_app_id` + `algolia_api_key` z search-only privileges są często bundled w JS dla search functionality. Search-only z `validUntil` field może być eskalowany do admin (HackTricks Algolia).
- **Mapbox/Stripe public keys NIE są zagrożeniem**: kluczowe rozróżnienie — Mapbox `pk.eyJ...` i Stripe `pk_live_*` są DESIGNED do public exposure. False positive w skanerach.

### Common pitfalls

- **Skanery tagują UUIDy jako AWS keys**: `12345678-1234-1234-1234-123456789012` może mieć 16 wielkich znaków alfa-num jak AKIA pattern. Wymaga manual triage.
- **Stripe `pk_live_*` to FAŁSZYWY pozytyw bezpieczeństwa**: Stripe publishable key z założenia public. Tylko `sk_*` to true secret.
- **CSP nonce jako "leak"**: wartość `nonce="..."` w `<script>` to per-request unique ID, nie sekret. Skanery często flagują niepotrzebnie.
- **Hardcoded internal hostname false positives**: nazwa `.test`, `.local` w komentarzu może być przykładem dokumentacji, nie real internal infra.
- **Source maps z 403 Forbidden a faktycznie istnieją**: skaner zobaczy 403 ale plik dostępny przez direct curl z proper Referer. Worth retry.

### Świeżynki z research

- **JWT secret extraction via reused HS256 keys** — gdy aplikacja używa HS256 z hardcoded secret w JS bundle, atakujący wyciąga secret i forguje tokeny.
- **`__NEXT_DATA__` server-side props leakage** — patterns z research: Next.js bundlu props initial state w HTML; jeśli zwraca authenticated user data anonymously = info disclosure.
- **CDN cache shadowing JS bundles** — różne JS bundles per użytkownik mogą być cached cross-user (Cache Deception, PortSwigger research).
- **Mass-deploy `.git/` + `.env` exposure** — community reports na GitHub: hundred-thousand of CDN-serwowanych Laravel/.env exposed.
- **PortSwigger Web Cache Deception**: https://portswigger.net/web-security/web-cache-deception
- **HackTricks Hidden Parameters & Information Disclosure**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web
- **TruffleHog (open-source secret scanner)**: https://github.com/trufflesecurity/trufflehog
- **GitLeaks**: https://github.com/gitleaks/gitleaks

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| JS Link Finder | Pasywne wyciąganie endpointów z plików JS | [GitHub](https://github.com/InitRoot/BurpJSLinkFinder) |
| Reflector | Wykrywanie miejsc gdzie input jest reflectowany | [GitHub](https://github.com/elkokc/reflector) |
| Software Version Reporter | Pasywne wykrywanie wersji w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Hackvertor | Decode/encode + JWT inspection | [GitHub](https://github.com/PortSwigger/hackvertor) |
| Secret Finder | Wyszukiwanie sekretów w JS i HTML | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/05-Review_Web_Page_Content_for_Information_Leakage
- OWASP Cheat Sheet — Secrets Management: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- HackTricks Information Disclosure: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web
- TruffleHog: https://github.com/trufflesecurity/trufflehog
- GitLeaks: https://github.com/gitleaks/gitleaks
- LinkFinder: https://github.com/GerbenJavado/LinkFinder
- PayloadsAllTheThings — API Key Leaks: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/API%20Key%20Leaks

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.5 | Information Leakage (L2) | Documentation and monitoring endpoints not exposed unless intended. |
| V14.3.2 | Configuration Hardening (L2) | Web/application server, framework, and components configured securely. |
| V8.2.2 | Sensitive Data (L1) | Sensitive data not stored in browser localStorage / sessionStorage. |
