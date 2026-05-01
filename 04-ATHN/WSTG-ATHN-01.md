# WSTG-ATHN-01 — Testing for Credentials Transported over an Encrypted Channel

## Cel

Weryfikacja że credentials (login, password, MFA codes) przesyłane są tylko przez HTTPS. Login form na HTTP = atakujący w MitM przechwytuje plaintext credentials.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-athn-01-credentials-transport.yaml
```

Wykrywa: login form na HTTP page, form action HTTP, auth API endpoint via HTTP, MFA challenge na HTTP, Basic Auth challenge na HTTP.

### Cross-reference

```bash
# Pełny transport security (CRYP-03)
nuclei -l burp-export.xml -im burp -t templates/wstg-cryp-03-unencrypted-channels.yaml

# HSTS (CONF-07)
nuclei -l burp-export.xml -im burp -t templates/wstg-conf-07-hsts.yaml
```

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| Login form na HTTP | ✓ |
| Form action HTTP | ✓ |
| API auth endpoint via HTTP | ✓ |
| MFA challenge HTTP | ✓ |
| Basic Auth na HTTP | ✓ |
| HSTS | cross-ref CONF-07 |
| TLS protocol/cipher analysis | testssl.sh |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **HTTP probe**: GET na port 80 - czy serwowane treści, czy redirect 301?
2. **Form action audit**: wszystkie `<form>` elementy - target HTTPS?
3. **API endpoints**: każdy auth endpoint (login, register, reset, MFA) - tylko HTTPS?
4. **HSTS verify**: nasz CONF-07 + check preload status.

### Co MUSI być sprawdzone (8 punktów)

- [ ] HTTP redirect 301 do HTTPS
- [ ] Login form action używa HTTPS (relative na HTTPS page też OK)
- [ ] Password reset flow tylko przez HTTPS
- [ ] MFA enrollment / challenge tylko HTTPS
- [ ] OAuth callback URLs HTTPS
- [ ] HSTS poprawny (max-age, includeSubDomains, preload)
- [ ] Brak mixed content na login page
- [ ] Cookies z Secure flag

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transport_Layer_Security_Cheat_Sheet.md, HTTP_Strict_Transport_Security_Cheat_Sheet.md

### Konfiguracja TLS

- Wymuszaj **TLS 1.2+** dla wszystkich połączeń — wyłącz TLS 1.0/1.1 (przestarzałe, podatne na POODLE, BEAST)
- Preferuj **TLS 1.3** — eliminuje starsze, niebezpieczne cipher suites, szybszy handshake
- Wyłącz słabe cipher suites: **RC4, DES, 3DES, NULL, EXPORT, aNULL, eNULL**
- Preferuj **AEAD cipher suites**: AES-GCM, ChaCha20-Poly1305
- Preferuj **ECDHE** (Elliptic Curve Diffie-Hellman Ephemeral) — zapewnia Perfect Forward Secrecy (PFS)
- Formularz logowania i endpoint POST MUSZĄ być na HTTPS — brak HTTPS ujawnia credentials w sieci

### HSTS (HTTP Strict Transport Security)

- Włącz HSTS z: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `max-age` minimum **31536000** (1 rok) — krótsza wartość daje mniejszą ochronę
- `includeSubDomains` — chroni wszystkie subdomeny (WAŻNE: upewnij się że WSZYSTKIE subdomeny obsługują HTTPS)
- `preload` — dodaj domenę do HSTS Preload List (hstspreload.org) — przeglądarka wymusza HTTPS bez pierwszego HTTP request
- HSTS chroni przed: SSL stripping (sslstrip), downgrade attacks, mixed content issues

### Mixed Content

- WSZYSTKIE zasoby (obrazy, CSS, JS, fonty, iframe) muszą być ładowane przez HTTPS
- Mixed content: HTTP resources na stronie HTTPS — przeglądarka może je zablokować lub wyświetlić ostrzeżenie

## Pentesterskie deep dive

### Mniej znane techniki

- **sslstrip2 z HSTS bypass**: nowsze warianty obejmują HSTS preload mapping subset → effective gdy aplikacja nowo dodana.
- **HTTP/2 cleartext (h2c)**: niektóre internal services używają h2c za reverse proxy → bypass TLS jeśli proxy nie enforces.
- **Captive portal bypass**: Wi-Fi captive portal redirects HTTPS to HTTP login → user enters creds on HTTP.
- **OAuth state via insecure channel**: redirect_uri http:// zwraca authorization code w URL → MitM intercept.

### Common pitfalls

- **HTTPS na main domain ale HTTP na subdomain login**: `login.target.com` może być HTTP gdy main jest HTTPS.
- **HSTS bez preload**: pierwszy request idzie przez HTTP - vulnerable do sslstrip.

### Świeżynki z research

- **HTTPS-Only Mode w browserach** (Firefox/Chrome): nowy default upgrades all HTTP to HTTPS.
- **PortSwigger TLS labs**: https://portswigger.net/web-security

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Software Version Reporter | Detekcja insecure versions |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/01-Testing_for_Credentials_Transported_over_an_Encrypted_Channel
- OWASP TLS CS: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html
- HSTS Preload: https://hstspreload.org/

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V9.1.1 | TLS for all client connectivity. |
| V2.7.1 | Authentication credentials always over TLS. |
| V14.4.5 | HSTS with sufficient max-age. |
