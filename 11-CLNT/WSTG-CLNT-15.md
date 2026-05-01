# WSTG-CLNT-15 — Testing for Client-side Template Injection (CSTI)

## Cel

Wykrycie reflectowania user input w syntax `{{...}}` (Angular/Vue/Handlebars/Mustache) bez sanityzacji — pivot do JavaScript execution w sandbox lub bypass do XSS. AngularJS 1.6+ usunął sandbox = direct RCE-equivalent w aplikacji.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-15-csti.yaml
```

Fuzzuje typowe CSTI payloads (`{{7*7}}`, `{{ '7'*7 }}`, constructor escape) - detekcja: `49` (= 7*7) lub `7777777` (Vue '7'*7) reflectowane w body z client-side content-type.

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Math evaluation (7*7=49) | ✓ | — |
| Vue '7'*7 → "7777777" | ✓ | — |
| AngularJS sandbox escape patterns | ✓ payloady | actual sandbox bypass per version → manual |
| Constructor.constructor RCE pattern | ✓ payload | — |
| Vue 3 sandbox (harder to escape) | częściowe | manual research per version |
| Handlebars / Mustache | częściowe | wymaga specific syntax tests |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Framework identification**: cross WSTG-INFO-08 — które framework ({{}}-syntax) jest używany.
2. **Probe: simple math**: `{{7*7}}` → 49 reflectowane = CSTI exists.
3. **Per-framework payload**: AngularJS 1.x ma znane sandbox escape gadgets per version.
4. **Sandbox bypass research**: PortSwigger XSS cheatsheet, JSFuck.com, AngularJS bypasses repository.
5. **Pivot to XSS**: jeśli sandbox bypass succeeds → arbitrary JS execution.

### Co MUSI być sprawdzone (8 punktów)

- [ ] Framework identification (Angular vs Vue vs Handlebars)
- [ ] `{{7*7}}` simple test
- [ ] `{{constructor.constructor('alert(1)')()}}` AngularJS classic
- [ ] `{{$on.constructor('alert(1)')()}}` AngularJS 1.6+
- [ ] `{{_c.constructor('alert(1)')()}}` Vue 2.x
- [ ] Per-framework version specific bypass
- [ ] CSP audit (czy chroni przed CSTI?)
- [ ] Production framework version (newer = harder to bypass)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Third_Party_Javascript_Management_Cheat_Sheet.md, DOM_based_XSS_Prevention_Cheat_Sheet.md

### CSTI — Client-Side Template Injection

- Dane użytkownika są **wstawiane do szablonu client-side** (Angular, Vue, Handlebars)
- Skutek: wykonanie **JavaScript** w kontekście strony — XSS
- Różnica vs SSTI: kod wykonywany w **przeglądarce**, nie na serwerze

### Payloady per framework

| Framework | Payload | Wersja |
|-----------|---------|--------|
| AngularJS 1.x | `{{constructor.constructor('alert(1)')()}}` | < 1.6 |
| AngularJS 1.6+ | `{{$on.constructor('alert(1)')()}}` | >= 1.6 (sandbox removed) |
| Vue.js 2.x | `{{_c.constructor('alert(1)')()}}` | 2.x |
| Vue.js 3.x | Sandbox — trudniejsze do eksploitacji | 3.x |
| Handlebars | `{{#with "s" as \|string\|}}...{{/with}}` | Różne |

### AngularJS sandbox escape — historia

- AngularJS 1.0-1.5: sandbox — próbował ograniczyć wykonanie kodu
- Sandbox był **wielokrotnie obchodzony** — nowe bypass w każdej wersji
- AngularJS 1.6+: **sandbox usunięty** — `{{constructor.constructor('alert(1)')()}}` działa bezpośrednio
- Angular (2+): nie interpretuje `{{}}` z danych użytkownika — bezpieczne domyślnie

### Obrona

- **Nie wstawiaj danych użytkownika** do szablonów client-side bez enkodowania
- Użyj **CSP** z `script-src 'self'` — blokuje eval(), Function() (wymagane przez wiele exploitów CSTI)
- Aktualizuj frameworki — nowsze wersje mają lepsze zabezpieczenia
- Angular (2+) i React: domyślnie bezpieczne — enkodują output
- Vue 3: bardziej restrykcyjny sandbox — trudniejsze do exploitacji

### Subresource Integrity (SRI) — third-party JS

- `<script src="cdn.com/lib.js" integrity="sha384-..." crossorigin="anonymous">`
- Przeglądarka weryfikuje hash pliku — jeśli CDN skompromitowany, plik nie zostanie załadowany
- Pinuj wersje: `lib@1.2.3` zamiast `lib@latest`
- CSP: `require-sri-for script style` — wymuszaj SRI
- Monitoruj zmiany w third-party zasobach — supply chain attacks

## Pentesterskie deep dive

### Mniej znane techniki

- **AngularJS sandbox escapes per version**: każda wersja AngularJS przed 1.6 miała różne sandbox escape. https://portswigger.net/research/dom-based-angular-sandbox-escapes
- **Vue 3 hidden gadgets**: Vue 3 ma stricter sandbox ale gadgets w polyfills/internal APIs mogą być wykorzystywane.
- **Handlebars custom helpers RCE**: jeśli aplikacja akceptuje user-defined helpers w Handlebars - direct RCE.
- **Server-Side rendering w Next.js + CSTI**: SSR Next.js może render SSTI z client-controlled string → XSS via SSR.

### Common pitfalls

- **AngularJS 1.x w produkcji**: AngularJS jest EOL od stycznia 2022 — wszystkie aplikacje powinny migrować do Angular 2+.
- **CSP nie blokuje CSTI**: jeśli `script-src 'self'`, CSTI nadal może wykonać `eval()` w niektórych frameworks (zależy od bypass).

### Świeżynki z research

- **PortSwigger AngularJS sandbox**: https://portswigger.net/research/dom-based-angular-sandbox-escapes
- **HackTricks CSTI**: https://book.hacktricks.xyz/pentesting-web/client-side-template-injection-csti
- **PayloadsAllTheThings CSTI**: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/CSTI

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| DOM Invader | CSTI auto-detection | Built-in |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/15-Testing_for_Client-side_Template_Injection
- PortSwigger AngularJS: https://portswigger.net/research/dom-based-angular-sandbox-escapes
- HackTricks CSTI: https://book.hacktricks.xyz/pentesting-web/client-side-template-injection-csti
- PayloadsAllTheThings CSTI: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/CSTI

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.3 | Output Encoding (L1) | Context-aware output encoding. |
| V14.2.1 | Dependency (L1) | Components up to date. |
| V14.4.3 | Configuration (L1) | CSP set deny by default. |
