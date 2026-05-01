# WSTG-ERRH-02 — Testing for Stack Traces

## Cel

Wykrycie ujawnienia stack trace w odpowiedziach. Stack trace ujawnia: nazwy klas/metod, ścieżki plików w systemie, numery linii, łańcuch wywołań — wszystko co potrzebne do exploit development. Krytyczna pre-condition dla wielu zaawansowanych ataków.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-errh-02-stack-trace.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-errh-02.jsonl
```

Szablon w jednym requeście z dedicated matcherami per stack: Java/JVM (at file.java:N), Spring (org.springframework.*), Python traceback, Django (DEBUG=True yellow), Flask/Werkzeug, Ruby, Rails (Action Controller Exception), Node.js (at func (/path/file.js:N)), Express, PHP (Warning/Fatal in /path/file.php on line N), Laravel Whoops, Symfony Exception, ASP.NET ([Exception:]), .NET Core, Go panic.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Cross-ref: WSTG-ERRH-01 dla kompleksowego error handling
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-errh-01-error-page.yaml

# Cross-ref: WSTG-CONF-02 platform config (debug mode detection)
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-02-platform-config.yaml

# Misconfiguration: stack-related
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/ -tags trace
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Java/JVM stack trace | ✓ | — |
| Spring framework markers | ✓ | — |
| Python traceback (generic + Django + Flask) | ✓ | — |
| Ruby / Rails | ✓ | — |
| Node.js / Express | ✓ | — |
| PHP (warnings, fatal, Laravel, Symfony) | ✓ | — |
| ASP.NET / .NET Core | ✓ | — |
| Go panic / runtime error | ✓ | — |
| Rust panic | częściowe (Go pattern matchuje czasem) | osobno |
| C/C++ stack trace (rare in web) | — | poza zakresem |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Trigger errors**: malformed input (null, array, oversized), invalid types (NaN, Infinity), special chars (`%00`).
2. **Stack-specific triggers**: dla zidentyfikowanego stacka (z WSTG-INFO-08), użyj specific framework triggers.
3. **Per endpoint test**: niektóre endpointy mają lepsze error handling niż inne — testować szeroko.
4. **Authenticated vs anonymous**: czasem authenticated pokazuje więcej (debug aktywny gdy admin token).
5. **Path extraction**: dla każdego znalezionego stack trace, ekstraktuj filesystem paths jako pivot do LFI/source disclosure.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Python traceback markers
- [ ] Java `at com.X.method(File.java:N)` patterns
- [ ] PHP `in /path/file.php on line N`
- [ ] ASP.NET `[Exception: ...]`
- [ ] Node.js `at function (/path/file.js:N:M)`
- [ ] Ruby `.rb:N:in` patterns
- [ ] Go `panic: runtime error`
- [ ] Per stack (z INFO-08): targeted error trigger
- [ ] Filesystem paths extracted (jako recon dla LFI)
- [ ] Class/method names extracted (jako recon dla source code disclosure)

### Per stack — typowe triggery

| Stack | Trigger | Typowa stack trace marker |
|---|---|---|
| Spring Boot | `?id=invalid` na typed param | `org.springframework.web.method.annotation.MethodArgumentTypeMismatchException` |
| Django | `?invalid_filter[]=x` | `<title>FieldError at /...</title>` + DEBUG yellow page |
| Flask/Werkzeug | malformed body JSON | `werkzeug.exceptions.BadRequest` + traceback |
| Rails | `/users/abc.json` (string zamiast int) | Action Controller: Exception |
| Express | `?json={"a":1` (malformed) | SyntaxError + at body-parser |
| Laravel | `?id[]=array` zamiast string | Whoops error page z Illuminate exception |
| ASP.NET MVC | `/Home/Index/abc` (int param) | YSD z ModelBindingException |
| PHP (raw) | array param when string expected | `Warning: Array to string conversion` |
| Go (Gin/Echo) | malformed JSON body | `panic: runtime error: invalid memory` (rare ale ujawnia path) |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Error_Handling_Cheat_Sheet.md

### Co stack trace może ujawnić atakującemu

- **Technologie**: `com.opensymphony.xwork2` → Struts2, `Apache Tomcat/7.0.56` → konkretna wersja z CVE
- **Ścieżki plików**: `D:\app\index_new.php on line 188` → struktura aplikacji
- **Zapytania SQL**: `odbc_fetch_array()` → typ bazy danych, możliwy injection point
- **Klasy i metody**: `java.lang.NumberFormatException.forInputString()` → logika biznesowa
- **Connection strings**: dane dostępu do bazy, hosty wewnętrzne

### Wyłączanie stack traces na produkcji

- **Java/Spring**: ustaw `server.error.include-stacktrace=never` w `application.properties`
- **ASP.NET Core**: NIE używaj `app.UseDeveloperExceptionPage()` na produkcji — używaj `app.UseExceptionHandler()`
- **ASP.NET**: `<customErrors mode="RemoteOnly">` lub `mode="On"` w Web.config
- **PHP**: `display_errors = Off`, `log_errors = On` w php.ini
- **Django**: `DEBUG = False` w settings.py (KRYTYCZNE)
- **Node.js/Express**: NIE używaj `app.use(errorHandler())` na produkcji — custom middleware z generycznym response

### Globalny error handler — wzorzec

- Przechwytuj WSZYSTKIE nieobsłużone wyjątki na najwyższym poziomie
- Loguj pełny stack trace SERVER-SIDE (do plików logów, SIEM, ELK)
- Zwracaj użytkownikowi TYLKO generyczny komunikat: `{"message":"An error occurred"}`
- Używaj RFC 7807 (Problem Details) w REST API: `Content-Type: application/problem+json`

### Debug endpointy do sprawdzenia

- `/actuator`, `/actuator/env`, `/actuator/heapdump` — Spring Boot Actuator
- `/trace.axd`, `/elmah.axd` — ASP.NET diagnostics
- `/phpinfo.php` — PHP info (ujawnia całą konfigurację)
- `/_debugbar`, `/__debug__/` — Laravel/Django debug toolbars
- `?debug=true`, `?trace=true`, `?show_errors=1` — debug query params

### Monitoring i alerting

- Monitoruj błędy 5xx — wskazują na nieoczekiwane awarie, potencjalne ataki
- Loguj WSZYSTKIE nieobsłużone wyjątki jako zdarzenia wysokiego priorytetu
- Alertuj na nagły wzrost błędów — może wskazywać na atak fuzzing/injection
- Używaj centralnego systemu logowania (ELK, Splunk, SIEM) do korelacji błędów

## Pentesterskie deep dive

### Mniej znane techniki

- **Stack trace via deserialization**: dla aplikacji deserializujących input (Java ObjectInputStream, PHP unserialize, Python pickle), malformed serialized data zwraca stack trace zawierający chain klas — pivot do gadget chain.
- **Spring Cloud Function SpEL via header**: `spring.cloud.function.routing-expression: T(java.lang.Runtime).getRuntime().exec(...)` — jeśli stack trace ujawnia SpEL active, CVE-2022-22963.
- **`/error` endpoint Spring Boot**: domyślny `/error` endpoint z parametrami `?path=/admin&trace=true` może wymusić zwrócenie pełnego trace.
- **PHP `display_errors=stderr` redirected**: niektóre konfiguracje przekierowują stderr do response (rzadkie ale istnieje).
- **TimeoutError stack** w long-running queries: timeout na DB query często zwraca stack z internal IPs i query.
- **Async/await stack trace differences**: stack trace z async functions w Node.js / Python pokazuje internal scheduler frames — ujawnia wersję framework.

### Common pitfalls

- **WAF blocking stack trace markers**: Cloudflare/AWS WAF mają reguły blokujące responses zawierające `at com.`, `Traceback` — może maskować findings.
- **Custom 500 page przesłaniający stack**: dobrze zhardenowana aplikacja zwraca custom 500 ale internal logging dalej widzi trace. Z perspektywy pentestera = brak finding.
- **Different stack per HTTP method**: GET zwraca generic 500, POST z body parsing error daje stack — testować wszystkie metody.

### Świeżynki z research

- **Stack trace driven recon for CVE matching** — community pattern; framework version z stack trace + NVD search = znane CVE.
- **GraphQL introspection blocked ale errors leak schema** — community pattern; unknown field error reveals lookalike valid fields.
- **HackTricks per-framework error handling**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Wykrywanie wersji w stack traces | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Reflector | Detekcja reflected user input w error responses | [GitHub](https://github.com/elkokc/reflector) |
| Backslash Powered Scanner | Probe-based input mutation → error trigger | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/08-Testing_for_Error_Handling/02-Testing_for_Stack_Traces
- OWASP Error Handling Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html
- CWE-209: https://cwe.mitre.org/data/definitions/209.html
- HackTricks Pentesting Web: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V7.4.1 | Error Handling (L1) | Generic message returned. |
| V7.4.2 | Error Handling (L2) | Application logs all unhandled exceptions. |
| V13.4.6 | Information Leakage (L3) | No detailed version information of backend components. |
