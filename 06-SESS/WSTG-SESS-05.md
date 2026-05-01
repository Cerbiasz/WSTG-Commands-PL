# WSTG-SESS-05 — Testing for Cross Site Request Forgery (CSRF)

## Cel

Wykrycie state-changing endpoints bez anti-CSRF defense: brak CSRF token, brak SameSite cookies, akceptowanie GET dla state changes, brak Origin/Referer validation.

## Automatyzacja Nuclei

```bash
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-05-csrf.yaml
```

Wykrywa formularze POST/PUT/DELETE bez CSRF token, session cookies bez SameSite.

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| Form bez CSRF token | ✓ |
| Cookies bez SameSite | ✓ |
| Origin/Referer validation | manual |
| GET state changes | manual |
| Per-request token rotation | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **State-changing endpoint enumeration**: POST/PUT/DELETE/PATCH endpoints.
2. **CSRF token check**: czy każdy endpoint wymaga CSRF token? (input field lub header).
3. **Token validation**: usuń token → endpoint nadal działa? (broken validation).
4. **Token reuse**: token z user A → wykonaj action jako user B (per-session tokens powinny być unique).
5. **PoC creation**: stworzyć HTML auto-submit form na evil.com.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Każdy state-changing endpoint wymaga CSRF token
- [ ] Token validated server-side (nie tylko presence)
- [ ] Token unique per session/request
- [ ] SameSite=Lax/Strict na session cookies
- [ ] Origin/Referer header validation (defense-in-depth)
- [ ] Brak GET state changes
- [ ] Re-authentication for sensitive ops (zmiana hasła wymaga current password)
- [ ] CSRF token nie w URL (Referer leak)
- [ ] CORS Allow-Credentials z wildcard ACAO blocked
- [ ] PoC test - HTML auto-submit z evil.com

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md

### WAŻNE: XSS pokonuje WSZYSTKIE zabezpieczenia CSRF

- Jeśli aplikacja ma XSS — atakujący może odczytać CSRF tokeny i ominąć każdą ochronę
- Najpierw napraw XSS, potem wdrażaj CSRF protection

### Primary Defense — Token-Based Mitigation

- **Synchronizer Token Pattern** (stateful): serwer generuje unikalny token per sesja, wstawia w hidden field formularza
  - Token musi być: unikalny per sesja, tajny, nieprzewidywalny (CSPRNG, duża wartość losowa)
  - Token NIE powinien być przekazywany w cookie (w synchronizer pattern)
  - Token NIE może być w URL (wyciek przez Referer, logi, historia)
  - Bezpieczniej: wstaw CSRF token w custom HTTP header przez JavaScript (objęty same-origin policy)
- **Double Submit Cookie** (stateless): alternatywa gdy serwer nie przechowuje stanu
  - Rekomendowany wariant: **Signed Double-Submit Cookie** z HMAC
  - HMAC payload: sessionID + randomValue, klucz: tajny secret serwera
  - Zwykły double-submit (bez podpisu) jest podatny na cookie injection

### Defense-in-depth — dodatkowe warstwy

- **SameSite Cookie Attribute** (`Strict` lub `Lax`) — nie wystarcza sam, ale dobry suplement
- **Custom Request Headers** dla AJAX: `X-Requested-With: XMLHttpRequest` — same-origin policy blokuje cross-site
- **Origin/Referer header validation**: sprawdź czy request pochodzi z zaufanej domeny
- **User Interaction** (re-auth, MFA, CAPTCHA) dla wrażliwych operacji

### CSRF — common bypasses

- Token validated tylko na obecność (nie wartość)
- Token reuseable cross-session
- GET request akceptowany dla state-changing operations
- CSRF token w cookie, nie w hidden field (cookie injection)
- Brak CSRF check na alternative endpoints (legacy `/api/v1/`)

## Pentesterskie deep dive

### Mniej znane techniki

- **JSON CSRF via fetch + Content-Type**: niektóre frameworki wymagają `Content-Type: application/json` ale akceptują `text/plain` w fetch → bypass.
- **CSRF via XMLHttpRequest credentials**: jeśli CORS misconfigured, atakujący może `fetch('target', {credentials: 'include'})`.
- **Method override CSRF**: aplikacja honoruje `X-HTTP-Method-Override: PUT` w POST → bypass form-only CSRF protection.
- **Login CSRF**: atakujący loguje victim na atakera konto → user nieświadomie używa attacker's session.

### Common pitfalls

- **CSRF token tylko w API ale nie w form**: aplikacja wymaga w API ale akceptuje form z bez tokenu.
- **Token validated case-sensitive but stored case-insensitive**: można zgadnąć token z capital letters.

### Świeżynki z research

- **PortSwigger CSRF Lab**: https://portswigger.net/web-security/csrf
- **OWASP CSRF Prevention CS**: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| CSRF Scanner | Detect missing CSRF tokens |
| CO2 | CSRF PoC generation |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/05-Testing_for_Cross_Site_Request_Forgery
- OWASP CSRF Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html
- PortSwigger CSRF: https://portswigger.net/web-security/csrf

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V4.2.2 | CSRF defense per state-changing operation. |
| V3.4.1 | SameSite cookie attribute. |
