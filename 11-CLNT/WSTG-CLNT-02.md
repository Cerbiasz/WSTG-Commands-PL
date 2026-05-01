# WSTG-CLNT-02 — Testing for JavaScript Execution

## Cel

Wykrycie miejsc gdzie aplikacja wykonuje user-controlled JavaScript przez sinki `eval`, `Function`, `setTimeout(string)`. To podzbiór DOM XSS — ale specyficznie focus na execution sinks (nie HTML rendering).

> **Test mostly manual**: wymaga static analysis JS bundles + tracing source-to-sink. Cross-ref WSTG-CLNT-01.

## Automatyzacja Nuclei

```bash
# WSTG-CLNT-01 wykrywa eval/Function/setTimeout markery
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-01-dom-xss.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Static analysis JS bundles**: `grep -nE "\\beval\\(|new Function\\(|setTimeout\\([\"']" main.js`.
2. **Source tracing**: per znaleziony sink, prześledź skąd pochodzi argument (location.hash? postMessage? localStorage?).
3. **JSONP endpoints**: szukaj `?callback=` parametrów - zwracają executable JS.
4. **JSONP callback validation test**: `?callback=alert(1)//` - czy aplikacja waliduje callback name?
5. **Burp DOM Invader**: aktywna analiza w przeglądarce.

### Co MUSI być sprawdzone (8 punktów)

- [ ] `eval()` calls per JS bundle
- [ ] `new Function()` calls
- [ ] `setTimeout/setInterval` z string parameter
- [ ] `setAttribute("onclick", ...)` event handlers
- [ ] JSONP endpoints (`?callback=`)
- [ ] WebSocket message handlers wykonujące JS
- [ ] iframe `src="javascript:"` patterns
- [ ] `location.href = "javascript:"` patterns

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — DOM_based_XSS_Prevention_Cheat_Sheet.md, Cross_Site_Scripting_Prevention_Cheat_Sheet.md

### DOM-based JavaScript Execution — sinki

- **eval()**: wykonanie dowolnego kodu JS — najniebezpieczniejszy
- **Function()**: `new Function('alert(1)')()` — równoważne eval
- **setTimeout/setInterval**: z argumentem string — `setTimeout("alert(1)", 1000)`
- **innerHTML/outerHTML**: wstawia HTML z potencjalnym JS
- **document.write/writeln**: wstawia HTML do dokumentu
- **element.setAttribute**: np. `setAttribute("onclick", user_input)`
- **javascript: URI**: `location = "javascript:alert(1)"`

### Źródła (sources) danych użytkownika w DOM

- `location.hash`, `location.search`, `location.href`
- `document.referrer`
- `document.cookie`
- `window.name`
- `postMessage` data
- `localStorage/sessionStorage`
- URL parameters via frameworks (React Router, Vue Router)

### Obrona

- **NIGDY** nie używaj `eval()`, `Function()`, `setTimeout/setInterval` z danymi użytkownika
- Użyj `textContent` zamiast `innerHTML` — nie interpretuje HTML/JS
- Sanityzuj HTML: **DOMPurify** — jedyna zaufana biblioteka client-side
- CSP: `script-src 'self'` — blokuje inline JS i eval
- Użyj frameworków (React, Vue, Angular) — domyślnie enkodują output

### JSONP — ryzyko

- Callback parameter: `?callback=alert(1)` — wykonanie dowolnego JS
- JSONP jest **przestarzałe** — używaj CORS + JSON zamiast JSONP
- Jeśli musisz używać: waliduj callback — allowlist dozwolonych nazw funkcji

## Pentesterskie deep dive

### Mniej znane techniki

- **JSONP via legacy endpoints**: nawet aplikacje SPA z REST mogą mieć legacy `?callback=` endpointy które ujawniają sensitive data via `<script src="">`.
- **CSP bypass via `eval` w whitelisted JS**: AngularJS sandbox escape, znane biblioteki w `script-src` ze znanymi gadgets (zbiór JSONBee).
- **Trusted Types bypass via legacy code**: aplikacja z modern Trusted Types CSP może wciąż mieć stare biblioteki które wymagają eval i są whitelisted.
- **Service Worker XSS**: zarejestrowany SW ma persistent JS execution na origin — atakujący XSS może dropować SW dla persistence.

### Common pitfalls

- **`eval` "tylko w dev"**: developers myślą że eval is safe in development build — buildy często leak do prod.
- **JSONP "for backwards compatibility"**: legacy endpoint left in for old client = open XSSI.

### Świeżynki z research

- **JSONBee** (CSP bypass JSONP): https://github.com/zigoo0/JSONBee
- **PortSwigger Web Security Academy XSS labs**: https://portswigger.net/web-security/cross-site-scripting

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| DOM Invader | Aktywna analiza DOM | Built-in |
| JS Link Finder | Endpointy z JS | [GitHub](https://github.com/InitRoot/BurpJSLinkFinder) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/02-Testing_for_JavaScript_Execution
- HackTricks XSS: https://book.hacktricks.xyz/pentesting-web/xss-cross-site-scripting

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.3 | Output Encoding (L1) | Context-aware encoding. |
| V14.4.3 | Configuration (L1) | CSP deny by default + nonce/hash. |
