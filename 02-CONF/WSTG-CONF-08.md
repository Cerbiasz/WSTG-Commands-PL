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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md, REST_Security_Cheat_Sheet.md

### Cross-domain policy — niebezpieczne konfiguracje

| Konfiguracja | Ryzyko | Poprawna wersja |
|-------------|--------|-----------------|
| `allow-access-from domain="*"` | Dowolna domena moze czytac dane | Ogranicz do konkretnych domen |
| `<allow-http-request-headers-from domain="*">` | Dowolne naglowki z dowolnej domeny | Tylko zaufane domeny |
| `Access-Control-Allow-Origin: *` + credentials | Nie dziala w przegladarce, ale swiadczy o zlej konfiguracji | Konkretna domena, nie wildcard |
| Reflected Origin w ACAO | Atakujacy moze czytac dane ofiary | Whitelist dozwolonych origin |
| `Access-Control-Allow-Origin: null` | Bypass przez iframe sandbox | Nie akceptuj null origin |

### CORS — poprawna konfiguracja

- **Whitelist origin**: sprawdzaj Origin z lista dozwolonych domen — nie odbijaj dynamicznie
- **Credentials**: `Access-Control-Allow-Credentials: true` wymaga konkretnego origin (nie `*`)
- **Metody**: ogranicz `Access-Control-Allow-Methods` do potrzebnych (GET, POST)
- **Naglowki**: ogranicz `Access-Control-Allow-Headers` do minimum
- **Max-Age**: ustaw `Access-Control-Max-Age` aby zmniejszyc preflight requests
- **Expose-Headers**: nie ujawniaj wrazliwych naglowkow

### crossdomain.xml (Flash) — status

- Flash Player oficjalnie wycofany (EOL grudzien 2020)
- Pliki `crossdomain.xml` nadal moga istniec na serwerach — usun je
- Jesli konieczny dla legacy: `allow-access-from domain="specific.domain.com"`, **nigdy** `domain="*"`

### clientaccesspolicy.xml (Silverlight) — status

- Silverlight oficjalnie wycofany (EOL pazdziernik 2021)
- Usun pliki `clientaccesspolicy.xml` z serwerow produkcyjnych
- Legacy Silverlight apps powinny byc zmigrowane

### Testowanie CORS — payloady

```
Origin: https://evil.com                    # Podstawowy test
Origin: null                                # Iframe sandbox bypass
Origin: https://target.com.evil.com         # Subdomena atakujacego
Origin: https://eviltarget.com              # Suffix match bypass
Origin: https://target.com%60.evil.com      # Backtick bypass
Origin: https://sub.target.com              # Subdomena target
```

### Obrona

- Usun `crossdomain.xml` i `clientaccesspolicy.xml` jesli nie sa potrzebne
- Implementuj CORS whitelist na serwerze — nie odbijaj Origin dynamicznie
- Nie laczkuj `Allow-Credentials: true` z luznymi origin rules
- Testuj CORS na kazdym endpoincie API osobno — konfiguracja moze sie roznic
- Uzyj CSP `connect-src` jako dodatkowa warstwe ochrony

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CSP Auditor | Analiza naglowkow Content-Security-Policy | [GitHub](https://github.com/GoSecure/csp-auditor) |
| Headers Analyzer | Analiza naglowkow bezpieczenstwa HTTP | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |
