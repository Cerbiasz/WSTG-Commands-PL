# WSTG-ATHN-04 — Testing for Bypassing Authentication Schema

## Cel

Wykrycie ścieżek omijających authentication: forced browsing (direct URL access), HTTP method switching (GET zamiast POST), header injection (X-Original-URL, X-Forwarded-For 127.0.0.1), parameter manipulation (`?admin=true`), API version bypass (legacy `/api/v1/` bez auth).

> **Test mostly manual**: wymaga próbkowania paths + analizy requests bez auth.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Forced browsing**: lista chronionych URL (`/admin`, `/api/users`) → próba direct access bez auth.
2. **HTTP method switching**: GET zamiast POST, OPTIONS, PUT na chronionych endpointach.
3. **Header injection bypass**: `X-Forwarded-For: 127.0.0.1`, `X-Original-URL: /admin`, `X-Custom-IP-Authorization: 127.0.0.1`.
4. **Path manipulation**: `/admin/../admin`, `/admin;/`, `/%2e%2e/admin`, `/ADMIN/` (case sensitivity).
5. **Parameter manipulation**: `?authenticated=true`, `?admin=1`, `?debug=true`, `?role=admin`.
6. **API version bypass**: `/api/v1/admin` (legacy bez auth) vs `/api/v2/admin` (z auth).

### Co MUSI być sprawdzone (12 punktów)

- [ ] Forced browsing - direct URL access
- [ ] GET zamiast POST na auth endpoints
- [ ] HTTP method switching (PUT/DELETE/OPTIONS)
- [ ] X-Original-URL header
- [ ] X-Forwarded-For: 127.0.0.1
- [ ] X-Custom-IP-Authorization
- [ ] Path traversal w URL (`/admin/../admin`)
- [ ] Matrix params (`/admin;/public`)
- [ ] Case sensitivity (`/ADMIN`)
- [ ] Parameter manipulation
- [ ] API version downgrade
- [ ] Re-authentication for sensitive operations

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Walidacja uwierzytelnienia po stronie serwera

- **Każdy request** musi być walidowany server-side — nie polegaj na client-side checks
- Użyj globalnych filtrów/middleware: Java Filters, Django Middleware, Express middleware, .NET Filters
- **Deny by default** — jeśli brak jawnej reguły, ODMÓW dostępu

### Obejście uwierzytelnienia — wektory

- **Forced browsing**: bezpośredni dostęp do chronionych URL bez logowania
- **Path manipulation**: `/admin/../admin`, `/admin;/`, `/%2e%2e/admin`, `/ADMIN/` (case sensitivity)
- **HTTP method switching**: GET zamiast POST, OPTIONS, PUT na chronionych endpointach
- **Header injection**: `X-Forwarded-For: 127.0.0.1`, `X-Original-URL`, `X-Custom-IP-Authorization`
- **Parameter manipulation**: `?admin=true`, `?authenticated=true`, `?debug=true`
- **API version bypass**: stara wersja API (`/api/v1/`) może nie mieć autentykacji

### Re-autentykacja dla wrażliwych operacji

- **Zmiana hasła**: wymagaj podania AKTUALNEGO hasła
- **Płatności / przelewy**: wymagaj hasła lub MFA
- **Zmiana emaila / telefonu**: wymagaj hasła — atakujący może przejąć konto
- **Eksport danych**: wymagaj potwierdzenia tożsamości

## Pentesterskie deep dive

### Mniej znane techniki

- **HTTP/2 method smuggling**: HTTP/2 może być różnie traktowany przez frontend vs backend → method switch bypass.
- **`X-Original-URL` rewrite bypass**: aplikacja używa proxy która sprawdza URL ale forwards z `X-Original-URL` → backend uses header value.
- **Spring Security `;` matrix params bypass**: `/admin;/public` - older Spring Security skip auth filter.
- **Tomcat `..;/` path bypass**: ATM-2017-12615 / Ghostcat era → path normalization differences.
- **Authentication bypass via SQL injection in login**: `' OR 1=1--` w username field → bypass auth filter (but requires SQLi-vulnerable login).

### Common pitfalls

- **JWT `none` algorithm bypass**: starsze biblioteki JWT akceptują `alg: none` bez signature.
- **Frontend hides UI ale backend nie enforces**: `Login` button hidden via JS gdy "logged out" ale endpoint sam nie waliduje.

### Świeżynki z research

- **PortSwigger Authentication Bypass labs**: https://portswigger.net/web-security/authentication
- **HackTricks Authentication Bypass**: https://book.hacktricks.xyz/pentesting-web/login-bypass

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| AuthMatrix | Authz testing across roles |
| Authz | Per-endpoint auth testing |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/04-Testing_for_Bypassing_Authentication_Schema
- HackTricks Login Bypass: https://book.hacktricks.xyz/pentesting-web/login-bypass

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V2.1.1 | Authentication required for all functionality. |
| V4.1.1 | Access control rules at trusted layer. |
| V4.2.1 | Authorization not bypassed by parameter tampering. |
