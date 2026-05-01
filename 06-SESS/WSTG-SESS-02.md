# WSTG-SESS-02 — Testing for Cookies Attributes

## Cel

Audyt cookies attributes: Secure (HTTPS only), HttpOnly (no JS), SameSite (CSRF), Domain/Path scope, `__Host-`/`__Secure-` prefixes, Max-Age/Expires.

## Automatyzacja Nuclei

```bash
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-02-cookie-attributes.yaml
```

Wykrywa session/auth cookies bez Secure/HttpOnly/SameSite, SameSite=None bez Secure, broad Domain wildcard, brak __Secure-/__Host- prefixu.

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| Secure flag | ✓ |
| HttpOnly flag | ✓ |
| SameSite attribute | ✓ |
| SameSite=None bez Secure | ✓ |
| Domain wildcard | ✓ |
| __Secure-/__Host- prefix | ✓ |
| Max-Age/Expires audit | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Cookie inventory**: per page, list wszystkich Set-Cookie headers.
2. **Per cookie audit**: każda flaga obecna i poprawnie ustawiona?
3. **Per cookie type**: session/auth/csrf - różne wymagania (np. CSRF token cookie czasem bez HttpOnly dla JS read).
4. **Cross-domain test**: czy cookie wysyłane z innego origin (CORS+credentials)?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Session cookie: Secure + HttpOnly + SameSite=Strict/Lax
- [ ] Auth cookie: same as session
- [ ] CSRF token cookie: Secure + SameSite (HttpOnly opcjonalne jeśli JS reads)
- [ ] SameSite=None ZAWSZE z Secure
- [ ] `__Host-` prefix dla session cookies (bezpieczne wymuszanie Path=/)
- [ ] Domain nie wildcard (.com, .net) - too broad
- [ ] Max-Age rozsądne (session: brak/krótki, persistent: 7-30 dni)
- [ ] Cookie nie zawiera sensitive data plaintext
- [ ] Session cookie regenerated po login
- [ ] Cookie cleared po logout

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Secure flag

- Cookie wysyłane TYLKO przez HTTPS — przeglądarka nigdy nie wyśle go przez HTTP
- **KRYTYCZNE** nawet jeśli serwer nie słucha na porcie 80 — atakujący MitM może sproofować HTTP serwer
- Cookie bez Secure flag może być przechwycone w otwartej sieci Wi-Fi

### HttpOnly flag

- Cookie niedostępne dla JavaScript (`document.cookie` nie zwróci go)
- **Ochrona przed XSS** — nawet jeśli atakujący wstrzyknie JS, nie może wykraść session cookie
- UWAGA: NIE chroni przed CSRF, session fixation ani innymi atakami

### SameSite attribute

- `SameSite=Strict` — cookie NIE wysyłane w cross-site requests (najsilniejsza ochrona CSRF)
  - Może powodować problemy UX (np. link z emaila nie zaloguje użytkownika)
- `SameSite=Lax` — cookie wysyłane w top-level navigations (GET) ale nie w cross-site POST/iframe (rekomendowany default)
- `SameSite=None` — cookie wysyłane zawsze, WYMAGA Secure flag (Chrome blokuje bez Secure)

### Cookie Prefixes

- **`__Secure-`**: wymusza Secure + ustawione tylko z HTTPS
- **`__Host-`**: wymusza Secure + brak Domain attr + Path=/ — najsilniejsza izolacja
- Przykład: `Set-Cookie: __Host-Session=abc; Secure; HttpOnly; SameSite=Strict; Path=/`

### Domain i Path scope

- **Domain** zbyt szeroki = cookie wysyłane na subdomeny: `.target.com` → wszystkie subdomeny dostają cookie
- Brak Domain = host-only cookie (bezpieczne)
- **Path** ogranicza scope cookie do określonych ścieżek

## Pentesterskie deep dive

### Mniej znane techniki

- **Cookie injection via subdomain takeover**: atakujący na `staging.target.com` ustawia cookie z `Domain=.target.com` → leak do main app.
- **CRLF injection w Set-Cookie**: jeśli aplikacja reflectuje user input do Set-Cookie header → atakujący ustawia własne cookies (cross WSTG-INPV-15).
- **Cookie tossing**: w shared subdomain context, atakujący sets cookie that overrides legitimate session.

### Common pitfalls

- **`SameSite=Lax` default w Chrome ale nie w Safari/Firefox**: cross-browser inconsistency.
- **HttpOnly cookie ale token w localStorage**: aplikacja używa zarówno cookie (HttpOnly) jak localStorage (no protection) - mixed approach.

### Świeżynki z research

- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- **MDN Cookies**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Cookie Editor | Per-cookie audit |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/02-Testing_for_Cookies_Attributes
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.4.1 | Cookie attributes: Secure, HttpOnly, SameSite. |
| V3.4.2 | Session cookies use __Host- prefix. |
