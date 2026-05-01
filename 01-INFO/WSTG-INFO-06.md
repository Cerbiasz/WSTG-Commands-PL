# WSTG-INFO-06 — Identify Application Entry Points

## Cel

Identyfikacja wszystkich punktów wejścia danych do aplikacji: URL parametry, ciało żądania, nagłówki, cookies, pliki upload, WebSocket, GraphQL queries. Mapa entry pointów napędza wszystkie testy INPV — bez kompletnej mapy fuzzing pomija powierzchnię ataku.

> **Test manual-heavy**: brak dedykowanego szablonu Nuclei — entry pointy najlepiej zbierać przez przechodzenie aplikacji w Burp Proxy. Hidden parameter discovery (Arjun, Param Miner) automatyzowalne ale wymaga interakcji z aplikacją w sposób kontekstowy.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (8 kroków)

1. **Manual walkthrough w Burp**: kliknij każdą funkcję aplikacji jako użytkownik, wszystkie żądania trafiają do Burp Site Map. To kompletność bazowa.
2. **Burp Spider/Crawler**: uzupełnia walkthrough — odkrywa linki niewidoczne w manualnym przejściu (carousel, lazy load).
3. **JS LinkFinder pull**: dla każdego pliku JS ekstraktuj endpointy (`linkfinder.py`, Burp JS Link Finder).
4. **Hidden parameter discovery**: `arjun -u target.com/api/x` lub Burp Param Miner na każdym endpoincie.
5. **GraphQL introspection**: `?query={__schema{...}}` jeśli endpoint istnieje — full schema.
6. **Wayback enumeration**: `gau target.com | grep "?"` — historyczne URL z parametrami.
7. **Header fuzzing**: testować custom headers (`X-Forwarded-For`, `X-Original-URL`, `X-Rewrite-URL`) na każdym endpoincie.
8. **WebSocket capture**: Burp WebSockets History — często ignorowane, a interesujące injekcyjnie.

### Co MUSI być sprawdzone (15 punktów)

- [ ] Pełny crawl Burp + manual walkthrough
- [ ] LinkFinder na każdym JS bundle
- [ ] Hidden parameter discovery na każdym endpoincie (Arjun lub Param Miner)
- [ ] GraphQL introspection jeśli `/graphql` istnieje
- [ ] Wayback URLs porównane z aktualnym crawlem
- [ ] Wszystkie metody HTTP testowane per endpoint (`OPTIONS`, `PUT`, `DELETE`, `PATCH`)
- [ ] Każdy parametr: typ, długość, encoding (URL/Base64/JSON/XML)
- [ ] Cookies — flagi (HttpOnly/Secure/SameSite), zawartość
- [ ] Hidden form fields (`<input type=hidden>`)
- [ ] Custom headers akceptowane (`X-Custom-Auth`, `X-User-Role`, `X-Original-URL`)
- [ ] WebSocket endpointy + wiadomości
- [ ] File upload endpointy + dozwolone typy
- [ ] Race condition windows (multi-step transactions)
- [ ] Authenticated vs anonymous endpoints (różnice w params/responses)
- [ ] Internal-only endpoints accessible przez header bypass

### Per stack — gdzie szukać entry pointów

| Stack | Lokalizacja | Sztuczka |
|---|---|---|
| REST API | `/api/v*/...` | OpenAPI/Swagger spec to złoto |
| GraphQL | `/graphql`, `/api/graphql` | Introspection query lub `__schema` |
| SOAP | `?wsdl` | WSDL ujawnia wszystkie operacje |
| RPC | `/rpc`, `/jsonrpc` | Methods enumeration via `system.listMethods` (XML-RPC) |
| Server Components (Next.js, Remix) | inline w HTML | Server-only funkcje są dostępne via routing |
| Express/Koa | dynamic routes | Brak spec - manual via JS analysis |
| Spring Boot | `/actuator/mappings` | Pełna lista routes (gdy actuator open) |
| Django | `/admin/`, `urls.py` patterns | DEBUG=True zwraca routes w 404 |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Entry points — kategoryzacja

| Typ entry point | Przykłady | Potencjalne ataki |
|----------------|-----------|------------------|
| URL parametry (GET) | `?id=1&search=test` | SQLi, XSS, IDOR, LFI |
| Body parametry (POST) | Formularze, JSON, XML | SQLi, XSS, XXE, command injection |
| HTTP nagłówki | `Cookie`, `Referer`, `User-Agent`, `X-Forwarded-For` | Header injection, log injection, SSRF |
| Cookies | Session ID, preferencje | Session hijacking, parameter tampering |
| Pliki (upload) | Obrazy, dokumenty, archiwa | RCE, XSS, path traversal |
| URL ścieżka | `/api/users/123` | IDOR, path traversal |
| WebSocket | Wiadomości WS | Injection, CSWSH |

### Ukryte parametry — jak je znaleźć

- **Arjun**: automatyczne odkrywanie ukrytych parametrów HTTP (GET, POST, JSON)
- **ParamSpider**: zbieranie parametrów z historycznych URL-ów (Wayback Machine)
- **Burp Intruder**: fuzzowanie parametrów z wordlistą `burp-parameter-names.txt`
- **Analiza JS**: LinkFinder, JSParser — endpointy i parametry w kodzie JavaScript
- **Hidden fields**: `<input type="hidden">` w formularzach — często brak walidacji server-side

### Mapowanie parametrów — checklist

