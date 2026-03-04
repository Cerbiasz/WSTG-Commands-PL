# WSTG-CONF-08 — Test RIA Cross Domain Policy

## Cele

- Review cross-domain policy files (crossdomain.xml, clientaccesspolicy.xml)
- Identify overly permissive cross-domain policies
- Assess CORS configuration

## KOMENDY

### Sprawdzenie crossdomain.xml (Flash/Adobe)

```bash
curl -s https://TARGET/crossdomain.xml | tee output_crossdomain.xml
curl -s http://TARGET/crossdomain.xml | tee output_crossdomain_http.xml

```

### Sprawdzenie clientaccesspolicy.xml (Silverlight)

```bash
curl -s https://TARGET/clientaccesspolicy.xml | tee output_clientaccesspolicy.xml

```

### Sprawdzenie CORS headers

```bash
curl -sI https://TARGET -H "Origin: https://evil.com" | grep -iE "^Access-Control" | tee output_cors.txt
curl -sI https://TARGET -H "Origin: https://evil.com" -H "Access-Control-Request-Method: POST" | grep -iE "^Access-Control" | tee output_cors_preflight.txt

```

### Testowanie roznych origin w CORS

```bash
curl -sI https://TARGET -H "Origin: null" | grep -iE "^Access-Control"
curl -sI https://TARGET -H "Origin: https://TARGET.evil.com" | grep -iE "^Access-Control"
curl -sI https://TARGET -H "Origin: https://eviltarget.com" | grep -iE "^Access-Control"
curl -sI https://TARGET -H "Origin: https://subdomain.TARGET" | grep -iE "^Access-Control"

```

### Sprawdzenie Access-Control-Allow-Credentials

```bash
curl -sI https://TARGET -H "Origin: https://evil.com" | grep -i "Access-Control-Allow-Credentials"
# NIEBEZPIECZNE: Allow-Credentials: true + Allow-Origin: https://evil.com

```

### Sprawdzenie wildcard CORS

```bash
curl -sI https://TARGET -H "Origin: https://anything.com" | grep -i "Access-Control-Allow-Origin"
# NIEBEZPIECZNE: Access-Control-Allow-Origin: *

```

### Sprawdzenie na roznych endpointach

```bash
curl -sI https://TARGET/api/ -H "Origin: https://evil.com" | grep -iE "^Access-Control"
curl -sI https://TARGET/api/v1/ -H "Origin: https://evil.com" | grep -iE "^Access-Control"

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - test polega na analizie plikow polityk cross-domain

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz https://TARGET/crossdomain.xml - szukaj allow-access-from domain="*"
2. Sprawdz https://TARGET/clientaccesspolicy.xml
3. W Burp Suite: dodaj naglowek Origin: https://evil.com i sprawdz odpowiedz CORS
4. Sprawdz czy Access-Control-Allow-Origin odbija dowolny Origin
5. Zweryfikuj czy Access-Control-Allow-Credentials: true nie jest polaczone z wildcard
6. Sprawdz CORS na endpointach API
7. Przetestuj CORS bypass: subdomena, null origin, regex bypass
8. W DevTools > Console: sprobuj fetch() z innej domeny do TARGET

