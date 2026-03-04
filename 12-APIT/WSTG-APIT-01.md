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

