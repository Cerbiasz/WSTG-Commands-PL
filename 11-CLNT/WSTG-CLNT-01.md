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

- Unikaj innerHTML, document.write, outerHTML — uzywaj textContent lub setAttribute
- Sanityzuj HTML za pomoca DOMPurify przed wstawieniem do DOM
- Waliduj wszystkie DOM sources: location.hash, location.search, document.referrer, window.name
- Wdroz CSP z nonces jako dodatkowa warstwe obrony
- Uwazaj na DOM Clobbering — atakujacy moze nadpisac globalne obiekty przez HTML id/name
- Zamroz Object.prototype aby zapobiec prototype pollution w DOM

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp DOM Scanner | Rekursywne skanowanie DOM w Single Page Applications | [GitHub](https://github.com/fcavallarin/burp-dom-scanner) |
| JavaScript Security | Sprawdzanie bezpieczenstwa DOM i walidacja SRI | [GitHub](https://github.com/phefley/burp-javascript-security-extension) |
