# WSTG-CLNT-13 — Testing for Cross Site Script Inclusion (XSSI)

## Cel

Wykrycie endpointów zwracających JavaScript / JSON które są loadable cross-origin przez `<script src="...">`. Sensitive data w response = atakujący na evil.com kradnie przez global function override / prototype pollution.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-13-xssi.yaml
```

Wykrywa: naked JSON array (XSSI classic), JSONP callback pattern, JSON bez anti-XSSI prefix, global variable z sensitive data, JS function returning sensitive.

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Naked JSON array | ✓ | — |
| JSONP callback pattern | ✓ | — |
| JSON bez anti-XSSI prefix `)]}'`/`while(1);` | ✓ | — |
| Global var z sensitive data w JS | ✓ | — |
| Static JS files z sensitive embedded | ✓ | — |
| Dynamic CSRF context (per-request token leak) | częściowe | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **JS endpoints discovery**: aplikacja zwraca `Content-Type: application/javascript` lub `text/javascript`.
2. **JSONP search**: paramy `?callback=`, `?jsonp=`, `?cb=` w API.
3. **Cross-origin load test**: stwórz HTML page z `<script src="https://target.com/api/data?callback=callback">` na evil.com.
4. **Sensitive data check**: czy response zawiera user info, tokeny, CSRF?
5. **Defense audit**: anti-XSSI prefix (`)]}'\n` Google-style), Content-Type validation, CORS+credentials.

### Co MUSI być sprawdzone (8 punktów)

- [ ] Wszystkie endpoints zwracające JSON/JS
- [ ] JSONP endpoints (callback parameters)
- [ ] Static JS files z embedded sensitive data
- [ ] Anti-XSSI prefix obecny? (`)]}'\n`, `while(1);`, `for(;;);`)
- [ ] Content-Type: application/json (NIE javascript)
- [ ] CORS + credentials check
- [ ] CSRF token w JSON response (nie w URL/path)
- [ ] SameSite cookies ograniczają cookies w cross-origin script load

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md

### Cross-Site Script Inclusion (XSSI) — czym jest

- Atakujący importuje skrypt/JSONP z TARGET na swojej stronie: `<script src="TARGET/api/data?callback=steal">`
- Przeglądarka automatycznie dołącza cookies ofiary → dane wraca do strony atakującego
- Różnica od XSS: atakujący NIE wstrzykuje kodu do TARGET — importuje dane Z TARGET

### JSONP — ryzyka

- JSONP wraca dane jako `callback({...})` — przeglądarka wykonuje jako JavaScript
- Atakujący definiuje `callback` na swojej stronie — odczytuje dane ofiary
- **Obrona**: nie używaj JSONP — migruj na CORS z `Access-Control-Allow-Origin`

### Obrona przed XSSI

- **Nie zwracaj wrażliwych danych** w JSONP/dynamic JS — używaj JSON + CORS
- **Waliduj Referer/Origin** header — odrzuć requesty z nieznanych domen
- **CSRF token** w parametrze — JSONP request bez tokenu = odrzucony
- **Content-Type**: `application/json` (nie `text/javascript`) — zapobiega importowaniu przez `<script>`
- **SameSite cookies**: `Lax` lub `Strict` — cookie nie będzie dołączane w cross-site `<script>` request
- **JSON prefix**: dodaj `)]}'` lub `while(1);` przed JSON — zapobiega direct execution

### Testowanie

- Szukaj JSONP endpointów: `callback=`, `jsonp=`, `cb=` parametry
- Stwórz PoC: `<script>function callback(data){alert(JSON.stringify(data))}</script><script src="TARGET/api?callback=callback"></script>`
- Sprawdź czy odpowiedź zawiera wrażliwe dane (PII, tokeny, dane użytkownika)

## Pentesterskie deep dive

### Mniej znane techniki

- **JSON Hijacking via Array constructor (legacy IE)**: starsze IE z overridden `Array` constructor mogły leak `[1,2,3]` data. Modern browsers immune.
- **Global object pollution via JSON props**: `<script>` execution z `{user:"admin"}` → niektóre browsers tworzyły global `user` variable. Modern browsers immune.
- **Charset confusion XSSI**: response `text/javascript; charset=utf-7` może omijać niektóre parsers — bypass anti-XSSI.
- **Dynamic chunked JS**: aplikacja serwująca JS chunks per route (Webpack code splitting) - per-route może być sensitive.

### Common pitfalls

- **Anti-XSSI prefix wyłączony "for performance"**: wyłączenie `)]}'\n` żeby zaoszczędzić bytes = open XSSI.
- **CSRF token w GET response**: jeśli token jest in JSON response z GET endpoint, JSONP scenarios mogą leak.

### Świeżynki z research

- **HackTricks XSSI**: https://book.hacktricks.xyz/pentesting-web/xssi-cross-site-script-inclusion
- **PortSwigger Cross Site Script Inclusion**: research publications

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| JS Link Finder | Endpoint discovery z JS | [GitHub](https://github.com/InitRoot/BurpJSLinkFinder) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/13-Testing_for_Cross_Site_Script_Inclusion
- OWASP CSRF Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
- HackTricks XSSI: https://book.hacktricks.xyz/pentesting-web/xssi-cross-site-script-inclusion

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.2.5 | RESTful (L2) | Anti-XSSI prefix on JSON responses. |
| V14.5.3 | Configuration (L1) | CORS uses explicit list. |
