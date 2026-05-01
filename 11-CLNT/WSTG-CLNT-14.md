# WSTG-CLNT-14 — Testing for Reverse Tabnabbing

## Cel

Wykrycie linków `target="_blank"` bez `rel="noopener"` (lub `rel="noreferrer"`). Atakujący kontrolujący link target może użyć `window.opener.location` do redirect original page → phishing. Modern browsers (Chrome 88+, Firefox 79+) auto-set noopener, ale defense-in-depth wymaga explicit attribute.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-14-reverse-tabnabbing.yaml
```

Wykrywa `<a target="_blank">` bez `rel="noopener"`. Limited regex - może wymagać manual review.

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| `<a target="_blank">` bez noopener | ✓ | — |
| User-generated content (komentarze) | częściowe | requires authenticated browse |
| `window.open()` w JS bez noopener | — | manual JS review |
| Markdown rendered links | częściowe | depends on renderer |
| Email rendering tabnabbing | — | osobne medium |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **HTML scan**: nasz Nuclei + `grep -E 'target="_blank"' source.html`.
2. **JS scan**: `grep -E 'window\\.open\\(' *.js` — każde wywołanie powinno być z 'noopener,noreferrer' w features.
3. **User-generated content**: jeśli aplikacja pozwala na URL w komentarzach/profilu, sprawdzić czy markdown renderer dodaje noopener.
4. **PoC**: stwórz attacker page → user kliknie link → atakujący zmienia `window.opener.location`.

### Co MUSI być sprawdzone (6 punktów)

- [ ] Wszystkie `<a target="_blank">` w aplikacji
- [ ] User-generated content z linkami (komentarze, profile, posts)
- [ ] Markdown renderer dodaje noopener?
- [ ] `window.open()` w JS z noopener feature
- [ ] React/Vue/Angular components - czy framework auto-add noopener
- [ ] Email rendering (HTML email z linkami)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md

### Reverse Tabnabbing — mechanizm ataku

1. Strona A zawiera link `<a href="https://evil.com" target="_blank">` bez `rel="noopener"`
2. Użytkownik klika link → otwiera się nowa karta z evil.com
3. Evil.com używa `window.opener.location = "https://phishing.com"` → strona A zmienia się na phishing
4. Użytkownik wraca do "karty A" → widzi stronę phishingową (np. fake login)

### Podatny kod

```html
<!-- PODATNE -->
<a href="https://external.com" target="_blank">Link</a>

<!-- BEZPIECZNE -->
<a href="https://external.com" target="_blank" rel="noopener noreferrer">Link</a>
```

### Obrona

- **Zawsze** dodawaj `rel="noopener noreferrer"` do linków z `target="_blank"`
- `noopener`: blokuje dostęp do `window.opener` — zapobiega tabnabbingowi
- `noreferrer`: nie wysyła Referer header — dodatkowa prywatność
- Nowoczesne przeglądarki (Chrome 88+, Firefox 79+) automatycznie dodają `noopener` — ale nie polegaj na tym
- **CSP**: rozważ `sandbox` na iframe aby ograniczyć możliwości zagnieżdżonych stron

### User-generated content — ryzyko

- Jeśli użytkownicy mogą wstawiać linki (komentarze, profil, wiadomości) — **automatycznie** dodawaj `rel="noopener noreferrer"`
- W Markdown rendererach: sprawdź czy linki z `target="_blank"` mają prawidłowe atrybuty rel
- Frameworki: React automatycznie dodaje `noopener` od v16.x; sprawdź konfigurację innych

### Testowanie

- Przeszukaj kod źródłowy: `grep -i 'target="_blank"' | grep -iv 'noopener'`
- Sprawdź user-generated content pod kątem linków bez noopener
- Stwórz PoC: strona która zmienia `window.opener.location` po otwarciu

## Pentesterskie deep dive

### Mniej znane techniki

- **window.open without features = vulnerable**: `window.open('https://evil.com')` w JS bez 'noopener,noreferrer' = same attack vector.
- **target="_top" + framing**: `<a target="_top">` w iframed content - może mutate parent location.
- **HTML email tabnabbing**: HTML email links mogą tabnabbować email client (rare but exists).
- **React JSX `target="_blank"` rules**: React 16+ auto-warning ale nie auto-fix - dev musi explicit dodać.

### Common pitfalls

- **Markdown renderer adds target="_blank" but not noopener**: many older markdown libraries.
- **CSP rel-validation**: CSP nie chroni przed tabnabbing - to HTML attribute level.

### Świeżynki z research

- **OWASP Tabnabbing**: https://owasp.org/www-community/attacks/Reverse_Tabnabbing
- **Mozilla rel=noopener**: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel/noopener

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Reflector | User-input in href detection | [GitHub](https://github.com/elkokc/reflector) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/13.1-Testing_for_Reverse_Tabnabbing
- OWASP Tabnabbing: https://owasp.org/www-community/attacks/Reverse_Tabnabbing
- OWASP HTML5 Security CS: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html
- Mozilla rel=noopener: https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/rel/noopener

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.1 | Configuration (L1) | All hyperlinks with target="_blank" use rel="noopener". |
