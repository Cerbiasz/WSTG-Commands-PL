# WSTG-ERRH-01 — Testing for Improper Error Handling

## Cel

Wykrycie ujawnienia szczegółów technicznych w odpowiedziach na błędy (4xx/5xx) — server banner, framework version, file paths, SQL fragments. Atakujący wykorzystuje te informacje w fazie rekonesansu do CVE matching i pivot do konkretnych ataków.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-errh-01-error-page.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-errh-01.jsonl
```

Szablon w 3 grupach: forced 404 + analiza error page (server banner, filesystem paths), forced 500 via malformed query (Django yellow page, ASP.NET YSD, PHP warnings, Laravel Whoops, Rails dev page, Symfony, Java/Spring stack trace, Werkzeug, SQL errors), 405 Method Not Allowed via PROPFIND.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Misconfiguration directory ma wzorce na error pages
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/ -tags errordisclosure

# Cross-ref WSTG-CONF-02 platform config (debug consoles, verbose errors)
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-02-platform-config.yaml

# Cross-ref WSTG-ERRH-02 dla pełnego stack trace coverage
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-errh-02-stack-trace.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Default error pages (Apache/Nginx/IIS/Tomcat) | ✓ | — |
| Forced 404 + server banner | ✓ | — |
| Forced 500 + framework markers | ✓ | — |
| Django/Rails/ASP.NET/PHP/Laravel/Symfony specific errors | ✓ | — |
| SQL errors w error pages | ✓ | (cross WSTG-INPV-05) |
| Filesystem path disclosure | ✓ | — |
| Stack trace specifically | częściowe | osobno → WSTG-ERRH-02 |
| Custom error pages bypass | — | manual z różnymi inputs |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Forced errors arsenal**: random nonexistent path (404), malformed query (500), special chars (`%00`, `%3C%3E`), oversized headers, PROPFIND/JUNK methods.
2. **Per status analysis**: zbierać responses 400/401/403/404/405/500/502/503/504 — każdy może ujawnić różne info.
3. **Stack-specific markers**: znajomość frameworka pozwala targeted error trigger (np. Django `?_invalid_filter=`, Rails `/admin/.invalid`, ASP.NET `/<>`).
4. **Custom error page audit**: nawet zhardenowane aplikacje mogą mieć custom 500 page który nadal ujawnia framework przez body markers (logo, footer text).
5. **CDN behavior**: porównanie 404 z CDN vs origin — czasem origin error pages dostępne przez direct backend.

### Co MUSI być sprawdzone (10 punktów)

- [ ] 404 → server banner w body (Apache/Nginx/IIS/Tomcat default page)
- [ ] 500 → stack trace, file paths, SQL queries
- [ ] 4xx różne → różne informacje per status
- [ ] PROPFIND / OPTIONS na nieobsługiwane endpointy
- [ ] Malformed query parameters → debug info
- [ ] Special chars w path/query → error fallback
- [ ] Oversized headers (`A` × 10000) → server-side parser error
- [ ] Custom 500 page review — czy zawiera tech markers
- [ ] Headers w error responses (X-Powered-By, Server)
- [ ] CDN vs origin error response delta

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Error_Handling_Cheat_Sheet.md

### Dlaczego error handling jest krytyczny

- Nieobsłużony błąd może ujawnić: nazwę i wersję serwera, frameworki, ścieżki plików, zapytania SQL, connection strings, nazwy tabel
- Atakujący wykorzystują te informacje w fazie **Reconnaissance** — identyfikacja technologii, injection points, wersji z znanymi CVE
- Przykład: stack trace Struts2/Tomcat ujawnia `com.opensymphony.xwork2` + `Apache Tomcat/7.0.56` — atakujący wie co atakować

### Zasady ogólne

- **Generyczne odpowiedzi dla użytkownika** — zwracaj ogólny komunikat np. `{"message":"An error occurred, please retry"}`
- **Szczegółowe logowanie SERVER-SIDE** — loguj pełny stack trace, request details, user context po stronie serwera
- **Obsłuż WSZYSTKIE typy wyjątków** — nieobsłużony wyjątek może ujawnić wrażliwe dane techniczne
- **Wdróż globalny error handler** — zapobiegaj niespójnym odpowiedziom na różnych endpointach
- **Używaj kodów HTTP poprawnie**: 4xx dla błędów klienta (unauthorized, bad request), 5xx dla błędów serwera
- **RFC 7807** (Problem Details for HTTP APIs) — standardowy format odpowiedzi błędów w REST API: `application/problem+json`

### Globalny error handler — konfiguracja wg technologii

- **Standard Java (web.xml)**: `<error-page><exception-type>java.lang.Exception</exception-type><location>/error.jsp</location></error-page>`
- **Spring MVC/Boot**: klasa z `@RestControllerAdvice` + `@ExceptionHandler(Exception.class)` zwracająca `ProblemDetail` (Spring 6+ RFC 7807)
- **ASP.NET Core**: `app.UseExceptionHandler("/api/error")` w `Startup.cs` — dedykowany ErrorController zwraca generyczny JSON
  - W DEV: `app.UseDeveloperExceptionPage()` — WYŁĄCZ na produkcji
  - `app.UseStatusCodePages()` — custom odpowiedzi dla kodów statusu
- **ASP.NET Web API (.NET Framework)**: zarejestruj `ExceptionLogger` + `ExceptionHandler` w `WebApiConfig.Register()`
  - `config.Services.Replace(typeof(IExceptionLogger), new GlobalErrorLogger())`
  - `config.Services.Replace(typeof(IExceptionHandler), new GlobalErrorHandler())`
  - `<customErrors mode="RemoteOnly">` w Web.config

### Co NIE powinno być w odpowiedzi błędu

- Stack traces, numery linii kodu, nazwy klas
- Ścieżki plików (`D:\app\index_new.php on line 188`)
- Zapytania SQL, connection strings, nazwy tabel
- Wersje serwera, frameworka, bibliotek
- Zmienne środowiskowe, konfiguracja

### Kody HTTP — poprawne użycie

- **4xx** — błąd klienta: 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 405 Method Not Allowed, 429 Too Many Requests
- **5xx** — błąd serwera: 500 Internal Server Error, 502 Bad Gateway, 503 Service Unavailable
- Monitoruj błędy 5xx — wskazują na nieoczekiwane awarie aplikacji
- NIE zwracaj szczegółów implementacji w body odpowiedzi — używaj generycznych komunikatów

### Dodatkowe najlepsze praktyki

- Dodaj header `X-ERROR: true` do odpowiedzi błędów — ułatwia client-side error handling
- Używaj [Logging Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html) do prawidłowego logowania błędów
- Testuj error handling na produkcji — upewnij się że debug mode jest WYŁĄCZONY
- Sprawdź czy reverse proxy/CDN nie dodaje własnych stron błędów z informacjami technicznymi

## Pentesterskie deep dive

### Mniej znane techniki

- **Forced TypeError via array params**: `?id[]=1&id[]=2` zamiast `?id=1` — niektóre frameworki (PHP, Express) zwracają stack trace gdy oczekują string a dostają array.
- **`Accept` header confusion**: `Accept: application/xml` na endpoincie który normalnie zwraca JSON może wymusić error w content negotiation.
- **HTTP/1.0 vs HTTP/1.1 differences**: `curl --http1.0` może wymusić error gdy aplikacja oczekuje konkretnych headers.
- **Oversized body / header**: 100MB body lub `User-Agent: A × 100000` — często wywołuje server-side parsing error.
- **Reverse proxy 502 leak**: gdy backend down, proxy zwraca 502 z banner backendu (np. `proxy_pass http://internal-backend:8080` — internal hostname leaked).
- **JSON parse error reflects malformed input**: `{"id":1,"name":"<script>` może być reflectowane w error message (cross XSS).

