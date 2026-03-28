# WSTG-INPV-03 — Testing for HTTP Verb Tampering

## Cele

- Test HTTP verb tampering and access control bypass

## KOMENDY

### Testowanie roznych metod HTTP

```bash
curl -X GET "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X POST "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X PUT "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X DELETE "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X PATCH "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X OPTIONS "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X HEAD "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X TRACE "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X CONNECT "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"

```

### Niestandardowe metody

```bash
curl -X JEFF "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X FOO "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"

```

### Nmap HTTP methods

```bash
nmap --script http-methods -p 80,443 TARGET -oN output_nmap_methods.txt

```

### Method override headers

```bash
curl -X POST "https://TARGET/admin" -H "X-HTTP-Method-Override: PUT" -o /dev/null -w "%{http_code}\n"
curl -X POST "https://TARGET/admin" -H "X-Method-Override: DELETE" -o /dev/null -w "%{http_code}\n"
curl -X POST "https://TARGET/admin" -H "X-HTTP-Method: PATCH" -o /dev/null -w "%{http_code}\n"

```

## KOMENDY Z WORDLISTAMI

### SecLists HTTP request methods

```bash
ffuf -u "https://TARGET/admin" -w Desktop/WSTG/SecLists-master/Fuzzing/http-request-methods.txt -X FUZZ -mc all -o output_ffuf_methods.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp Repeater do testowania kazdej metody HTTP na chronionych endpointach
2. Porownaj odpowiedzi dla roznych metod (200 vs 403 vs 405)
3. Sprawdz czy zmiana metody omija autentykacje lub autoryzacje
4. Testuj method override headers w polaczeniu z POST
5. Sprawdz TRACE method pod katem XST (Cross-Site Tracing)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### HTTP Verb Tampering — mechanizm ataku

- Kontrola dostepu skonfigurowana tylko dla GET/POST — inne metody (PUT, DELETE, PATCH) moga ominac zabezpieczenia
- Niestandardowe metody (JEFF, FOO) — niektore frameworki akceptuja dowolne metody jako GET
- **TRACE** — moze ujawniac cookies i naglowki (Cross-Site Tracing / XST)

### Konfiguracja serwera — prawidlowa obrona

- Blokuj **wszystkie** metody HTTP ktore nie sa jawnie wymagane — allowlist, nie denylist
- Apache: `<LimitExcept GET POST>` → deny from all
- Nginx: `if ($request_method !~ ^(GET|POST)$) { return 405; }`
- Sprawdz autoryzacje na **kazdej metodzie** — nie tylko na GET/POST
- Wylacz TRACE na produkcji — zapobiega XST

### Method Override Headers — bypass

- `X-HTTP-Method-Override: PUT` — zmienia POST na PUT po stronie serwera
- `X-Method-Override`, `X-HTTP-Method` — alternatywne naglowki
- `_method=DELETE` — parametr w body (Rails, Laravel)
- Frameworki ktore to obsluguja: Rails, Spring, Django REST Framework, Laravel
- Testuj: wyslij POST z override header do chronionego endpointu

### REST API — metody i autoryzacja

- Kazda metoda HTTP na kazdym endpoincie musi byc **oddzielnie autoryzowana**
- `GET /users/123` (odczyt) vs `DELETE /users/123` (usuwanie) — rozne uprawnienia
- Nie zakladaj ze kontrola dostepu na GET chroni tez PUT/DELETE
- Odpowiedz `405 Method Not Allowed` jest lepsza niz `404` — ale nie ujawnia zbytnio

### Co testowac

- Wyslij OPTIONS do kazdego endpointu — sprawdz `Allow` header
- Porownaj odpowiedzi: GET 403 vs PUT 200? vs DELETE 200?
- Testuj niestandardowe metody (FOO, JEFF) — czy omijaja auth?
- Testuj method override headers na endpointach z ograniczonym dostepem
- Sprawdz TRACE — czy zwraca cookies/auth headers?

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Identity Crisis | Testowanie roznych odpowiedzi na rozne metody HTTP i User-Agenty | [GitHub](https://github.com/EnableSecurity/Identity-Crisis) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.5.3 | Browser Origin Separation | Verify that HTTP requests to sensitive functionality use appropriate HTTP methods such as POST, PUT, PATCH, or DELETE, and not methods defined by the HTTP specification as "safe" such as HEAD, OPTIONS, or GET. Alternatively, strict validation of the Sec-Fetch-* request header fields can be used to ensure that the request did not originate from an inappropriate cross-origin call, a navigation request, or a resource load (such as an image source) where this is not expected. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.1.4 | Generic Web Service Security | Verify that only HTTP methods that are explicitly supported by the application or its API (including OPTIONS during preflight requests) can be used and that unused methods are blocked. |


---

## HackTricks Tips

- **HEAD traktowany jako GET** w niektórych frameworkach (Oak, etc.) — może ominąć CSRF checks
- **`X-HTTP-Method-Override: DELETE`** → dostęp do non-POST handlerów bez CSRF protection
