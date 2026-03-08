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

- Uzywaj wylacznie TLS 1.2+ (preferuj TLS 1.3) — wylacz SSL 2/3, TLS 1.0/1.1
- Preferuj AEAD cipher suites: AES-GCM, ChaCha20-Poly1305
- Wlacz Perfect Forward Secrecy (PFS) z ECDHE key exchange
- Wylacz slabe ciphers: RC4, DES, 3DES, NULL, EXPORT, CBC bez HMAC
- Uzywaj certyfikatow z min RSA 2048-bit lub ECDSA P-256
- Sprawdz caly lancuch certyfikatow i prawidlowosc CA

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| TLS-Attacker-BurpExtension | Kompleksowe testowanie konfiguracji TLS | [GitHub](https://github.com/RUB-NDS/TLS-Attacker-BurpExtension) |
