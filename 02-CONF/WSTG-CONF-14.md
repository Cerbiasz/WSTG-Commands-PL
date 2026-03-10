# WSTG-CONF-14 — Test Other HTTP Security Header Misconfigurations

## Cele

- Identify improperly configured security headers
- Verify presence and correct values of all recommended HTTP security headers
- Find missing headers that leave the application vulnerable

## KOMENDY

### cURL - pobranie wszystkich naglowkow

```bash
curl -sI https://TARGET | tee output_all_headers.txt

```

### Sprawdzenie poszczegolnych naglowkow bezpieczenstwa

```bash

# X-Frame-Options (ochrona przed clickjacking)
curl -sI https://TARGET | grep -i "X-Frame-Options"
# Oczekiwany: DENY lub SAMEORIGIN

# X-Content-Type-Options (ochrona przed MIME sniffing)
curl -sI https://TARGET | grep -i "X-Content-Type-Options"
# Oczekiwany: nosniff

# X-XSS-Protection (filtr XSS w przegladarce - deprecated ale nadal uzywany)
curl -sI https://TARGET | grep -i "X-XSS-Protection"
# Oczekiwany: 0 (wylaczyc - polega na CSP) lub 1; mode=block

# Referrer-Policy (kontrola naglowka Referer)
curl -sI https://TARGET | grep -i "Referrer-Policy"
# Oczekiwany: strict-origin-when-cross-origin lub no-referrer

# Permissions-Policy / Feature-Policy
curl -sI https://TARGET | grep -i "Permissions-Policy"
curl -sI https://TARGET | grep -i "Feature-Policy"
# Oczekiwany: ograniczenie dostepu do API przegladarki

# Cache-Control (zapobieganie cache'owaniu wrazliwych danych)
curl -sI https://TARGET | grep -i "Cache-Control"
# Oczekiwany dla wrazliwych stron: no-store, no-cache, must-revalidate

# Pragma
curl -sI https://TARGET | grep -i "Pragma"

# X-Permitted-Cross-Domain-Policies
curl -sI https://TARGET | grep -i "X-Permitted-Cross-Domain-Policies"

# Cross-Origin-Embedder-Policy
curl -sI https://TARGET | grep -i "Cross-Origin-Embedder-Policy"

# Cross-Origin-Opener-Policy
curl -sI https://TARGET | grep -i "Cross-Origin-Opener-Policy"

# Cross-Origin-Resource-Policy
curl -sI https://TARGET | grep -i "Cross-Origin-Resource-Policy"

```

### Sprawdzenie na roznych endpointach

```bash
curl -sI https://TARGET/login | tee output_headers_login.txt
curl -sI https://TARGET/api/ | tee output_headers_api.txt
curl -sI https://TARGET/dashboard | tee output_headers_dashboard.txt

```

### Nmap - naglowki bezpieczenstwa

```bash
nmap --script http-security-headers -p 80,443 TARGET -oN output_nmap_sec_headers.txt
nmap --script http-headers -p 80,443 TARGET -oN output_nmap_headers.txt

```

### shcheck - sprawdzenie naglowkow bezpieczenstwa

```bash
shcheck https://TARGET | tee output_shcheck.txt

```

### Nuclei - naglowki bezpieczenstwa

```bash
nuclei -u https://TARGET -tags security-headers -o output_nuclei_sec_headers.txt
nuclei -u https://TARGET -tags headers -o output_nuclei_headers.txt

```

### Sprawdzenie securityheaders.com (API)

```bash
# Sprawdz recznie: https://securityheaders.com/?q=TARGET

```

### Sprawdzenie niebezpiecznych naglowkow ujawniajacych informacje

```bash
curl -sI https://TARGET | grep -iE "^(Server|X-Powered-By|X-AspNet-Version|X-AspNetMvc-Version|X-Runtime|X-Version|X-Generator):" | tee output_info_disclosure_headers.txt

```

### Porownanie naglowkow HTTP vs HTTPS

