# WSTG-CLNT-04 — Testing for Client-side URL Redirect

## Cel

Wykrycie open redirect — server-side (302 z reflected URL) lub client-side (`window.location = userInput`). Pivot do phishing (zaufana domena → evil), OAuth attacks (kradzież authorization code), SSRF (jeśli internal URL akceptowany).

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-04-url-redirect.yaml
```

Szablon fuzzuje typowe redirect parameter names (`redirect`, `url`, `next`, `return`, `goto`, `callback`) ze szerokim zestawem bypass payloads (//, @, backslash, encoding, schema bypass). Detekcja: Location header z attacker host.

### Cross-reference

```bash
# DOM XSS markers - client-side window.location patterns
nuclei -l burp-export.xml -im burp -t templates/wstg-clnt-01-dom-xss.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Server-side redirect (Location header) | ✓ | — |
| URL parser confusion bypass (`@`, `//`, `\\`) | ✓ | — |
| Schema bypass (`javascript:`, `data:`) | ✓ | — |
| URL encoding bypass | ✓ | — |
| Whitespace bypass | ✓ | — |
| Client-side redirect (window.location) | częściowe | wymaga DOM Invader |
| Whitelisted domain bypass | — | wymaga subdomain takeover analysis |
| Numeric ID-based redirect | — | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify redirect endpoints**: szukać paths typu `/redirect`, `/login` (po success), `/logout` (po success).
2. **Common param names**: `?url=`, `?next=`, `?return=`, `?continue=`, `?goto=` — fuzz z evil URL.
3. **Bypass techniques**: `//evil.com`, `https://target.com@evil.com`, `https://target.com.evil.com`.
4. **OAuth flow**: `redirect_uri=` na OAuth endpointach — często mają whitelisted domains.
5. **Client-side check**: w JS bundle szukać `window.location.href = ...` z user input.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Wszystkie redirect param names testowane evil URL
- [ ] OAuth `redirect_uri` flexibility
- [ ] Login redirect (po success → user-controlled URL?)
- [ ] Logout redirect
- [ ] Email confirmation links (?next=)
- [ ] Schema bypass (javascript:, data:)
- [ ] @ bypass (`https://target.com@evil.com`)
- [ ] // protocol-relative
- [ ] Encoding bypass (%2f%2f, %5c%5c)
- [ ] Client-side `window.location` patterns w JS

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Unvalidated_Redirects_and_Forwards_Cheat_Sheet.md

### Open Redirect — ryzyka

- **Phishing**: atakujący wysyła link `trusted.com/redirect?url=evil.com` — ofiara ufa domenie
- **OAuth token theft**: redirect_uri → atakujący kradnie authorization code
- **SSO bypass**: redirect po logowaniu do strony atakującego
- **Chaining**: open redirect + SSRF, open redirect + XSS

### Obrona — hierarchia

1. **Unikaj user input w URL przekierowań** — najlepsza obrona
2. **Mapping IDs**: zamiast `?url=https://...` używaj `?id=1` → mapuj do dozwolonych URL
3. **Allowlist domen**: jawna lista dozwolonych domen do przekierowania
4. **Walidacja URL server-side**: sprawdź scheme (tylko https), host (tylko zaufane domeny)

### Typowe bypass techniki (testowanie)

- `//evil.com` — protocol-relative URL, przeglądarka uzupełnia protokół
- `/\evil.com` — backslash jako separator
- `/%09/evil.com` — tab character bypass
- `https://trusted.com@evil.com` — userinfo w URL (user=trusted.com, host=evil.com)
- `https://evil.com#trusted.com` — fragment jako dezorientacja
- `data:text/html,<script>` — data URI scheme
- `javascript:alert(1)` — JavaScript pseudo-protocol

### Client-Side Redirect (DOM-based)

- JavaScript: `location.href = userInput`, `location.assign()`, `location.replace()`
- Waliduj URL PRZED przypisaniem do location — sprawdź czy zaczyna się od `/` (relative) lub zaufanej domeny
- NIGDY nie przypisuj user input bezpośrednio do `location.*`

### Walidacja URL — bezpieczna implementacja

- Parsuj URL (np. `new URL(input)`) — sprawdź `.hostname` przeciw allowlist
- Odrzuć: `javascript:`, `data:`, `vbscript:` schemes
- Sprawdź że URL jest absolute i zaczyna się od `https://`
- Używaj server-side walidacji — client-side można ominąć

## Pentesterskie deep dive

### Mniej znane techniki

- **Subdomain takeover + whitelist**: aplikacja whitelisty `*.target.com` → atakujący przejmuje `wycofana.target.com` → legit redirect.
- **OAuth state confusion**: open redirect na callback URL po OAuth → atakujący steal authorization code z URL fragment.
- **DNS rebinding**: redirect do attacker-controlled domain z short TTL → po pierwszym fetch zmienia rekord na internal IP = SSRF.
- **Triple-slash URL**: `///evil.com` traktowane różnie przez parsers — czasami jako `evil.com`, czasem jako relative path.
- **Userinfo + path bypass**: `https://target.com\\@evil.com/path` — różne URL parsers traktują różnie (depends on Standard).

### Common pitfalls

- **Whitelist sprawdza hostname startswith**: `target.com` matches `target.com.evil.com` → bypass.
- **Whitelist sprawdza endsWith**: `target.com` matches `evil.target.com` ALE też `eviltarget.com` (bez kropki).
- **Server-side validation OK, client-side weak**: server validates ale client-side JS akceptuje user input → DOM XSS via redirect.

### Świeżynki z research

- **Sam Curry OAuth research**: https://samcurry.net/
- **PortSwigger OAuth labs**: https://portswigger.net/web-security/oauth
- **HackTricks Open Redirect**: https://book.hacktricks.xyz/pentesting-web/open-redirect

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Reflector | Detekcja reflected user input | [GitHub](https://github.com/elkokc/reflector) |
| Param Miner | Hidden parameter discovery | [GitHub](https://github.com/PortSwigger/param-miner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/04-Testing_for_Client-side_URL_Redirect
- OWASP Unvalidated Redirects CS: https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html
- PortSwigger OAuth: https://portswigger.net/web-security/oauth
- HackTricks Open Redirect: https://book.hacktricks.xyz/pentesting-web/open-redirect

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.1.5 | Input Validation (L1) | URL redirects only allow whitelisted destinations. |
| V13.2.1 | RESTful (L1) | Documented HTTP methods. |
