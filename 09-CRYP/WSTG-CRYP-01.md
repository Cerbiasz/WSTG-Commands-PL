# WSTG-CRYP-01 — Testing for Weak Transport Layer Security

## Cele

- Zwalidowac konfiguracje TLS
- Przegladnac sile kryptograficzna certyfikatu
- Upewnic sie ze TLS nie moze byc ominiete

## KOMENDY

### testssl.sh - kompleksowe skanowanie TLS

```bash
testssl.sh TARGET
testssl.sh --full TARGET
testssl.sh --vulnerable TARGET
testssl.sh --headers TARGET

```

### testssl.sh - szczegolowe testy

```bash
testssl.sh --protocols TARGET
testssl.sh --ciphers TARGET
testssl.sh --server-defaults TARGET
testssl.sh --heartbleed TARGET
testssl.sh --poodle TARGET
testssl.sh --beast TARGET
testssl.sh --lucky13 TARGET
testssl.sh --freak TARGET
testssl.sh --logjam TARGET
testssl.sh --drown TARGET

```

### sslyze - analiza TLS

```bash
sslyze TARGET
sslyze --regular TARGET
sslyze --certinfo TARGET
sslyze --tlsv1 TARGET
sslyze --tlsv1_1 TARGET
sslyze --tlsv1_2 TARGET
sslyze --tlsv1_3 TARGET
sslyze --sslv2 TARGET
sslyze --sslv3 TARGET

```

### sslscan - szybkie skanowanie

```bash
sslscan TARGET
sslscan --no-fallback TARGET

```

### nmap ssl-enum-ciphers

```bash
nmap --script ssl-enum-ciphers -p 443 TARGET
nmap --script ssl-cert -p 443 TARGET
nmap --script ssl-known-key -p 443 TARGET
nmap --script ssl-heartbleed -p 443 TARGET
nmap --script ssl-poodle -p 443 TARGET
nmap --script ssl-ccs-injection -p 443 TARGET
nmap --script ssl-dh-params -p 443 TARGET

```

### curl verbose - sprawdzenie TLS

```bash
curl -vvI https://TARGET 2>&1 | grep -E "SSL|TLS|certificate|cipher|issuer|subject"

```

### curl wymuszenie starych protokolow

```bash
curl -v --tlsv1.0 --tls-max 1.0 https://TARGET 2>&1
curl -v --tlsv1.1 --tls-max 1.1 https://TARGET 2>&1
curl -v --sslv2 https://TARGET 2>&1
curl -v --sslv3 https://TARGET 2>&1

```

### openssl s_client - manualne testowanie

```bash
openssl s_client -connect TARGET:443 -tls1
openssl s_client -connect TARGET:443 -tls1_1
openssl s_client -connect TARGET:443 -tls1_2
openssl s_client -connect TARGET:443 -tls1_3

```

### Sprawdzenie certyfikatu

```bash
openssl s_client -connect TARGET:443 < /dev/null 2>/dev/null | openssl x509 -noout -text

```

### Sprawdzenie daty waznosci certyfikatu

```bash
openssl s_client -connect TARGET:443 < /dev/null 2>/dev/null | openssl x509 -noout -dates

```

### Sprawdzenie lancucha certyfikatow

```bash
openssl s_client -connect TARGET:443 -showcerts < /dev/null

```

### Sprawdzenie HSTS

```bash
curl -sI https://TARGET | grep -i strict-transport-security

```

### Sprawdzenie HTTP -> HTTPS redirect

```bash
curl -sI http://TARGET | grep -i location

```

### Sprawdzenie mixed content

```bash
curl -s https://TARGET | grep -iE "http://" | head -20

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - testy oparte na narzdziach kryptograficznych

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W przegladarce kliknij ikone kludki -> Szczegoly certyfikatu: sprawdz waznosc,
```bash
   wystawce, algorytm podpisu (RSA >= 2048, unikaj SHA-1)
