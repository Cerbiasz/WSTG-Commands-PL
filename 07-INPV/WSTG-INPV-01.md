# WSTG-INPV-01 — Testing for Reflected Cross Site Scripting

## Cele

- Identify variables that are reflected in responses
- Assess the input they accept and the encoding that gets applied on return

## KOMENDY

### dalfox - automatyczny skaner XSS

```bash
dalfox url "https://TARGET/search?q=FUZZ" -o output_dalfox.txt
dalfox url "https://TARGET" --crawl -o output_dalfox_crawl.txt

```

### XSStrike

```bash
python3 xsstrike.py -u "https://TARGET/search?q=test" --crawl
python3 xsstrike.py -u "https://TARGET/search?q=test" --fuzzer

```

### kxss - szybki skaner reflected params

```bash
echo "https://TARGET" | gau | kxss

```

### Reczne testowanie podstawowe

```bash
curl -s "https://TARGET/search?q=<script>alert(1)</script>" | grep -i "<script>alert"
curl -s "https://TARGET/search?q=\"onmouseover=alert(1)" | grep -i "onmouseover"
curl -s "https://TARGET/search?q=<img src=x onerror=alert(1)>" | grep -i "onerror"

```

### Sprawdzenie kontekstu odbicia

```bash
curl -s "https://TARGET/search?q=UNIQUE_CANARY_STRING" | grep -c "UNIQUE_CANARY_STRING"

```

## KOMENDY Z WORDLISTAMI

### ffuf z XSS payloads (PayloadsAllTheThings)

```bash
ffuf -u "https://TARGET/search?q=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt" -fr "not found" -o output_ffuf_xss.json

```

### ffuf z JHADDIX XSS

```bash
ffuf -u "https://TARGET/search?q=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/JHADDIX_XSS.txt" -fr "not found" -o output_ffuf_jhaddix.json

```

### ffuf z XSS Polyglots

```bash
ffuf -u "https://TARGET/search?q=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/XSS_Polyglots.txt" -fr "not found" -o output_ffuf_polyglots.json

```

### wfuzz z SecLists XSS

```bash
wfuzz -c -z file,"Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-BruteLogic.txt" --hl 0 "https://TARGET/search?q=FUZZ"

```

### wfuzz z PortSwigger cheatsheet

```bash
wfuzz -c -z file,"Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-Cheat-Sheet-PortSwigger.txt" --hl 0 "https://TARGET/search?q=FUZZ"

```

### ffuf z fuzzdb XSS

```bash
ffuf -u "https://TARGET/search?q=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/xss/xss-rsnake.txt -fr "not found" -o output_ffuf_fuzzdb_xss.json

```

### ffuf z BruteLogic XSS

```bash
ffuf -u "https://TARGET/search?q=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/BRUTELOGIC-XSS-STRINGS.txt" -fr "not found" -o output_ffuf_brutelogic.json

```

### Burp Intruder z event handlers

```bash
ffuf -u "https://TARGET/search?q=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/0xcela_event_handlers.txt" -o output_ffuf_events.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj wszystkie parametry odbijane w odpowiedzi (wstaw unikalne canary)
2. Sprawdz kontekst odbicia: HTML body, atrybut, JavaScript, URL
3. Testuj rozne kodowania: URL encode, double encode, HTML entities
4. Sprawdz Content-Type odpowiedzi i CSP headery
5. Testuj z Burp Repeater modyfikujac payloady pod kontekst
6. Sprawdz czy WAF blokuje - testuj bypass techniki
7. Przetestuj w przegladarce czy payload sie wykonuje (alert/console.log)
8. Sprawdz X-XSS-Protection i inne headery ochronne


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross_Site_Scripting_Prevention_Cheat_Sheet.md, DOM_based_XSS_Prevention_Cheat_Sheet.md, XSS_Filter_Evasion_Cheat_Sheet.md

### Filozofia obrony przed XSS

- Kazda zmienna wyswietlana w aplikacji musi przejsc walidacje + encoding/sanityzacje — to tzw. **perfect injection resistance**
- Zadna pojedyncza technika nie rozwiaze XSS — konieczna kombinacja: framework security + output encoding + HTML sanitization + CSP
- Output encoding jest kluczowy — zamienia dane uzytkownika na bezpieczny tekst, nie pozwalajac na interpretacje jako kod

### Output Encoding wg kontekstu

- **HTML Body** (`<div>$var</div>`): HTML Entity Encoding — `& → &amp;`, `< → &lt;`, `> → &gt;`, `" → &quot;`, `' → &#x27;`
- **HTML Attribute** (`<div attr="$var">`): HTML Attribute Encoding — ZAWSZE otaczaj wartosci cudzylowami `"` lub `'`
- **JavaScript** (`<script>var x='$var'</script>`): JavaScript Encoding `\xHH` — zmienne TYLKO w quoted data values
- **URL** (`<a href="...?param=$var">`): URL Encoding `%HH` — koduj TYLKO wartosc parametru, nie caly URL
- **CSS** (`style="property: $var"`): CSS Hex Encoding `\XX` — zmienne TYLKO w wartosciach wlasciwosci CSS
- Podwojny kontekst (URL w href): najpierw URL encode, potem HTML attribute encode

