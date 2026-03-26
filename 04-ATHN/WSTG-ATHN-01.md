# WSTG-ATHN-01 — Testing for Credentials Transported over an Encrypted Channel

## Cele

- Ocenic czy dane uwierzytelniajace sa przesylane bez szyfrowania
- Zweryfikowac konfiguracje SSL/TLS
- Sprawdzic czy formularze logowania wymuszaja HTTPS

## KOMENDY

### Sprawdzenie czy strona logowania uzywa HTTPS

```bash
curl -s -v "http://TARGET/login" 2>&1 | grep -iE "Location|HTTP/"
curl -s -v "https://TARGET/login" 2>&1 | grep -iE "Location|HTTP/"

```

### Testssl.sh - kompleksowy test SSL/TLS

```bash
testssl.sh https://TARGET
testssl.sh --starttls smtp TARGET:25
testssl.sh -U --sneaky https://TARGET

```

### sslyze - analiza konfiguracji SSL

```bash
sslyze TARGET
sslyze --regular TARGET
sslyze --certinfo TARGET
sslyze --tlsv1 --tlsv1_1 --tlsv1_2 --tlsv1_3 TARGET

```

### curl - sprawdzenie certyfikatu i wersji TLS

```bash
curl -vI "https://TARGET" 2>&1 | grep -iE "SSL|TLS|subject|issuer|expire"

```

### Sprawdzenie czy formularz logowania wysyla POST przez HTTP

```bash
curl -s "https://TARGET/login" | grep -iE "action=.*http://"

```

### Nmap SSL scripts

```bash
nmap --script ssl-enum-ciphers -p 443 TARGET
nmap --script ssl-cert -p 443 TARGET
nmap --script ssl-known-key -p 443 TARGET
nmap --script ssl-heartbleed -p 443 TARGET
nmap --script ssl-poodle -p 443 TARGET
nmap --script ssl-dh-params -p 443 TARGET

```

### Sprawdzenie naglowkow bezpieczenstwa

```bash
curl -s -I "https://TARGET/" | grep -iE "Strict-Transport|Content-Security|X-Frame|X-Content"

```

### Sprawdzenie HSTS

```bash
curl -s -I "https://TARGET/" | grep -i "Strict-Transport-Security"

```

### Sprawdzenie mixed content (HTTP resources na HTTPS)

```bash
curl -s "https://TARGET/login" | grep -iE "src=.http://"

```

### Sprawdzenie przekierowania HTTP -> HTTPS

```bash
curl -s -o /dev/null -w "%{redirect_url}" "http://TARGET/login"

```

### Sprawdzenie czy API akceptuje HTTP

```bash
curl -s -X POST "http://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"test","password":"test"}' -v 2>&1

```

### Sprawdzenie slabych cipher suites

```bash
openssl s_client -connect TARGET:443 -cipher NULL,EXPORT,LOW,DES,RC4,MD5,aNULL,eNULL 2>&1

```

### Sprawdzenie obslugi TLS 1.0/1.1 (przestarzale)

```bash
openssl s_client -connect TARGET:443 -tls1 2>&1 | grep -i "protocol"
openssl s_client -connect TARGET:443 -tls1_1 2>&1 | grep -i "protocol"
openssl s_client -connect TARGET:443 -tls1_2 2>&1 | grep -i "protocol"
openssl s_client -connect TARGET:443 -tls1_3 2>&1 | grep -i "protocol"

```

## KOMENDY Z WORDLISTAMI

# Brak wordlist - test konfiguracji SSL/TLS i szyfrowania transportu

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W przegladarce sprawdz ikone klodki i szczegoly certyfikatu na stronie logowania
2. W DevTools (Security tab) sprawdz konfiguracje TLS i certyfikat
3. W Burp Suite sprawdz czy requesty logowania ida przez HTTPS
4. Uzyj Wireshark do przechwycenia ruchu i sprawdzenia czy credentials sa widoczne
5. Sprawdz czy formularz logowania nie wysyla danych przez HTTP (action URL)
6. Przetestuj czy mozna uzyskac dostep do strony logowania przez HTTP (bez S)
7. Sprawdz czy cookies maja flage Secure
8. Zweryfikuj naglowek HSTS i jego wartosc max-age


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transport_Layer_Security_Cheat_Sheet.md, HTTP_Strict_Transport_Security_Cheat_Sheet.md

### Konfiguracja TLS

- Wymuszaj **TLS 1.2+** dla wszystkich polaczen — wylacz TLS 1.0/1.1 (przestarzale, podatne na POODLE, BEAST)
- Preferuj **TLS 1.3** — eliminuje starsze, niebezpieczne cipher suites, szybszy handshake
- Wylacz slabe cipher suites: **RC4, DES, 3DES, NULL, EXPORT, aNULL, eNULL**
- Preferuj **AEAD cipher suites**: AES-GCM, ChaCha20-Poly1305
- Preferuj **ECDHE** (Elliptic Curve Diffie-Hellman Ephemeral) — zapewnia Perfect Forward Secrecy (PFS)
- Formularz logowania i endpoint POST MUSZA byc na HTTPS — brak HTTPS ujawnia credentials w sieci

### HSTS (HTTP Strict Transport Security)

- Wlacz HSTS z: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `max-age` minimum **31536000** (1 rok) — krotsza wartosc daje mniejsza ochrone
- `includeSubDomains` — chroni wszystkie subdomeny (WAZNE: upewnij sie ze WSZYSTKIE subdomeny obsluguja HTTPS)
- `preload` — dodaj domene do HSTS Preload List (hstspreload.org) — przegladarka wymusza HTTPS bez pierwszego HTTP request
- HSTS chroni przed: SSL stripping (sslstrip), downgrade attacks, mixed content issues

### Mixed Content

- WSZYSTKIE zasoby (obrazy, CSS, JS, fonty, iframe) musza byc ladowane przez HTTPS
- Mixed content: HTTP resources na stronie HTTPS — przegladarka moze je zablokowac lub wyswietlic ostrzezenie
- Sprawdz: `curl -s "https://TARGET/" | grep -i "src=.http://"`

### Certyfikaty

- Uzyj certyfikatow od zaufanych CA (nie self-signed w produkcji)
- Sprawdz date waznosci certyfikatu, lancuch zaufania, CN/SAN
- Wlacz OCSP Stapling dla szybszej weryfikacji statusu certyfikatu
- Nie lacz stron HTTP (niezabezpieczonych) z HTTPS na tej samej domenie

### Session Security

- Cookie session MUSI miec flage **Secure** — bez niej moze byc wyslane przez HTTP
- Nie przechodzic sesji z HTTP na HTTPS (i odwrotnie) — regeneruj cookie PO redirect na HTTPS
- Implementuj HSTS razem z Secure cookies — defence in depth

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| TLS-Attacker-BurpExtension | Testowanie konfiguracji TLS serwera | [GitHub](https://github.com/RUB-NDS/TLS-Attacker-BurpExtension) |
| Headers Analyzer | Analiza naglowkow bezpieczenstwa (HSTS, CSP) | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V12.1.1 | General TLS Security Guidance | Verify that only the latest recommended versions of the TLS protocol are enabled, such as TLS 1.2 and TLS 1.3. The latest version of the TLS protocol must be the preferred option. |
| V12.2.1 | HTTPS Communication with External Facing Services | Verify that TLS is used for all connectivity between a client and external facing, HTTP-based services, and does not fall back to insecure or unencrypted communications. |
| V12.2.2 | HTTPS Communication with External Facing Services | Verify that external facing services use publicly trusted TLS certificates. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V12.1.2 | General TLS Security Guidance | Verify that only recommended cipher suites are enabled, with the strongest cipher suites set as preferred. L3 applications must only support cipher suites which provide forward secrecy. |