```

2. Sprawdz w DevTools -> Security tab: szczegoly polaczenia TLS
3. Zweryfikuj ze HTTP zawsze przekierowuje na HTTPS
4. Sprawdz naglowek HSTS (Strict-Transport-Security) i jego parametry (max-age, includeSubDomains)
5. Uzyj Burp Suite -> Scanner do automatycznego wykrycia slabych szyfrow
6. Sprawdz czy SSL/TLS Certificate Pinning jest zaimplementowany (mobile app)
7. Zweryfikuj ze nie ma wsparcia dla SSLv2, SSLv3, TLS 1.0, TLS 1.1


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transport_Layer_Security_Cheat_Sheet.md, TLS_Cipher_String_Cheat_Sheet.md

### Konfiguracja protokolow

- **TLS 1.3** (preferowany) + **TLS 1.2** (jesli wymagana kompatybilnosc) — JEDYNE dozwolone protokoly
- **WYLACZ**: SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1 — PCI DSS ZABRANIA uzywania legacy protocols
- Wlacz `TLS_FALLBACK_SCSV` extension — zapobiega downgrade attacks na nowsze klienty
- TLS 1.0 TYLKO w wyjatkowych sytuacjach (legacy browsers np. IE 10) — z ostrożnoscia

### Cipher suites

- **Preferuj AEAD**: AES-GCM, ChaCha20-Poly1305 — zapewniaja poufnosc + integralnosc + autentycznosc
- **Perfect Forward Secrecy (PFS)**: ECDHE key exchange — kompromitacja klucza nie ujawnia przeszlego ruchu
- **WYLACZ**: Null ciphers, Anonymous ciphers, EXPORT ciphers, RC4, DES, 3DES
- Generator bezpiecznej konfiguracji: [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- Grupy Diffie-Hellman (TLS 1.3): `x25519`, `prime256v1`/`secp256r1`, `ffdhe3072`

### Certyfikaty

- Klucz prywatny: min **RSA 2048-bit** lub **ECDSA P-256** (Curve25519 preferowany)
- Algorytm hashowania: **SHA-256** — NIE uzywaj MD5 ani SHA-1
- Domain Name w certyfikacie: ustaw w `subjectAlternativeName` (SAN) — Chrome ignoruje CN
- **Wildcard certificates**: uzywaj ostrożnie — kompromitacja klucza dotyczy WSZYSTKICH subdomen
  - Nigdy nie wspoldziel wildcard miedzy systemami o roznym poziomie zaufania (np. VPN + publiczny web server)
- **CAA DNS records**: ogranicz ktore CA moga wydawac certyfikaty dla Twojej domeny
- **Let's Encrypt**: darmowe certyfikaty DV, zaufane przez wszystkie major browsers

### HSTS (HTTP Strict Transport Security)

- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- Wymusza HTTPS na wszystkich przyszlych requestach — przegladarka nigdy nie uzyje HTTP
- `includeSubDomains` — stosuje sie do wszystkich subdomen
- `preload` — dodanie do listy preload w przegladarkach (trwale)
- Ustaw HSTS PO potwierdzeniu ze HTTPS dziala poprawnie — blad moze zablokowac dostep

### Aplikacja — zasady

- **TLS na WSZYSTKICH stronach** — nie tylko login/checkout; strony HTTP moga ujawnic session cookies
- **Redirect HTTP → HTTPS**: HTTP 301 permanent redirect, potem wzmocnij HSTS
- **API endpoints**: wylacz HTTP calkowicie — failuj requesty zamiast redirectowac
- **Nie mieszaj TLS i non-TLS**: nie laduj JS/CSS przez HTTP na stronie HTTPS (mixed content)
- **Secure cookie flag**: WSZYSTKIE cookies z atrybutem `Secure` — nie wysylaj przez HTTP
- **Cache-Control**: `no-cache, no-store, must-revalidate` na odpowiedziach z wrazliwymi danymi

### Mutual TLS (mTLS)

- Klient i serwer wzajemnie weryfikuja tozsamosc przez certyfikaty
- Zapobiega man-in-the-middle nawet jesli atakujacy ma trusted CA cert
- Rozważ dla: high-value applications, API-to-API, wewnetrzne microservices
- Wyzwania: zarzadzanie certyfikatami klienta, overhead administracyjny

### Testowanie konfiguracji TLS

- Online: SSL Labs, CryptCheck, Hardenize, ImmuniWeb, Mozilla Observatory
- Offline: testssl.sh, SSLyze, SSLScan, CipherScan, O-Saft
- Aktualizuj biblioteki kryptograficzne — Heartbleed, POODLE, BEAST, CRIME, FREAK, Logjam

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| TLS-Attacker-BurpExtension | Kompleksowe testowanie konfiguracji TLS | [GitHub](https://github.com/RUB-NDS/TLS-Attacker-BurpExtension) |