### Niebezpieczne konteksty (Dangerous Contexts)

- NIGDY nie umieszczaj zmiennych bezposrednio w: `<script>...tutaj...</script>`, komentarzach HTML `<!-- -->`, blokach `<style>`, definicjach tagow/atrybutow
- Unikaj: `eval()`, `setTimeout()`, `setInterval()`, `new Function()`, `document.write()`, `innerHTML`
- Event handlery (`onclick`, `onerror`, `onmouseover`) — nawet z encoding, NIE sa bezpieczne dla niezaufanych danych

### Framework Security

- Uzywaj frameworkowego auto-escaping (React, Angular, Vue, Lit, Polymer) — ale uwazaj na escape hatches:
  - React: `dangerouslySetInnerHTML` — nie uzywaj bez sanityzacji; nie obsluguje `javascript:` i `data:` URLs
  - Angular: `bypassSecurityTrustAs*` — omija wbudowane zabezpieczenia
  - Lit: `unsafeHTML` — bezposrednie wstawienie HTML
  - Polymer: `inner-h-t-m-l` attribute i `htmlLiteral`
- Regularne aktualizacje frameworkow i pluginow — stare wersje moga miec znane bypassy

### HTML Sanitization

- Sanityzuj HTML uzytkownika biblioteka **DOMPurify**: `let clean = DOMPurify.sanitize(dirty);`
- NIGDY nie uzywaj regexa do sanityzacji HTML
- Po sanityzacji NIE modyfikuj stringa — mozesz uniewaznc zabezpieczenia
- Regularnie aktualizuj DOMPurify — przegladarki zmieniaja zachowanie, odkrywane sa nowe bypassy

### Safe Sinks (bezpieczne metody DOM)

- Uzywaj safe sinks zamiast niebezpiecznych metod:
  - `elem.textContent = var` zamiast `innerHTML`
  - `elem.setAttribute(safeName, var)` — bezpieczne TYLKO dla niewykonujacych atrybutow (align, class, id, title, value itd.)
  - `document.createTextNode(var)` — zawsze bezpieczne
  - `formfield.value = var` — bezpieczne
- Niebezpieczne: `innerHTML`, `outerHTML`, `document.write()`, `document.writeln()`

### DOM-based XSS — dodatkowe zasady

- HTML escape POTEM JavaScript escape przed wstawieniem do HTML subcontext w DOM
- W event handler subcontext — JavaScript encoding NIE zapobiega XSS (setAttribute z onclick nadal wykona kod)
- Uzyj `element.textContent` jako PRIMARY safe method do wstawiania tekstu w DOM
- Unikaj umieszczania danych uzytkownika w `window[var]` po lewej stronie wyrazenia
- Unikaj `eval()` JSON — uzywaj `JSON.parse()` zamiast tego
- Wykrywaj DOM XSS: szukaj wzorcow `document.write(location.hash)`, `innerHTML = location.search` itp.

### Dodatkowe warstwy obrony

- **Content-Security-Policy**: uzyj nonces zamiast `unsafe-inline`, traktuj jako defence-in-depth, NIE jako jedyna obrone
- **Cookie attributes**: `HttpOnly`, `Secure`, `SameSite` — ograniczaja impact, ale nie eliminuja przyczyny XSS
- **WAF**: nie polega na WAF jako obronie przed XSS — latwo omijany, nie chroni przed DOM XSS
- CSP musi byc dostosowany do konkretnej aplikacji — uniwersalna polityka enterprise jest nieskuteczna

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| XSS Validator | Automatyczna walidacja podatnosci XSS | [GitHub](https://github.com/nVisium/xssValidator) |
| Reflector | Wykrywanie reflected XSS w czasie rzeczywistym | [GitHub](https://github.com/elkokc/reflector) |
| BitBlinder | Wyszukiwanie blind XSS | [GitHub](https://github.com/BitTheByte/BitBlinder) |
| Reflected Parameters | Monitorowanie odbitych parametrow w odpowiedziach | [GitHub](https://github.com/portswigger/reflected-parameters) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.1 | Injection Prevention | Verify that output encoding for an HTTP response, HTML document, or XML document is relevant for the context required, such as encoding the relevant characters for HTML elements, HTML attributes, HTML comments, CSS, or HTTP header fields, to avoid changing the message or document structure. |
| V1.2.2 | Injection Prevention | Verify that when dynamically building URLs, untrusted data is encoded according to its context (e.g., URL encoding or base64url encoding for query or path parameters). Ensure that only safe URL protocols are permitted (e.g., disallow javascript: or data:). |
| V1.2.3 | Injection Prevention | Verify that output encoding or escaping is used when dynamically building JavaScript content (including JSON), to avoid changing the message or document structure (to avoid JavaScript and JSON injection). |
| V3.2.2 | Unintended Content Interpretation | Verify that content intended to be displayed as text, rather than rendered as HTML, is handled using safe rendering functions (such as createTextNode or textContent) to prevent unintended execution of content such as HTML or JavaScript. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.1.2 | Encoding and Sanitization Architecture | Verify that the application performs output encoding and escaping either as a final step before being used by the interpreter for which it is intended or by the interpreter itself. |
