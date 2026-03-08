# WSTG-INFO-02 — Fingerprint Web Server

## Cele

- Determine the version and type of a running web server
- Identify server software to find known vulnerabilities and appropriate exploits

## KOMENDY

### WhatWeb - identyfikacja technologii

```bash
whatweb TARGET -v -a 3 | tee output_whatweb.txt
whatweb TARGET --log-verbose=output_whatweb_verbose.txt

```

### Nmap - skanowanie wersji serwera

```bash
nmap -sV -p 80,443,8080,8443 TARGET -oN output_nmap_version.txt
nmap -sV --version-intensity 5 -p 80,443,8080,8443 TARGET -oN output_nmap_version_intense.txt
nmap -sV -sC -p 80,443 TARGET -oN output_nmap_default_scripts.txt
nmap --script http-server-header -p 80,443 TARGET -oN output_nmap_server_header.txt

```

### cURL - analiza naglowkow HTTP

```bash
curl -sI https://TARGET | tee output_headers.txt
curl -sI http://TARGET | tee output_headers_http.txt
curl -sI https://TARGET -H "Host: TARGET" --http1.0
curl -sI https://TARGET -X OPTIONS

```

### Analiza naglowka Server i X-Powered-By

```bash
curl -sI https://TARGET | grep -iE "^(Server|X-Powered-By|X-AspNet-Version|X-Runtime):"

```

### Httprint - fingerprinting serwera (jesli dostepny)

```bash
httprint -h TARGET -s signatures.txt -o output_httprint.txt

```

### Nikto - skaner podatnosci webowych

```bash
nikto -h https://TARGET -o output_nikto.txt -Format txt
nikto -h https://TARGET -Tuning 0 -o output_nikto_info.txt

```

### Wymuszenie odpowiedzi blednej - analiza stron bledow

```bash
curl -sI https://TARGET/nonexistent_page_12345 | tee output_error_headers.txt
curl -s https://TARGET/nonexistent_page_12345 | tee output_error_page.txt

```

### Netcat - reczne polaczenie HTTP

```bash
echo -e "HEAD / HTTP/1.0\r\nHost: TARGET\r\n\r\n" | nc TARGET 80
echo -e "HEAD / HTTP/1.1\r\nHost: TARGET\r\n\r\n" | nc TARGET 80

```

### Niepoprawne zadanie HTTP - analiza odpowiedzi

```bash
echo -e "JUNK / HTTP/1.0\r\n\r\n" | nc TARGET 80

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - narzedzia maja wbudowane sygnatury
# WhatWeb, Nmap, Nikto uzywaja wlasnych baz danych sygnatur serwerow

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz DevTools (F12) > zakladka Network > zaladuj strone > sprawdz naglowki odpowiedzi (Server, X-Powered-By)
2. W Burp Suite: przechwyc odpowiedz i przeanalizuj naglowki serwera
3. Wyslij nieprawidlowe zadanie HTTP przez Burp Repeater i przeanalizuj strone bledu
4. Porownaj odpowiedzi na HTTP/1.0 vs HTTP/1.1 - roznice moga zdradzic serwer
5. Sprawdz strony bledow (404, 500) - czesto zdradzaja wersje serwera
6. Uzyj rozszerzenia Wappalyzer w przegladarce do identyfikacji technologii
7. Porownaj kolejnosc naglowkow odpowiedzi - rozne serwery zwracaja je w roznej kolejnosci


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Pasywne wykrywanie wersji oprogramowania w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Active Scan++ | Rozszerzony skaner aktywny i pasywny z dodatkowymi checkami | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
| Burp Retire JS | Wykrywanie podatnych wersji bibliotek JavaScript | [GitHub](https://github.com/h3xstream/burp-retire-js) |
