# WSTG-CLNT-01 — Testing for DOM-Based Cross Site Scripting

## Cele

- Identify DOM sinks
- Build payloads that pertain to every sink type

## KOMENDY

### Identyfikacja sinkow DOM

```bash
# Pobierz JS i szukaj niebezpiecznych sinkow
curl -s "https://TARGET/" | grep -oP 'src="[^"]*\.js"' | sed 's/src="//;s/"//'
# Pobierz kazdy JS file i szukaj:
# document.write, innerHTML, outerHTML, eval, setTimeout, setInterval
# location.href, location.assign, location.replace, window.open
# jQuery: .html(), .append(), .prepend(), .after(), .before()

```

### dalfox DOM XSS

```bash
dalfox url "https://TARGET/page#payload" -o output_dalfox_dom.txt

```

### Testowanie zrodel DOM

```bash
curl -s "https://TARGET/page?input=<img src=x onerror=alert(1)>#<img src=x onerror=alert(1)>"

```

### Retire.js - wyszukiwanie podatnych bibliotek JS

```bash
retire --js --jspath /sciezka/do/pobranych/js/

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings XSS DOM payloads

```bash
# Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt
# Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/JHADDIX_XSS.txt

```

### SecLists XSS

```bash
# Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-BruteLogic.txt
# Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-Cheat-Sheet-PortSwigger.txt

```

### fuzzdb XSS event handlers

```bash
# Desktop/WSTG/fuzzdb-master/attack/xss/html-event-attributes.txt
# Desktop/WSTG/fuzzdb-master/attack/xss/default-javascript-event-attributes.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz DevTools > Sources i szukaj sinkow DOM w kodzie JS
2. Uzyj DOM Invader w Burp embedded browser
3. Testuj payloady w URL hash (#), query params, postMessage
4. Monitoruj console.log na bledy i wykonanie kodu
5. Uzyj Sources tab do breakpointow na sinkach DOM


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — DOM_based_XSS_Prevention_Cheat_Sheet.md, DOM_Clobbering_Prevention_Cheat_Sheet.md

### Kluczowa roznica: DOM XSS vs Reflected/Stored XSS

- Reflected/Stored XSS: injection po stronie SERWERA
- DOM XSS: injection po stronie KLIENTA (przegladarki) — payload nigdy nie trafia na serwer
- WAF i server-side filtry NIE chronia przed DOM XSS

### Niebezpieczne sinki (NIGDY nie uzywaj z niezaufanymi danymi)

- `element.innerHTML`, `element.outerHTML` — renderuja HTML
- `document.write()`, `document.writeln()` — pisza bezposrednio do dokumentu
- `eval()`, `setTimeout(string)`, `setInterval(string)`, `new Function(string)` — wykonuja kod
- `element.setAttribute("onclick", ...)` — setAttribute z event handler implicitly konwertuje string na kod JS

### Bezpieczne sinki (UZYWAJ tych zamiast powyzszych)

- `element.textContent = var` — PRIMARY safe method, automatycznie enkoduje
- `element.insertAdjacentText(position, var)` — bezpieczne
- `document.createTextNode(var)` — zawsze bezpieczne
- `element.setAttribute(safeName, var)` — bezpieczne TYLKO dla niewykonujacych atrybutow (class, id, title, value, align itd.)
- `element.className = var` — bezpieczne
- `DOMPurify.sanitize(var)` + innerHTML — jesli MUSISZ wstawic HTML

### 7 regul DOM XSS Prevention

1. **HTML escape, potem JS escape** przed wstawieniem do HTML subcontext w execution context
2. **JS escape** przed wstawieniem do HTML attribute subcontext (ale NIE double-encode — setAttribute jest safe sink)
3. **Uwazaj na event handlers i JS code subcontext** — JS encoding NIE zapobiega XSS w setAttribute("onclick", ...)
4. **JS escape + URL encode** przed wstawieniem do CSS attribute subcontext (`style.property = x` jest safe sink)
5. **URL escape, potem JS escape** przed wstawieniem do URL attribute subcontext
6. **Uzywaj bezpiecznych metod DOM**: textContent, createElement, setAttribute (safe attrs)
7. **Naprawianie DOM XSS**: zamien innerHTML/document.write na textContent/innerText

### Wytyczne dla JavaScript

- Niezaufane dane traktuj TYLKO jako tekst do wyswietlenia — nigdy jako kod
- Zawsze JS encode i delimituj niezaufane dane w quoted strings
- Uzywaj `document.createElement()` + `setAttribute()` + `appendChild()` do budowania dynamicznego UI
- NIE uzywaj `eval()` do parsowania JSON — uzywaj `JSON.parse()`
- Ogranicz dostep do wlasciwosci obiektu przy `object[x]` accessors — dodaj warstwe posrednia
- Uruchamiaj JavaScript w sandboxie (ECMAScript 5 canopy)

### Wykrywanie DOM XSS

- Szukaj wzorcow: `document.write(location.hash)`, `innerHTML = location.search`, `eval(document.URL)`
- Uzyj Semgrep rules do statycznej analizy DOM XSS
- DOM sources do sprawdzenia: `location.hash`, `location.search`, `location.href`, `document.referrer`, `window.name`, `document.URL`

### DOM Clobbering

- Atakujacy moze nadpisac globalne obiekty JavaScript przez HTML `id` i `name` atrybuty
- Obrona: zamroz `Object.prototype`, uzywaj `const` zamiast `var`, waliduj istnienie obiektow przed uzyciem

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp DOM Scanner | Rekursywne skanowanie DOM w Single Page Applications | [GitHub](https://github.com/fcavallarin/burp-dom-scanner) |
| JavaScript Security | Sprawdzanie bezpieczenstwa DOM i walidacja SRI | [GitHub](https://github.com/phefley/burp-javascript-security-extension) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.1 | Injection Prevention | Verify that output encoding for an HTTP response, HTML document, or XML document is relevant for the context required, such as encoding the relevant characters for HTML elements, HTML attributes, HTML comments, CSS, or HTTP header fields, to avoid changing the message or document structure. |
| V1.2.3 | Injection Prevention | Verify that output encoding or escaping is used when dynamically building JavaScript content (including JSON), to avoid changing the message or document structure (to avoid JavaScript and JSON injection). |
| V3.2.2 | Unintended Content Interpretation | Verify that content intended to be displayed as text, rather than rendered as HTML, is handled using safe rendering functions (such as createTextNode or textContent) to prevent unintended execution of content such as HTML or JavaScript. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.2.3 | Unintended Content Interpretation | Verify that the application avoids DOM clobbering when using client-side JavaScript by employing explicit variable declarations, performing strict type checking, avoiding storing global variables on the document object, and implementing namespace isolation. |
