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

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, HTTP_Headers_Cheat_Sheet.md

### Fingerprinting serwera — zrodla informacji

| Zrodlo | Co ujawnia | Jak ukryc |
|--------|-----------|-----------|
| Naglowek `Server` | Nazwa i wersja serwera | `ServerTokens Prod` (Apache), `server_tokens off` (Nginx) |
| Naglowek `X-Powered-By` | Framework/jezyk (PHP, ASP.NET) | `expose_php=Off` (PHP), usun naglowek |
| Naglowek `X-AspNet-Version` | Wersja ASP.NET | `<httpRuntime enableVersionHeader="false"/>` |
| Strony bledow (404/500) | Stack trace, sciezki, wersje | Custom error pages bez informacji technicznych |
| Kolejnosc naglowkow | Identyfikacja serwera | Trudne do ukrycia — unikalna per serwer |
| Naglowek `ETag` | Inode number (Apache) | `FileETag None` lub `FileETag MTime Size` |

### Techniki fingerprinting

- **Banner grabbing**: naglowek `Server` w odpowiedzi HTTP
- **Error page analysis**: domyslne strony bledow sa unikalne per serwer
- **HTTP method behavior**: rozne serwery roznie obsluguja nieznane metody
- **Header ordering**: Apache i Nginx zwracaja naglowki w roznej kolejnosci
- **Protocol behavior**: roznice w HTTP/1.0 vs HTTP/1.1 handling
- **Favicon hash**: hash favicony moze identyfikowac technologie (Shodan dork: `http.favicon.hash`)

### Konfiguracja — ukrywanie informacji per serwer

| Serwer | Konfiguracja |
|--------|-------------|
| Apache | `ServerTokens Prod`, `ServerSignature Off` |
| Nginx | `server_tokens off;` |
| IIS | Usun `X-Powered-By`, `X-AspNet-Version` via URL Rewrite |
| Tomcat | `server` attribute w `<Connector>`, usun default error pages |
| Node.js/Express | `app.disable('x-powered-by')` |

### Obrona

- Ukryj wersje serwera i frameworka — nie eliminuje ryzyka, ale spowalnia rekonesans
- Custom error pages: 400, 401, 403, 404, 500 bez stack traces i sciezek
- Usun domyslne strony instalacji (Apache default page, IIS welcome, Nginx welcome)
- Usun niepotrzebne naglowki: `X-Powered-By`, `X-AspNet-Version`, `X-Generator`
- **Security through obscurity nie wystarczy** — to dodatkowa warstwa, nie glowna obrona

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Pasywne wykrywanie wersji oprogramowania w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Active Scan++ | Rozszerzony skaner aktywny i pasywny z dodatkowymi checkami | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
| Burp Retire JS | Wykrywanie podatnych wersji bibliotek JavaScript | [GitHub](https://github.com/h3xstream/burp-retire-js) |
