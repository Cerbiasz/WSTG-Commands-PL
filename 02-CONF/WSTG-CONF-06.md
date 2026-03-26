# WSTG-CONF-06 — Test HTTP Methods

## Cele

- Enumerate HTTP methods supported by the web server
- Test access control bypass via HTTP method overriding
- Identify dangerous methods (PUT, DELETE, TRACE, CONNECT)

## KOMENDY

### cURL - sprawdzenie OPTIONS

```bash
curl -sI -X OPTIONS https://TARGET | tee output_options.txt
curl -sI -X OPTIONS https://TARGET -H "Access-Control-Request-Method: PUT" | tee output_options_put.txt

```

### Nmap - skrypty HTTP methods

```bash
nmap --script http-methods -p 80,443 TARGET -oN output_nmap_methods.txt
nmap --script http-methods --script-args http-methods.url-path='/admin/' -p 80,443 TARGET -oN output_nmap_methods_admin.txt
nmap --script http-trace -p 80,443 TARGET -oN output_nmap_trace.txt

```

### Testowanie roznych metod HTTP

```bash
curl -sI -X GET https://TARGET | head -1
curl -sI -X POST https://TARGET | head -1
curl -sI -X PUT https://TARGET | head -1
curl -sI -X DELETE https://TARGET | head -1
curl -sI -X PATCH https://TARGET | head -1
curl -sI -X HEAD https://TARGET | head -1
curl -sI -X OPTIONS https://TARGET | head -1
curl -sI -X TRACE https://TARGET | head -1
curl -sI -X CONNECT https://TARGET | head -1

```

### TRACE method - Cross-Site Tracing test

```bash
curl -sI -X TRACE https://TARGET | tee output_trace.txt
curl -s -X TRACE https://TARGET -H "Cookie: test=xst_test" | tee output_trace_xst.txt

```

### PUT method test

```bash
curl -sI -X PUT https://TARGET/test_put_file.txt -d "test content" | tee output_put_test.txt

```

### DELETE method test

```bash
curl -sI -X DELETE https://TARGET/test_put_file.txt | tee output_delete_test.txt

```

### HTTP Method Override headers

```bash
curl -sI https://TARGET -H "X-HTTP-Method-Override: PUT" | head -5
curl -sI https://TARGET -H "X-HTTP-Method: PUT" | head -5
curl -sI https://TARGET -H "X-Method-Override: PUT" | head -5

```

### Access control bypass via method change

```bash
# Jesli GET na /admin daje 403, sprobuj inne metody
curl -sI -X POST https://TARGET/admin | head -1
curl -sI -X PUT https://TARGET/admin | head -1
curl -sI -X PATCH https://TARGET/admin | head -1
curl -sI -X HEAD https://TARGET/admin | head -1

```

### Testowanie niestandardowych metod

```bash
curl -sI -X PROPFIND https://TARGET | head -5
curl -sI -X MOVE https://TARGET | head -5
curl -sI -X COPY https://TARGET | head -5
curl -sI -X MKCOL https://TARGET | head -5
curl -sI -X LOCK https://TARGET | head -5

```

### WebDAV detection

```bash
curl -sI -X PROPFIND https://TARGET -H "Depth: 0" | tee output_webdav.txt

```

## KOMENDY Z WORDLISTAMI

### fuzzdb common methods

```bash
# Uzyj listy metod z fuzzdb
ffuf -u https://TARGET -X FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/common-methods/common-methods.txt -mc all -o output_ffuf_methods.json

# Brak dodatkowych wordlist - test polega na sprawdzeniu konkretnych metod HTTP

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Repeater: wyslij zapytanie OPTIONS i sprawdz naglowek Allow
2. Zmien metode HTTP w Burp Repeater na PUT, DELETE, TRACE i obserwuj odpowiedz
3. Testuj HTTP Method Override: dodaj naglowek X-HTTP-Method-Override
4. Sprawdz czy TRACE jest wlaczony - ryzyko Cross-Site Tracing (XST)
5. Sprawdz czy PUT pozwala na upload plikow na serwer
6. Testuj access control bypass: jesli GET daje 403, sprobuj POST/PUT/PATCH
7. Sprawdz WebDAV methods (PROPFIND, MKCOL, MOVE, COPY)
8. Porownaj odpowiedzi na rozne metody dla roznych endpointow
9. Sprawdz czy metoda HEAD ujawnia informacje bez zwracania body


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md

### Metody HTTP — bezpieczenstwo

- Zezwalaj TYLKO na potrzebne metody — typowo GET i POST, opcjonalnie PUT/PATCH/DELETE dla REST API
- **TRACE**: wylacz — umozliwia Cross-Site Tracing (XST), ujawnia cookies i auth headers
- **PUT/DELETE**: zezwalaj TYLKO na autoryzowanych endpointach API — nie na statycznych zasobach
- **OPTIONS**: moze ujawniac dozwolone metody — rozważ ograniczenie (ale potrzebne dla CORS preflight)
- **CONNECT**: wylacz — moze byc uzyty do tunelowania
- Niestandardowe metody (FOO, JEFF): serwer powinien zwracac 405 — nie akceptowac jako GET

### Konfiguracja per serwer

| Serwer | Jak ograniczyc metody |
|--------|---------------------|
| Apache | `<LimitExcept GET POST>Require all denied</LimitExcept>` |
| Nginx | `if ($request_method !~ ^(GET\|POST)$) { return 405; }` |
| IIS | Web.config: `<security><requestFiltering><verbs>` |
| Tomcat | `<security-constraint>` w web.xml |

### Method Override — zagrożenie

- Headery: `X-HTTP-Method-Override`, `X-Method-Override`, `X-HTTP-Method`
- Parametr: `_method=PUT` w body (Rails, Laravel, Django)
- Atakujacy moze uzyc POST z override header aby wykonac PUT/DELETE
- Obrona: nie akceptuj method override headers z niezaufanych zrodel

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Identity Crisis | Testowanie roznych odpowiedzi serwera na rozne User-Agenty i metody | [GitHub](https://github.com/EnableSecurity/Identity-Crisis) |
| Bypass WAF | Obchodzenie regul Web Application Firewall | [GitHub](https://github.com/codewatchorg/bypasswaf) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.5.3 | Browser Origin Separation | Verify that HTTP requests to sensitive functionality use appropriate HTTP methods such as POST, PUT, PATCH, or DELETE, and not methods defined by the HTTP specification as "safe" such as HEAD, OPTIONS, or GET. Alternatively, strict validation of the Sec-Fetch-* request header fields can be used to ensure that the request did not originate from an inappropriate cross-origin call, a navigation request, or a resource load (such as an image source) where this is not expected. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.4 | Unintended Information Leakage | Verify that using the HTTP TRACE method is not supported in production environments, to avoid potential information leakage. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.1.4 | Generic Web Service Security | Verify that only HTTP methods that are explicitly supported by the application or its API (including OPTIONS during preflight requests) can be used and that unused methods are blocked. |
