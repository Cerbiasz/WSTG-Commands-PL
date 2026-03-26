# WSTG-APIT-01 — API Reconnaissance

## Cele

- Find all API endpoints supported by the backend server code
- Find all parameters for each endpoint
- Discover interesting data related to APIs in HTML and JavaScript

## KOMENDY

### Typowe sciezki dokumentacji API

```bash
curl -s "https://TARGET/swagger.json" | head -50
curl -s "https://TARGET/swagger/v1/swagger.json" | head -50
curl -s "https://TARGET/api-docs" | head -50
curl -s "https://TARGET/openapi.json" | head -50
curl -s "https://TARGET/v1/api-docs" | head -50
curl -s "https://TARGET/v2/api-docs" | head -50
curl -s "https://TARGET/.well-known/openapi.yaml" | head -50
curl -s "https://TARGET/swagger-ui.html" | head -50
curl -s "https://TARGET/redoc" | head -50
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { types { name } } }"}'

```

### kiterunner - API endpoint discovery

```bash
kr scan https://TARGET -w /path/to/kiterunner/routes.kite

```

### Ekstrakcja API z JS

```bash
curl -s "https://TARGET/" | grep -oP 'src="[^"]*\.js"' | while read js; do echo "=== $js ==="; curl -s "https://TARGET/$js" | grep -oP '"/api/[^"]*"'; done

```

### GAU + grep API endpoints

```bash
echo TARGET | gau | grep -i "api\|graphql\|v1\|v2\|rest" | sort -u | tee output_api_endpoints.txt

```

### Arjun - parameter discovery

```bash
arjun -u "https://TARGET/api/endpoint" -m GET

```

## KOMENDY Z WORDLISTAMI

### SecLists API wordlists

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/api/api-endpoints.txt -mc 200,301,302,401,403 -o output_ffuf_api.json

```

### Bug-Bounty-Wordlists API

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api.txt -mc 200,301,302,401,403 -o output_ffuf_bbw_api.json

ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api-actions.txt -mc 200 -o output_ffuf_api_actions.json

ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api-objects.txt -mc 200 -o output_ffuf_api_objects.json

ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api_seen_in_wild.txt -mc 200,301,302 -o output_ffuf_api_wild.json

```

### SecLists common paths

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -mc 200,301,302,401 -o output_ffuf_common_api.json

```

### Wordlists-master API

```bash
# Sprawdz: Desktop/WSTG/wordlists-master/data/

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz /swagger, /api-docs, /openapi.json
2. Analizuj kod JS pod katem API endpointow
3. Uzyj Burp Spider i sitemapa do mapowania API
4. Sprawdz rozne wersje API (v1, v2, v3)
5. Testuj rozne metody HTTP na kazdym endpoincie
6. Uzyj Postman/Insomnia do interakcji z API


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — GraphQL_Cheat_Sheet.md, REST_Security_Cheat_Sheet.md

### GraphQL Security

- **Wylacz introspection** na produkcji — nie ujawniaj calego schematu API atakujacemu
- **Query depth limiting**: ogranicz zagnieżdzenie zapytan (np. max 10 levels) — zapobiegaj DoS
- **Query cost analysis**: przypisz koszty do pol i ogranicz calkowity koszt zapytania
- **Persisted queries**: akceptuj TYLKO pre-approved query hashes — eliminuje arbitrary queries
- **Autoryzacja per field/type** — nie tylko na poziomie endpointu, ale na kazdym polu
- **Batch attack prevention**: ogranicz ilosc operacji w jednym batch request
- **Rate limiting** na poziomie zapytan, nie requestow (1 request GraphQL = wiele operacji)

### REST API Security

- **Autentykacja**: OAuth 2.0 + JWT, API keys (TYLKO jako identyfikator, NIE jako jedyna auth)
- **Autoryzacja**: sprawdzaj uprawnienia na KAZDYM endpoincie, KAZDEJ metodzie HTTP
- **Input validation**: waliduj wszystkie parametry — typ, dlugosc, format, zakres
- **Rate limiting**: ogranicz requesty per API key/IP/user — zapobiegaj abuse
- **Wersjonowanie**: utrzymuj bezpieczenstwo WSZYSTKICH aktywnych wersji API (v1, v2, v3)
- **CORS**: `Access-Control-Allow-Origin` — NIE uzywaj `*` z credentials

### API Discovery — co sprawdzic

- `/swagger`, `/swagger-ui`, `/api-docs`, `/openapi.json`, `/graphql` — dokumentacja API
- Starsze wersje API (`/api/v1/`) — czesto bez nowych zabezpieczen
- Hidden endpoints — sprawdz kod JavaScript, mobile app decompilation
- GraphQL introspection: `{ __schema { types { name fields { name } } } }`

### OWASP API Security Top 10

- **API1**: Broken Object Level Authorization (BOLA/IDOR) — sprawdzaj uprawnienia do KAZDEGO obiektu
- **API2**: Broken Authentication — slabe mechanizmy uwierzytelnienia API
- **API3**: Broken Object Property Level Authorization — Mass Assignment, excessive data exposure
- **API4**: Unrestricted Resource Consumption — brak rate limiting, DoS
- **API5**: Broken Function Level Authorization — brak autoryzacji na poziomie funkcji
- **API6**: Unrestricted Access to Sensitive Business Flows — automatyzacja krytycznych operacji
- **API7**: Server Side Request Forgery (SSRF) — API jako proxy do wewnetrznych zasobow
- **API8**: Security Misconfiguration — debug mode, verbose errors, CORS misconfiguration
- **API9**: Improper Inventory Management — shadow API, stare wersje
- **API10**: Unsafe Consumption of APIs — brak walidacji odpowiedzi z third-party API

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| InQL Scanner | Kompleksowe testowanie bezpieczenstwa GraphQL | [GitHub](https://github.com/doyensec/inql) |
| GraphQL Raider | Parsowanie i manipulacja zapytan GraphQL w Burp | [BApp Store](https://portswigger.net/bappstore/4841f0d78a554ca381c65b26d48571e2) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.1.1 | Generic Web Service Security | Verify that every HTTP response with a message body contains a Content-Type header field that matches the actual content of the response, including the charset parameter to specify safe character encoding (e.g., UTF-8, ISO-8859-1) according to IANA Media Types, such as "text/", "/+xml" and "/xml". |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.1.2 | Generic Web Service Security | Verify that only user-facing endpoints (intended for manual web-browser access) automatically redirect from HTTP to HTTPS, while other services or endpoints do not implement transparent redirects. This is to avoid a situation where a client is erroneously sending unencrypted HTTP requests, but since the requests are being automatically redirected to HTTPS, the leakage of sensitive data goes undiscovered. |
| V4.1.3 | Generic Web Service Security | Verify that any HTTP header field used by the application and set by an intermediary layer, such as a load balancer, a web proxy, or a backend-for-frontend service, cannot be overridden by the end-user. Example headers might include X-Real-IP, X-Forwarded-*, or X-User-ID. |
| V13.4.5 | Unintended Information Leakage | Verify that documentation (such as for internal APIs) and monitoring endpoints are not exposed unless explicitly intended. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Unintended Information Leakage | Verify that the application does not expose detailed version information of backend components. |
