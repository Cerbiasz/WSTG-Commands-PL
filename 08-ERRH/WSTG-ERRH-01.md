# WSTG-ERRH-01 — Testing for Improper Error Handling

## Cele

- Zidentyfikowac istniejace wyjscia bledow (error output)
- Przeanalizowac rozne typy zwracanych odpowiedzi bledow

## KOMENDY

### Wymuszenie bledu 404 (Not Found)

```bash
curl -s -o /dev/null -w "%{http_code}\n" TARGET/nieistniejaca-strona-12345

```

### Wymuszenie bledu 404 z pelna odpowiedzia

```bash
curl -v TARGET/nieistniejaca-strona-12345

```

### Wymuszenie bledu 500 (Internal Server Error) za pomoca nieprawidlowych parametrow

```bash
curl -v "TARGET/search?q=%00%ff%fe"

```

### Wymuszenie bledu 403 (Forbidden)

```bash
curl -v TARGET/.htaccess
curl -v TARGET/admin/
curl -v TARGET/server-status

```

### Wysylanie nieprawidlowego Content-Type

```bash
curl -v -X POST TARGET/login -H "Content-Type: application/xml" -d '<<<invalid'

```

### Wysylanie zdjeformatowanego JSON

```bash
curl -v -X POST TARGET/api/endpoint -H "Content-Type: application/json" -d '{invalid json###'

```

### Wysylanie bardzo dlugiego URL

```bash
curl -v "TARGET/$(python3 -c "print('A'*10000)")"

```

### Wysylanie nieprawidlowej metody HTTP

```bash
curl -v -X PATCH TARGET/
curl -v -X DELETE TARGET/
curl -v -X PROPFIND TARGET/

```

### Wysylanie nieprawidlowych naglowkow

```bash
curl -v -H "Host: " TARGET/
curl -v -H "Content-Length: -1" TARGET/

```

### Testowanie overflow parametrow

```bash
curl -v "TARGET/page?id=99999999999999999999"
curl -v "TARGET/page?id=-1"
curl -v "TARGET/page?id=abc"

```

### Wymuszenie bledow SQL (jezeli istnieje injection)

```bash
curl -v "TARGET/page?id=1'"
curl -v "TARGET/page?id=1%27%20OR%201=1--"

```

### Nmap skanowanie stron bledow

```bash
nmap --script http-errors -p 80,443 TARGET

```

### Nikto skanowanie bledow konfiguracji

```bash
nikto -h TARGET -Tuning 3

```

### Burp Suite - testowanie odpowiedzi na bledy

```bash
# 1. Uruchom Burp Suite -> Proxy -> Intercept
# 2. Przechwytuj request i modyfikuj parametry na nieprawidlowe wartosci
# 3. Obserwuj odpowiedzi serwera pod katem ujawniania informacji

```

## KOMENDY Z WORDLISTAMI

### Fuzzowanie sciezek w celu wymuszenia bledow (fuzzdb disclosure-directory)

```bash
ffuf -u TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/attack/disclosure-directory/directory-indexing-generic.txt -mc all -fc 200,301,302 -c

```

### Fuzzowanie z payload'ami naughty strings (SecLists)

```bash
ffuf -u "TARGET/search?q=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/big-list-of-naughty-strings.txt -mc all -fc 200 -c

```

### Wfuzz testowanie bledow na roznych endpointach

```bash
wfuzz -c --hc 200,301,302 -w Desktop/WSTG/fuzzdb-master/attack/disclosure-directory/directory-indexing-generic.txt TARGET/FUZZ

```

### Fuzzowanie parametrow wyzwalajacych bledy

```bash
ffuf -u "TARGET/page?FUZZ=test" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/CommonDebugParamNames.txt -mc all -fc 200 -c

```

### Fuzzowanie z debug param names (fuzzdb)

```bash
ffuf -u "TARGET/?FUZZ=true" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/DebugParams.Json.fuzz.txt -mc all -fc 200 -c

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz przegladarke i odwiedz nieistniejace strony - sprawdz czy strony bledow ujawniaja
```bash
   technologie (np. Apache, Nginx, IIS, Tomcat, wersje frameworkow)