```bash
curl -sI http://TARGET | tee output_headers_http.txt
curl -sI https://TARGET | tee output_headers_https.txt
diff output_headers_http.txt output_headers_https.txt

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - test polega na analizie naglowkow HTTP
# Uzyj narzedzi automatycznych i manualnej weryfikacji

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W DevTools > Network: sprawdz Response Headers dla kazdej odpowiedzi
2. Sprawdz securityheaders.com - automatyczna ocena naglowkow
3. Zweryfikuj X-Frame-Options: DENY/SAMEORIGIN (ochrona przed clickjacking)
4. Sprawdz X-Content-Type-Options: nosniff (ochrona przed MIME sniffing)
5. Sprawdz Referrer-Policy (nie powinien ujawniac URL w zewnetrznych zapytaniach)
6. Zweryfikuj Permissions-Policy (ograniczenie dostepu do kamer, mikrofonu, GPS)
7. Sprawdz Cache-Control na stronach z wrazliwymi danymi (no-store)
8. Zweryfikuj Cross-Origin-Opener-Policy i Cross-Origin-Resource-Policy
9. Sprawdz czy naglowki informacyjne (Server, X-Powered-By) sa usuniete
10. Porownaj naglowki na roznych endpointach - czy sa spojne
11. Sprawdz czy naglowek Set-Cookie ma flagi: Secure, HttpOnly, SameSite


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTTP_Headers_Cheat_Sheet.md

### Naglowki bezpieczenstwa — kompletna lista

| Naglowek | Wartosc | Cel |
|----------|---------|-----|
| `X-Content-Type-Options` | `nosniff` | Blokuje MIME sniffing |
| `X-Frame-Options` | `DENY` / `SAMEORIGIN` | Ochrona przed clickjacking |
| `Content-Security-Policy` | Restrykcyjna polityka | XSS, injection prevention |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Wymuszanie HTTPS |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Kontrola Referer header |
| `Permissions-Policy` | `camera=(), microphone=(), geolocation=()` | Blokada API przegladarki |
| `Cross-Origin-Opener-Policy` | `same-origin` | Izolacja okna przegladarki |
| `Cross-Origin-Resource-Policy` | `same-origin` | Blokada cross-origin read |
| `Cross-Origin-Embedder-Policy` | `require-corp` | Wymaganie CORP na zasobach |
| `Cache-Control` | `no-store` (wrazliwe dane) | Zapobieganie cache'owaniu |

### Naglowki do USUNIECIA (information disclosure)

| Naglowek | Przyklad | Ryzyko |
|----------|---------|--------|
| `Server` | `Apache/2.4.51` | Ujawnia technologie i wersje |
| `X-Powered-By` | `PHP/8.1.0` | Ujawnia jezyk programowania |
| `X-AspNet-Version` | `4.0.30319` | Ujawnia wersje .NET |
| `X-AspNetMvc-Version` | `5.2` | Ujawnia wersje MVC |
| `X-Generator` | `WordPress 6.0` | Ujawnia CMS |
| `X-Runtime` | `0.012345` | Ujawnia czas przetwarzania (timing attack) |

### Referrer-Policy — opcje (od najbardziej restrykcyjnej)

- `no-referrer` — nigdy nie wysylaj Referer
- `same-origin` — wysylaj tylko do tego samego origin
- `strict-origin` — wysylaj origin (bez path) tylko przez HTTPS→HTTPS
- `strict-origin-when-cross-origin` — **REKOMENDOWANE** — pelny URL same-origin, origin cross-origin
- `no-referrer-when-downgrade` — domyslne, nie wysylaj przy HTTPS→HTTP

### Permissions-Policy — wazne dyrektywy

- `camera=()` — zablokuj dostep do kamery
- `microphone=()` — zablokuj dostep do mikrofonu
- `geolocation=()` — zablokuj dostep do lokalizacji
- `payment=()` — zablokuj Payment Request API
- `usb=()` — zablokuj WebUSB
- `display-capture=()` — zablokuj Screen Capture API

### Cross-Origin headers (COOP/COEP/CORP)

- **COOP** (`same-origin`): izoluje okno przegladarki — blokuje cross-origin window references
- **CORP** (`same-origin`): blokuje cross-origin read zasobow (obrazy, skrypty, fonty)
- **COEP** (`require-corp`): wymaga CORP na wszystkich zaladowanych zasobach
- Razem wlaczaja **cross-origin isolation** — wymagane dla SharedArrayBuffer, high-res timers

### Testowanie naglowkow

- Sprawdz https://securityheaders.com — automatyczna ocena
- Porownaj naglowki na roznych endpointach — musza byc spojne
- Sprawdz naglowki na HTTP vs HTTPS — moga sie roznic
- Testuj clickjacking: stworz iframe z TARGET — sprawdz czy sie laduje

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Headers Analyzer | Pasywna analiza naglowkow bezpieczenstwa HTTP | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |
