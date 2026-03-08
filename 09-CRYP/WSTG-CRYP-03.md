# WSTG-CRYP-03 — Testing for Sensitive Information Sent via Unencrypted Channels

## Cele

- Zidentyfikowac wrazliwe informacje przesylane przez niezaszyfrowane kanaly

## KOMENDY

### Sprawdzenie czy strona logowania jest dostepna przez HTTP

```bash
curl -v http://TARGET/login
curl -v http://TARGET/signin
curl -v http://TARGET/account

```

### Sprawdzenie przekierowania HTTP -> HTTPS

```bash
curl -sI http://TARGET | grep -i location
curl -sI http://TARGET/login | grep -i location

```

### Sprawdzenie formularzy na stronach HTTP

```bash
curl -s http://TARGET | grep -iE "action=\"http://"
curl -s http://TARGET/login | grep -iE "<form" | head -10

```

### Sprawdzenie mixed content na stronach HTTPS

```bash
curl -s https://TARGET | grep -oP 'http://[^"'"'"' >]+' | sort -u | head -30

```

### Sprawdzenie cookies bez flagi Secure

```bash
curl -vI https://TARGET 2>&1 | grep -i set-cookie
curl -vI http://TARGET 2>&1 | grep -i set-cookie

```

### Wireshark/tshark - przechwytywanie ruchu niezaszyfrowanego

```bash
# Przechwytywanie ruchu HTTP na interfejsie eth0:
sudo tshark -i eth0 -f "tcp port 80" -Y "http" -w /tmp/http_capture.pcap

```

### tshark - analiza przechwyconych danych

```bash
sudo tshark -r /tmp/http_capture.pcap -Y "http.request.method == POST" -T fields -e http.host -e http.request.uri -e http.file_data

```

### Sprawdzenie API HTTP vs HTTPS

```bash
curl -v http://TARGET/api/
curl -v https://TARGET/api/

```

### Sprawdzenie naglowkow bezpieczenstwa

```bash
curl -sI https://TARGET | grep -iE "strict-transport-security|content-security-policy"

```

### Testowanie HSTS bypass

```bash
curl -sI https://TARGET | grep -i "strict-transport-security"
# Sprawdz max-age (powinien byc >= 31536000)
# Sprawdz includeSubDomains
# Sprawdz preload

```

### Sprawdzenie czy API akceptuje HTTP

```bash
curl -v http://TARGET/api/users
curl -v http://TARGET/api/login -X POST -d "user=test&pass=test"

```

### SSLstrip test koncepcyjny

```bash
# Jezeli brak HSTS, atakujacy moze uzyc sslstrip do downgrade HTTPS->HTTP
# Sprawdz: curl -sI https://TARGET | grep -c "Strict-Transport-Security"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test konfiguracji sieciowej

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz strone przez http:// - sprawdz czy nastepuje redirect na https://
2. W DevTools -> Console: sprawdz ostrzezenia o mixed content
3. W DevTools -> Network: sprawdz czy jakiekolwiek zasoby ladowane sa przez HTTP
4. W DevTools -> Application -> Cookies: sprawdz flage Secure na kazdym cookie
5. W Burp Suite -> Proxy: przechwytuj ruch i szukaj wrazliwych danych w HTTP
6. Sprawdz czy formularze logowania/rejestracji wysylaja dane przez HTTPS
7. Sprawdz czy tokeny sesji/API sa przesylane wylacznie przez HTTPS
8. Sprawdz czy linki do zasobow zewnetrznych uzywaja HTTPS


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transport_Layer_Protection_Cheat_Sheet.md

- Szyfruj wszystkie dane wrazliwe w transmisji — HTTPS wszedzie
- Wlacz HSTS aby zapobiec downgrade do HTTP
- Nie pozwalaj na mixed content — zasoby HTTP na stronach HTTPS
- Przekieruj HTTP na HTTPS na poziomie serwera (301 redirect)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Headers Analyzer | Weryfikacja naglowkow HSTS i bezpieczenstwa transportu | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |
