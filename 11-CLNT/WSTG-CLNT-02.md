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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — DOM_based_XSS_Prevention_Cheat_Sheet.md, Cross_Site_Scripting_Prevention_Cheat_Sheet.md

### DOM-based JavaScript Execution — sinki

- **eval()**: wykonanie dowolnego kodu JS — najniebezpieczniejszy
- **Function()**: `new Function('alert(1)')()` — rownowazne eval
- **setTimeout/setInterval**: z argumentem string — `setTimeout("alert(1)", 1000)`
- **innerHTML/outerHTML**: wstawia HTML z potencjalnym JS
- **document.write/writeln**: wstawia HTML do dokumentu
- **element.setAttribute**: np. `setAttribute("onclick", user_input)`
- **javascript: URI**: `location = "javascript:alert(1)"`

### Zrodla (sources) danych uzytkownika w DOM

- `location.hash`, `location.search`, `location.href`
- `document.referrer`
- `document.cookie`
- `window.name`
- `postMessage` data
- `localStorage/sessionStorage`
- URL parameters via frameworks (React Router, Vue Router)

### Obrona

- **NIGDY** nie uzywaj `eval()`, `Function()`, `setTimeout/setInterval` z danymi uzytkownika
- Uzyj `textContent` zamiast `innerHTML` — nie interpretuje HTML/JS
- Sanityzuj HTML: **DOMPurify** — jedyna zaufana biblioteka client-side
- CSP: `script-src 'self'` — blokuje inline JS i eval
- Uzyj frameworkow (React, Vue, Angular) — domyslnie enkoduja output

### JSONP — ryzyko

- Callback parameter: `?callback=alert(1)` — wykonanie dowolnego JS
- JSONP jest **przestarzale** — uzywaj CORS + JSON zamiast JSONP
- Jesli musisz uzywac: waliduj callback — allowlist dozwolonych nazw funkcji

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| ESLinter | Lintowanie JS z regulami bezpieczenstwa w Burp | [GitHub](https://github.com/parsiya/eslinter) |
| JSpector | Wyciaganie endpointow i niebezpiecznych metod z plikow JS | [GitHub](https://github.com/hisxo/JSpector) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.2 | Sanitization | Verify that the application avoids the use of eval() or other dynamic code execution features such as Spring Expression Language (SpEL). Where there is no alternative, any user input being included must be sanitized before being executed. |
| V1.2.3 | Injection Prevention | Verify that output encoding or escaping is used when dynamically building JavaScript content (including JSON), to avoid changing the message or document structure (to avoid JavaScript and JSON injection). |