Dla każdego entry point dokumentuj:
1. **Nazwa parametru** i lokalizacja (GET, POST, cookie, header)
2. **Typ danych** — string, integer, boolean, date, file
3. **Ograniczenia** — długość, dozwolone znaki, zakres wartości
4. **Walidacja** — client-side only? server-side?
5. **Wpływ** — co kontroluje ten parametr (logika biznesowa, dostęp, wyświetlanie)
6. **Encoding** — URL encoding, Base64, JSON, XML

### Analiza request/response — na co zwrócić uwagę

- **Parametry w URL** które kontrolują dostęp: `role=`, `admin=`, `debug=`
- **Hidden fields** z wartościami które można manipulować: `price`, `discount`, `user_id`
- **Cookies** bez flag Secure/HttpOnly — potential hijacking
- **Custom headers** akceptowane przez aplikację: `X-Custom-Auth`, `X-User-Role`
- **Różne odpowiedzi** na różne wartości tego samego parametru — wskazują na logikę

### Obrona

- Waliduj WSZYSTKIE dane wejściowe server-side — nigdy nie ufaj client-side validation
- Użyj allowlist (whitelist) zamiast denylist (blacklist) dla walidacji
- Implementuj walidację na granicy systemu: API gateway, controller, middleware
- Nie akceptuj nieznanych parametrów — strict parameter binding
- Loguj niestandardowe parametry w requestach — mogą wskazywać na probe ataku

## Pentesterskie deep dive

### Mniej znane techniki

- **HTTP method override**: niektóre frameworki (Laravel, Symfony) honorują `_method=DELETE` jako parametr POST → bypass WAF który filtruje DELETE method.
- **JSON parameter pollution**: `{"id":1,"id":2}` — JSON parser zwykle bierze ostatnią wartość, ale niektóre middleware bierze pierwszą. Bypass walidacji.
- **Header smuggling przez `X-Original-URL`/`X-Rewrite-URL`**: aplikacja sprawdza ścieżkę z URL, ale routing używa header value → bypass auth (PortSwigger HTTP Smuggling).
- **GraphQL aliases enumeration**: `query{a:user(id:1){name},b:user(id:2){name}}` — odkrywa internal fields nawet gdy introspection wyłączone.
- **Server-Sent Events (SSE)**: endpointy `/events`, `/sse`, `/stream` — często ignorowane przez skanery, ale są entry pointami danych z server-side.
- **WebSocket subprotocol negotiation**: `Sec-WebSocket-Protocol` może akceptować różne subprotocols, każdy z innym handlerem (różne entry points).

### Common pitfalls

- **Burp Spider nie kliknie WebSocket**: WebSocket history wymaga manual lub osobnego narzędzia (Burp WebSocket Test).
- **Single Page Apps i deep linking**: SPA routing client-side; Burp może nie wyzwolić wszystkich routes. Manual walkthrough niezbędny.
- **Authenticated content invisible bez sesji**: skaner anonymous nie zobaczy `/dashboard/admin` — testy MUSZĄ być uruchomione również z auth.
- **Optional parameters changing behavior**: `?debug=1`, `?test=true`, `?internal=1` często aktywują dev mode bez auth — testować zawsze.
- **Multipart/form-data parameter ordering**: PHP `$_POST` może override przez ostatni parametr o tej samej nazwie. JSON parser bierze pierwszy. Bypass walidacji.

### Świeżynki z research

- **HTTP Smuggling Reborn (James Kettle, PortSwigger)** — pattern: HTTP/2 → HTTP/1 conversion ujawnia hidden internal endpoints; każda smuggled request to nowy entry point.
- **Connection-state attacks** — hidden behavior gdy connection reused (PortSwigger Research, Browser-Powered Desync Attacks).
- **Hidden parameter discovery via cache poisoning** — Param Miner używa cache differential do detekcji nieudokumentowanych params.
- **GraphQL Field Suggestions** — `__schema` może być wyłączone, ale `query{user(id:1){nonexistent}}` zwraca podpowiedzi z lookalike fields (community pattern).
- **PortSwigger Web Security Academy — Authentication & Access**: https://portswigger.net/web-security
- **HackTricks Hidden Parameters**: https://book.hacktricks.xyz/pentesting-web/parameter-pollution

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| GAP-Burp-Extension | Automatyczne wyciąganie parametrów, endpointów, słów | [GitHub](https://github.com/xnl-h4ck3r/GAP-Burp-Extension) |
| Param Miner | Discovery hidden parameters + cache poisoning | [GitHub](https://github.com/PortSwigger/param-miner) |
| Autorize | Detekcja problemów autoryzacji - testuje endpointy z dwóch perspektyw | [GitHub](https://github.com/Quitten/Autorize) |
| JS Link Finder | Pasywne wyciąganie endpointów z JS | [GitHub](https://github.com/InitRoot/BurpJSLinkFinder) |
| WebSocket Test | Discovery i fuzzing WebSocket endpointów | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/06-Identify_Application_Entry_Points
- OWASP Cheat Sheet — Input Validation: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- HackTricks Parameter Pollution: https://book.hacktricks.xyz/pentesting-web/parameter-pollution
- PortSwigger Web Security Academy: https://portswigger.net/web-security
- Arjun (hidden parameter discovery): https://github.com/s0md3v/Arjun
- ParamSpider: https://github.com/devanshbatham/ParamSpider
- LinkFinder: https://github.com/GerbenJavado/LinkFinder

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.1.1 | Input Validation (L1) | Application has defenses against HTTP parameter pollution attacks. |
| V5.1.3 | Input Validation (L1) | All input is validated using positive validation (allow lists). |
| V13.2.1 | RESTful Web Services (L1) | Enabled HTTP methods are documented and appropriate. |