```

2. W Burp Suite -> Repeater: wyslij requesty z nieprawidlowymi danymi i analizuj odpowiedzi
3. Sprawdz czy bledy zawieraja sciezki plikow, nazwy bazy danych, stack traces
4. Sprawdz czy rozne kody bledow (400, 403, 404, 405, 500, 502, 503) zwracaja rozne informacje
5. Sprawdz naglowki odpowiedzi pod katem Server, X-Powered-By, X-AspNet-Version
6. Zrob screenshot kazdej unikalnej strony bledu jako dowod


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Error_Handling_Cheat_Sheet.md

### Dlaczego error handling jest krytyczny

- Nieobsluzony blad moze ujawnic: nazwe i wersje serwera, frameworki, sciezki plikow, zapytania SQL, connection strings, nazwy tabel
- Atakujacy wykorzystuja te informacje w fazie **Reconnaissance** — identyfikacja technologii, injection points, wersji z znanymi CVE
- Przyklad: stack trace Struts2/Tomcat ujawnia `com.opensymphony.xwork2` + `Apache Tomcat/7.0.56` — atakujacy wie co atakowac

### Zasady ogolne

- **Generyczne odpowiedzi dla uzytkownika** — zwracaj ogolny komunikat np. `{"message":"An error occurred, please retry"}`
- **Szczegolowe logowanie SERVER-SIDE** — loguj pelny stack trace, request details, user context po stronie serwera
- **Obsluz WSZYSTKIE typy wyjatkow** — nieobsluzony wyjatek moze ujawnic wrazliwe dane techniczne
- **Wdroz globalny error handler** — zapobiegaj niespojnym odpowiedziom na roznych endpointach
- **Uzywaj kodow HTTP poprawnie**: 4xx dla bledow klienta (unauthorized, bad request), 5xx dla bledow serwera
- **RFC 7807** (Problem Details for HTTP APIs) — standardowy format odpowiedzi bledow w REST API: `application/problem+json`

### Globalny error handler — konfiguracja wg technologii

- **Standard Java (web.xml)**: `<error-page><exception-type>java.lang.Exception</exception-type><location>/error.jsp</location></error-page>`
- **Spring MVC/Boot**: klasa z `@RestControllerAdvice` + `@ExceptionHandler(Exception.class)` zwracajaca `ProblemDetail` (Spring 6+ RFC 7807)
- **ASP.NET Core**: `app.UseExceptionHandler("/api/error")` w `Startup.cs` — dedykowany ErrorController zwraca generyczny JSON
  - W DEV: `app.UseDeveloperExceptionPage()` — WYLACZ na produkcji
  - `app.UseStatusCodePages()` — custom odpowiedzi dla kodow statusu
- **ASP.NET Web API (.NET Framework)**: zarejestruj `ExceptionLogger` + `ExceptionHandler` w `WebApiConfig.Register()`
  - `config.Services.Replace(typeof(IExceptionLogger), new GlobalErrorLogger())`
  - `config.Services.Replace(typeof(IExceptionHandler), new GlobalErrorHandler())`
  - `<customErrors mode="RemoteOnly">` w Web.config

### Co NIE powinno byc w odpowiedzi bledu

- Stack traces, numery linii kodu, nazwy klas
- Sciezki plikow (`D:\app\index_new.php on line 188`)
- Zapytania SQL, connection strings, nazwy tabel
- Wersje serwera, frameworka, bibliotek
- Zmienne srodowiskowe, konfiguracja

### Kody HTTP — poprawne uzycie

- **4xx** — blad klienta: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 405 Method Not Allowed, 429 Too Many Requests
- **5xx** — blad serwera: 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable
- Monitoruj bledy 5xx — wskazuja na nieoczekiwane awarie aplikacji
- NIE zwracaj szczegolow implementacji w body odpowiedzi — uzywaj generycznych komunikatow

### Dodatkowe najlepsze praktyki

- Dodaj header `X-ERROR: true` do odpowiedzi bledow — ulatwia client-side error handling
- Uzywaj [Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html) do prawidlowego logowania bledow
- Testuj error handling na produkcji — upewnij sie ze debug mode jest WYLACZONY
- Sprawdz czy reverse proxy/CDN nie dodaje wlasnych stron bledow z informacjami technicznymi

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Error Message Checks | Pasywne wykrywanie komunikatow bledow ujawniajacych informacje | [GitHub](https://github.com/augustd/burp-suite-error-message-checks) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V16.5.1 | Error Handling | Verify that a generic message is returned to the consumer when an unexpected or security-sensitive error occurs, ensuring no exposure of sensitive internal system data such as stack traces, queries, secret keys, and tokens. |
| V16.5.2 | Error Handling | Verify that the application continues to operate securely when external resource access fails, for example, by using patterns such as circuit breakers or graceful degradation. |
| V16.5.3 | Error Handling | Verify that the application fails gracefully and securely, including when an exception occurs, preventing fail-open conditions such as processing a transaction despite errors resulting from validation logic. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V16.5.4 | Error Handling | Verify that a "last resort" error handler is defined which will catch all unhandled exceptions. This is both to avoid losing error details that must go to log files and to ensure that an error does not take down the entire application process, leading to a loss of availability. |
