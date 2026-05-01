# WSTG-CLNT-01 — Testing for DOM-Based Cross Site Scripting

## Cel

Wykrycie DOM XSS — XSS gdzie payload nigdy nie trafia na serwer, tylko jest interpretowany client-side przez JS sinks (innerHTML, document.write, eval) z source typu `location.hash`/`document.URL`/`postMessage`. WAF nie chroni — wykrywanie wymaga DOM Invader/headless.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-01-dom-xss.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-clnt-01.jsonl
```

Szablon pasywnie wykrywa MARKERY DOM XSS w body: `innerHTML/outerHTML` z source, `document.write` z source, `eval/Function` z source, `setTimeout(string)` z source, jQuery `$.html`/`$.parseHTML`, postMessage handler bez origin check, source maps. Pełna weryfikacja DOM XSS wymaga Burp DOM Invader.

### Suplementarne narzędzia

```bash
# Burp DOM Invader (ekstensja PortSwigger) - aktywna analiza DOM
# Aktywuj w Burp > Extensions > DOM Invader

# Headless browser: Puppeteer + DOMPurify research
# https://github.com/PortSwigger/dom-invader

# Static analysis (Semgrep)
semgrep --config "p/javascript" --include "*.js" .
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| innerHTML/outerHTML z source | ✓ markery | actual XSS verification → DOM Invader |
| document.write z source | ✓ | — |
| eval/Function/setTimeout(string) | ✓ | — |
| jQuery sinks (.html, .parseHTML) | ✓ | — |
| postMessage handler bez origin check | ✓ | — |
| Reflected XSS (server-side) | — | osobno → WSTG-INPV-01 |
| Stored XSS | — | osobno → WSTG-INPV-02 |
| DOM Clobbering | — | manual + DOMPurify research |
| mXSS (mutation XSS) | — | wymaga browser-specific testing |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Pasywny scan**: nasz Nuclei + grep w JS bundle: `grep -E "innerHTML|document\.write|eval\(" *.js`.
2. **Burp DOM Invader**: aktywuj, navigate przez aplikację, automatycznie identyfikuje sinks/sources.
3. **Source enumeration per sink**: dla każdego znalezionego sink, prześledź source — od user input do sink.
4. **PoC payload**: dla każdej potencjalnej luki, stwórz payload (`#<script>alert(1)</script>` w hash, `?q=<img onerror=alert(1)>` w search).
5. **Sandbox bypass**: gdy CSP aktywny, sprawdzić bypass via `eval`, `Function`, JSONP, AngularJS gadgets.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Wszystkie `innerHTML/outerHTML` per JS file
- [ ] Wszystkie `document.write/writeln`
- [ ] Wszystkie `eval/Function` calls
- [ ] `setTimeout/setInterval` z string parameter
- [ ] `setAttribute("on*", ...)` event handlers
- [ ] `location.href = ...` z user input
- [ ] postMessage handlers — czy waliduje origin
- [ ] jQuery sinks (.html, .append, .parseHTML)
- [ ] Hash router (`#/path/<payload>`) handling
- [ ] Source maps available — pull i analyze original code

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — DOM_based_XSS_Prevention_Cheat_Sheet.md, DOM_Clobbering_Prevention_Cheat_Sheet.md

### Kluczowa różnica: DOM XSS vs Reflected/Stored XSS

- Reflected/Stored XSS: injection po stronie SERWERA
- DOM XSS: injection po stronie KLIENTA (przeglądarki) — payload nigdy nie trafia na serwer
- WAF i server-side filtry NIE chronią przed DOM XSS

### Niebezpieczne sinki (NIGDY nie używaj z niezaufanymi danymi)

- `element.innerHTML`, `element.outerHTML` — renderują HTML
- `document.write()`, `document.writeln()` — piszą bezpośrednio do dokumentu
- `eval()`, `setTimeout(string)`, `setInterval(string)`, `new Function(string)` — wykonują kod
- `element.setAttribute("onclick", ...)` — setAttribute z event handler implicitly konwertuje string na kod JS

### Bezpieczne sinki (UŻYWAJ tych zamiast powyższych)

- `element.textContent = var` — PRIMARY safe method, automatycznie enkoduje
- `element.insertAdjacentText(position, var)` — bezpieczne
- `document.createTextNode(var)` — zawsze bezpieczne
- `element.setAttribute(safeName, var)` — bezpieczne TYLKO dla niewykonujących atrybutów (class, id, title, value, align itd.)
- `element.className = var` — bezpieczne
- `DOMPurify.sanitize(var)` + innerHTML — jeśli MUSISZ wstawić HTML

### 7 reguł DOM XSS Prevention

1. **HTML escape, potem JS escape** przed wstawieniem do HTML subcontext w execution context
2. **JS escape** przed wstawieniem do HTML attribute subcontext (ale NIE double-encode — setAttribute jest safe sink)
3. **Uważaj na event handlers i JS code subcontext** — JS encoding NIE zapobiega XSS w setAttribute("onclick", ...)
4. **JS escape + URL encode** przed wstawieniem do CSS attribute subcontext (`style.property = x` jest safe sink)
5. **URL escape, potem JS escape** przed wstawieniem do URL attribute subcontext
6. **Używaj bezpiecznych metod DOM**: textContent, createElement, setAttribute (safe attrs)
7. **Naprawianie DOM XSS**: zamień innerHTML/document.write na textContent/innerText

### Wytyczne dla JavaScript

- Niezaufane dane traktuj TYLKO jako tekst do wyświetlenia — nigdy jako kod
- Zawsze JS encode i delimituj niezaufane dane w quoted strings
- Używaj `document.createElement()` + `setAttribute()` + `appendChild()` do budowania dynamicznego UI
- NIE używaj `eval()` do parsowania JSON — używaj `JSON.parse()`
- Ogranicz dostęp do właściwości obiektu przy `object[x]` accessors — dodaj warstwę pośrednią
- Uruchamiaj JavaScript w sandboxie (ECMAScript 5 canopy)

### Wykrywanie DOM XSS

- Szukaj wzorców: `document.write(location.hash)`, `innerHTML = location.search`, `eval(document.URL)`
- Użyj Semgrep rules do statycznej analizy DOM XSS
- DOM sources do sprawdzenia: `location.hash`, `location.search`, `location.href`, `document.referrer`, `window.name`, `document.URL`

## Pentesterskie deep dive

### Mniej znane techniki

- **DOM Clobbering**: `<form id="config"><input name="redirectUrl" value="https://evil.com"></form>` — niektóre frameworki czytają `config.redirectUrl` z global scope; clobber via injected HTML.
- **postMessage XSS chain**: `addEventListener('message', e => element.innerHTML = e.data)` bez origin check + atakujący embedded iframe z evil page → cross-domain XSS pivot.
- **mXSS (mutation XSS)**: HTML parsowany przez `innerHTML` może mutować w sposób nieoczekiwany — `<img src=" "><img src=onerror=alert(1)>` mutacja w niektórych browserach.
- **Document fragment manipulation**: `DocumentFragment` operations często nie są sanityzowane przez DOMPurify default config.
- **Web Components Shadow DOM**: shadow root z user content nie jest ujęty w document-level CSP — bypass.
- **Trusted Types bypass**: nawet z `Content-Security-Policy: require-trusted-types-for 'script'`, niektóre legacy library wrappers (np. older AngularJS) nie respektują.

### Common pitfalls

- **DOMPurify version old**: starsze wersje DOMPurify (przed 2.4.x) miały bypassy — verify via `DOMPurify.version`.
- **Custom sanitizer "rolling our own"**: regex-based HTML sanitizer = guaranteed bypass.
- **Framework auto-escape ignored**: `dangerouslySetInnerHTML` w React, `v-html` w Vue — explicit opt-out z safety.

### Świeżynki z research

- **PortSwigger DOM Invader**: https://portswigger.net/burp/documentation/desktop/tools/dom-invader
- **PortSwigger DOM XSS Lab**: https://portswigger.net/web-security/dom-based
- **HackTricks DOM XSS**: https://book.hacktricks.xyz/pentesting-web/xss-cross-site-scripting/dom-xss
- **DOMPurify (najlepszy sanitizer)**: https://github.com/cure53/DOMPurify

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| DOM Invader | Aktywna analiza DOM XSS | Built-in PortSwigger |
| Reflector | Reflected user input detection | [GitHub](https://github.com/elkokc/reflector) |
| JS Link Finder | Pasywne wyciąganie endpointów z JS | [GitHub](https://github.com/InitRoot/BurpJSLinkFinder) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/01-Testing_for_DOM-based_Cross_Site_Scripting
- OWASP DOM XSS Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html
- PortSwigger DOM-based XSS: https://portswigger.net/web-security/dom-based
- HackTricks DOM XSS: https://book.hacktricks.xyz/pentesting-web/xss-cross-site-scripting/dom-xss

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.3 | Output Encoding (L1) | Context-aware output encoding. |
| V5.3.6 | Output Encoding (L1) | Sanitize untrusted HTML inputs. |
