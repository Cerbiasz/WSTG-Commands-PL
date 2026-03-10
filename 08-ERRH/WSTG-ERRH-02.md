# WSTG-ERRH-02 — Testing for Stack Traces

## Cele

- Zidentyfikowac wyjscie stack trace w odpowiedziach aplikacji
- Ocenic ujawnianie informacji przez stack traces

## KOMENDY

### Wymuszenie stack trace przez nieprawidlowy typ danych

```bash
curl -v "TARGET/page?id=abc"
curl -v "TARGET/page?id[]=1"
curl -v "TARGET/page?id=null"

```

### Wymuszenie stack trace przez dzielenie przez zero

```bash
curl -v "TARGET/calc?value=0"
curl -v "TARGET/page?amount=0&operation=divide"

```

### Wymuszenie stack trace przez nieprawidlowe kodowanie

```bash
curl -v "TARGET/page?param=%zz"
curl -v "TARGET/page?param=%00"

```

### Wymuszenie stack trace przez buffer overflow w parametrach

```bash
curl -v "TARGET/page?param=$(python3 -c "print('A'*50000)")"

```

### Testowanie trybu debug

```bash
curl -v "TARGET/?debug=true"
curl -v "TARGET/?debug=1"
curl -v "TARGET/?trace=true"
curl -v "TARGET/?show_errors=1"
curl -v "TARGET/debug"
curl -v "TARGET/trace.axd"
curl -v "TARGET/elmah.axd"
curl -v "TARGET/phpinfo.php"
curl -v "TARGET/_debugbar"
curl -v "TARGET/__debug__/"

```

### Wymuszenie bledow w API

```bash
curl -v -X POST TARGET/api/endpoint -H "Content-Type: application/json" -d 'null'
curl -v -X POST TARGET/api/endpoint -H "Content-Type: application/json" -d '{"key": undefined}'
curl -v -X POST TARGET/api/endpoint -H "Content-Type: application/json" -d '[]'

```

### Wymuszenie bledu przez nieprawidlowe sesje/tokeny

```bash
curl -v TARGET/ -H "Cookie: session=invalid_session_value_12345"
curl -v TARGET/ -H "Authorization: Bearer invalid.token.here"

```

### Wymuszenie bledu przez XML

```bash
curl -v -X POST TARGET/api -H "Content-Type: application/xml" -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe "test">]><foo>&xxe;</foo>'

```

### Testowanie endpointow zdrowia/diagnostyki

```bash
curl -v TARGET/health
curl -v TARGET/status
curl -v TARGET/actuator
curl -v TARGET/actuator/env
curl -v TARGET/actuator/heapdump

```

### Nmap skanowanie debug endpointow

```bash
nmap --script http-errors,http-trace -p 80,443 TARGET

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test manualny

```bash
# Stack traces sa najczesciej wyzwalane przez logike a nie fuzzing

```

### Opcjonalnie: fuzzowanie debug parametrow (fuzzdb)

```bash
ffuf -u "TARGET/?FUZZ=true" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/CommonDebugParamNames.txt -mc all -c
ffuf -u "TARGET/?FUZZ=true" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/DebugParams.Json.fuzz.txt -mc all -c

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Repeater: wyslij zmodyfikowane requesty z nieprawidlowymi typami danych
2. Szukaj w odpowiedziach: "Exception", "Traceback", "Stack Trace", "at line",
```bash
   "NullPointerException", "SqlException", "Error in", "Fatal error"
```

3. Sprawdz czy stack traces ujawniaja: sciezki plikow, numery linii kodu, nazwy klas,
```bash
   wersje frameworkow, connection strings, nazwy tabel bazy danych
```

4. Testuj rozne Content-Types (application/json, application/xml, multipart/form-data)
```bash
   z nieprawidlowymi danymi
```

5. W DevTools -> Network: sprawdz odpowiedzi pod katem ukrytych informacji debugowania
6. Sprawdz naglowki odpowiedzi pod katem X-Debug-Token, X-Debug-Token-Link
7. Zrob screenshot kazdego znalezionego stack trace jako dowod


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Error_Handling_Cheat_Sheet.md

### Co stack trace moze ujawnic atakujacemu

- **Technologie**: `com.opensymphony.xwork2` → Struts2, `Apache Tomcat/7.0.56` → konkretna wersja z CVE
- **Sciezki plikow**: `D:\app\index_new.php on line 188` → struktura aplikacji
- **Zapytania SQL**: `odbc_fetch_array()` → typ bazy danych, mozliwy injection point
- **Klasy i metody**: `java.lang.NumberFormatException.forInputString()` → logika biznesowa
- **Connection strings**: dane dostepu do bazy, hosty wewnetrzne

### Wylaczanie stack traces na produkcji

- **Java/Spring**: ustaw `server.error.include-stacktrace=never` w `application.properties`
- **ASP.NET Core**: NIE uzywaj `app.UseDeveloperExceptionPage()` na produkcji — uzywaj `app.UseExceptionHandler()`
- **ASP.NET**: `<customErrors mode="RemoteOnly">` lub `mode="On"` w Web.config
- **PHP**: `display_errors = Off`, `log_errors = On` w php.ini
- **Django**: `DEBUG = False` w settings.py (KRYTYCZNE)
- **Node.js/Express**: NIE uzywaj `app.use(errorHandler())` na produkcji — custom middleware z generycznym response

### Globalny error handler — wzorzec

- Przechwytuj WSZYSTKIE nieobsluzowane wyjatki na najwyzszym poziomie
- Loguj pelny stack trace SERVER-SIDE (do plikow logow, SIEM, ELK)
- Zwracaj uzytkownikowi TYLKO generyczny komunikat: `{"message":"An error occurred"}`
- Uzywaj RFC 7807 (Problem Details) w REST API: `Content-Type: application/problem+json`

### Debug endpointy do sprawdzenia

- `/actuator`, `/actuator/env`, `/actuator/heapdump` — Spring Boot Actuator
- `/trace.axd`, `/elmah.axd` — ASP.NET diagnostics
- `/phpinfo.php` — PHP info (ujawnia cala konfiguracje)
- `/_debugbar`, `/__debug__/` — Laravel/Django debug toolbars
- `?debug=true`, `?trace=true`, `?show_errors=1` — debug query params

### Monitoring i alerting

- Monitoruj bledy 5xx — wskazuja na nieoczekiwane awarie, potencjalne ataki
- Loguj WSZYSTKIE nieobsluzowane wyjatki jako zdarzenia wysokiego priorytetu
- Alertuj na nagly wzrost bledow — moze wskazywac na atak fuzzing/injection
- Uzywaj centralnego systemu logowania (ELK, Splunk, SIEM) do korelacji bledow

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Error Message Checks | Pasywne skanowanie pod katem ujawnionych komunikatow bledow | [GitHub](https://github.com/augustd/burp-suite-error-message-checks) |