### Common pitfalls

- **CDN custom error pages**: Cloudflare zwraca własną stronę 502/520/521 — może maskować prawdziwy backend status.
- **`debug=1` query params**: legacy aplikacje akceptują `?debug=1`, `?show_errors=1` które aktywują verbose mode bez auth.
- **Production database dev endpoint**: niektóre aplikacje mają `/health/db` ujawniające connection string przy błędzie.

### Świeżynki z research

- **GraphQL field suggestion errors** — community pattern; `query{user(id:1){nonexistent}}` zwraca podpowiedzi z lookalike fields.
- **API gateway error formats** — różne formaty error response per gateway (AWS API Gateway, Azure API Management, Kong) ujawniają provider.
- **HackTricks Pentesting Web — Error Pages**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Detekcja info disclosure w error responses | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Backslash Powered Scanner | Probe-based detection of error-disclosing inputs | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
| Param Miner | Hidden parameter discovery (debug params) | [GitHub](https://github.com/PortSwigger/param-miner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/08-Testing_for_Error_Handling/01-Testing_for_Improper_Error_Handling
- OWASP Error Handling Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html
- RFC 7807 (Problem Details): https://datatracker.ietf.org/doc/html/rfc7807
- HackTricks Pentesting Web: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V7.4.1 | Error Handling (L1) | Generic message returned for all error states. |
| V7.4.2 | Error Handling (L2) | Application logs all unhandled exceptions. |
| V7.4.3 | Error Handling (L2) | All errors logged including unexpected error conditions. |
