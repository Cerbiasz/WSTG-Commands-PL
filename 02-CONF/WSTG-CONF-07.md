# WSTG-CONF-07 — Test HTTP Strict Transport Security

## Cele

- Review HSTS header presence and configuration
- Verify that HTTPS is enforced and HTTP redirects properly
- Check HSTS preload list inclusion

## KOMENDY

### cURL - sprawdzenie naglowka HSTS

```bash
curl -sI https://TARGET | grep -i "Strict-Transport-Security" | tee output_hsts.txt
curl -sI http://TARGET | tee output_http_redirect.txt

```

### Sprawdzenie parametrow HSTS

```bash
curl -sI https://TARGET | grep -i "Strict-Transport-Security"
# Oczekiwany: Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
# Minimalny max-age: 31536000 (1 rok)

```

### Sprawdzenie czy HTTP przekierowuje na HTTPS

```bash
curl -sIL http://TARGET | tee output_http_to_https.txt
curl -sI http://TARGET | grep -i "Location:"

```

### SSLyze - sprawdzenie HSTS

```bash
sslyze TARGET --regular | grep -iA 5 "HSTS" | tee output_sslyze_hsts.txt

```

### testssl.sh - sprawdzenie HSTS

```bash
testssl.sh --headers TARGET | tee output_testssl_headers.txt

```

### Nmap - sprawdzenie naglowkow bezpieczenstwa

```bash
nmap --script http-security-headers -p 443 TARGET -oN output_nmap_sec_headers.txt

```

### Sprawdzenie HSTS na subdomenach

```bash
curl -sI https://www.TARGET | grep -i "Strict-Transport-Security"
curl -sI https://mail.TARGET | grep -i "Strict-Transport-Security"
curl -sI https://api.TARGET | grep -i "Strict-Transport-Security"

```

### Sprawdzenie HSTS preload

```bash
# Sprawdz recznie: https://hstspreload.org/?domain=TARGET

```

### Sprawdzenie mixed content

```bash
curl -s https://TARGET | grep -iE "http://" | grep -v "https://" | tee output_mixed_content.txt

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - test polega na analizie naglowkow HTTP

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz TARGET przez HTTP (http://TARGET) - sprawdz czy przekierowuje na HTTPS
2. W DevTools > Network: sprawdz naglowek Strict-Transport-Security
3. Zweryfikuj parametry HSTS: max-age >= 31536000, includeSubDomains, preload
4. Sprawdz hstspreload.org czy domena jest na liscie preload
5. Przetestuj mixed content - czy strona HTTPS laduje zasoby przez HTTP
6. Sprawdz czy naglowek HSTS jest ustawiony na wszystkich subdomenach
7. W Burp Suite: sprawdz czy mozna wykonac SSL stripping
8. Zweryfikuj czy cookie maja flage Secure


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTTP_Strict_Transport_Security_Cheat_Sheet.md, Transport_Layer_Security_Cheat_Sheet.md

### HSTS — konfiguracja

- **max-age**: minimum `31536000` (1 rok) — krotszy jest niewystarczajacy
- **includeSubDomains**: chronij WSZYSTKIE subdomeny — nie tylko glowna domene
- **preload**: dodaj do preload list (hstspreload.org) — ochrona od pierwszego requestu
- Pelny naglowek: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- HSTS musi byc wysylany TYLKO przez HTTPS — NIE przez HTTP

### Dlaczego HSTS jest kluczowy

- Bez HSTS: pierwszy request moze isc przez HTTP → **sslstrip** atak
- Atakujacy w MitM moze przechwycic HTTP → proxy → nie przekieruj do HTTPS
- HSTS zmusza przegladarke do uzywania HTTPS **bezwarunkowo** po pierwszym uzyciu
- **HSTS preload**: przegladarka zna domene PRZED pierwszym requestem — zero HTTP requestow

### Wymagania HSTS preload list

- `max-age` >= 31536000 (1 rok)
- `includeSubDomains` musi byc obecne
- `preload` musi byc obecne
- Serwer musi obslugiwac HTTPS na glownej domenie (nie tylko subdomenach)
- HTTP musi przekierowywac 301 do HTTPS
- Wszystkie subdomeny musza obslugiwac HTTPS

### Mixed content — zagrożenie

- Strona HTTPS ladujaca zasoby przez HTTP = **mixed content**
- Active mixed content (script, iframe) — blokowane przez przegladarke
- Passive mixed content (obrazy, audio) — ostrzezenie, ale ladowane
- Sprawdz: `curl -s https://TARGET | grep -i "http://" | grep -v "https://"`
- CSP: `upgrade-insecure-requests` — automatycznie upgraduj HTTP do HTTPS

### TLS konfiguracja

- TLS 1.2+ (najlepiej TLS 1.3) — wylacz TLS 1.0/1.1
- Wylacz slabe cipher suites: RC4, DES, 3DES, NULL, EXPORT
- Preferuj AEAD: AES-GCM, ChaCha20-Poly1305 z ECDHE (PFS)
- Narzedzie: **Mozilla SSL Configuration Generator** — generuj prawidlowa konfiguracje

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Headers Analyzer | Analiza naglowkow bezpieczenstwa w odpowiedziach HTTP | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |
| SRI Check | Wykrywanie brakujacych atrybutow Subresource Integrity | [GitHub](https://github.com/SolomonSklash/sri-check) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.4.1 | Browser Security Mechanism Headers | Verify that a Strict-Transport-Security header field is included on all responses to enforce an HTTP Strict Transport Security (HSTS) policy. A maximum age of at least 1 year must be defined, and for L2 and up, the policy must apply to all subdomains as well. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.7.4 | Other Browser Security Considerations | Verify that the application's top-level domain (e.g., site.tld) is added to the public preload list for HTTP Strict Transport Security (HSTS). This ensures that the use of TLS for the application is built directly into the main browsers, rather than relying only on the Strict-Transport-Security response header field. |
