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

- Wlacz HSTS z dlugim max-age (minimum 31536000 = 1 rok) i includeSubDomains
- Dodaj domene do HSTS preload list (hstspreload.org) dla pelnej ochrony
- Uzyj wylacznie TLS 1.2+ (najlepiej TLS 1.3) — wylacz TLS 1.0/1.1
- Wylacz slabe cipher suites: RC4, DES, 3DES, NULL, EXPORT
- Preferuj AEAD cipher suites (AES-GCM, ChaCha20-Poly1305) z ECDHE (PFS)
- Unikaj mixed content — wszystkie zasoby musza byc ladowane przez HTTPS

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Headers Analyzer | Analiza naglowkow bezpieczenstwa w odpowiedziach HTTP | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |
| SRI Check | Wykrywanie brakujacych atrybutow Subresource Integrity | [GitHub](https://github.com/SolomonSklash/sri-check) |
