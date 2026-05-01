# WSTG-ATHZ-02 — Testing for Bypassing Authorization Schema

## Cel

Wykrycie ścieżek omijających authorization checks: header injection (X-Original-URL, X-Forwarded-For 127.0.0.1), HTTP method switching, path manipulation (case, matrix params, encoding), API version downgrade.

## Automatyzacja Nuclei

```bash
nuclei -l burp-export.xml -im burp -t templates/wstg-athz-02-bypass-headers.yaml
```

Aktywnie testuje typowe bypass headers + path manipulations + HTTP method switching na typowych admin endpoints.

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| X-Original-URL bypass | ✓ |
| X-Forwarded-For 127.0.0.1 | ✓ |
| Path manipulation (case, encoding, matrix) | ✓ |
| HTTP method switching | ✓ |
| Per-endpoint authz check | manual via Burp Autorize |
| Multi-user differential testing | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Endpoint enumeration**: lista wszystkich protected endpoints (z WSTG-INFO-04).
2. **Per endpoint - bypass test**: różne header/path bypass attempts.
3. **Burp Autorize**: register session for each role, test każdego endpointu z każdą rolą.
4. **JWT manipulation**: zmień `role` claim w JWT, czy aplikacja akceptuje (cross WSTG-SESS-10)?
5. **Body parameter mass assignment**: dodaj `role=admin` do body request (cross WSTG-IDNT-02).

### Co MUSI być sprawdzone (12 punktów)

- [ ] X-Original-URL: /admin
- [ ] X-Rewrite-URL: /admin
- [ ] X-Forwarded-For: 127.0.0.1
- [ ] X-Custom-IP-Authorization: 127.0.0.1
- [ ] Path manipulation (case, encoding, matrix params)
- [ ] HTTP method switching (GET/POST/PUT/DELETE)
- [ ] API version downgrade (`/api/v1/admin` vs `/api/v2/admin`)
- [ ] JWT role claim manipulation
- [ ] Mass assignment w request body
- [ ] BOLA (Broken Object Level Authorization)
- [ ] Function level authorization (admin functions accessible by user?)
- [ ] Tenant isolation (multi-tenant apps)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authorization_Cheat_Sheet.md, Access_Control_Cheat_Sheet.md

### Fundamentalne zasady autoryzacji

- **Deny by Default**: jeśli brak jawnej reguły — ODMÓW dostępu; każde uprawnienie musi być jawnie przyznane
- **Least Privilege**: przydzielaj MINIMUM uprawnień potrzebnych do wykonania zadania — horyzontalnie i wertykalnie
- **Waliduj przy KAŻDYM użyciu**: sprawdzaj uprawnienia na KAŻDY request, niezależnie od źródła (AJAX, server-side, API)
  - Użyj globalnych filtrów/middleware: Java Filters, Django Middleware, .NET Core Filters, Laravel Middleware

### Model kontroli dostępu

- Preferuj **ABAC** (Attribute-Based) lub **ReBAC** (Relationship-Based) nad **RBAC** (Role-Based)
  - RBAC: proste ale podatne na "role explosion", słabo obsługuje fine-grained permissions
  - ABAC: uwzględnia wiele atrybutów (rola, czas, lokalizacja, urządzenie) — lepsza obrona least privilege
  - ReBAC: kontrola dostępu na podstawie relacji między użytkownikiem a zasobem (np. "autor może edytować swój post")

### Obrona przed bypass autoryzacji

- NIE polegaj na client-side access control — atakujący może ominąć JavaScript/CSS ukrywające elementy
- Sprawdzaj autoryzację **SERVER-SIDE**, na gateway lub w serverless function
- Unikaj eksponowania identyfikatorów (ID) użytkownikowi — jeśli to możliwe, pobieraj dane na podstawie sesji/JWT
- Jeśli ID są eksponowane — używaj **UUID/hash** zamiast sekwencyjnych numerów
- Sprawdzaj uprawnienia do **KONKRETNEGO obiektu**, nie tylko do typu obiektu

### Typowe wektory bypass

- **Forced browsing**: `/admin/`, `/api/admin/users` bez logowania
- **Path manipulation**: `/admin/..%2f`, `/Admin`, `/admin;/`, `/admin//`
- **HTTP method switching**: GET zamiast POST, PUT/DELETE
- **Header injection**: `X-Original-URL`, `X-Rewrite-URL`, `X-Forwarded-For: 127.0.0.1`
- **Parameter manipulation**: `?admin=true`, `?role=admin`
- **API version bypass**: legacy `/api/v1/` bez auth
- **JWT manipulation**: zmiana claim `role` lub `alg=none`

## Pentesterskie deep dive

### Mniej znane techniki

- **JBoss HEAD bypass**: niektóre wersje JBoss tylko walidują GET/POST — HEAD daje content access bez auth.
- **Tomcat `..;/` bypass**: Spring Security bypass via matrix params (`/admin/..;/public/`).
- **Sub-path access**: `/admin/users` protected ale `/admin/users.json` nie - alternative file extension.
- **CORS preflight bypass**: niektóre aplikacje zwracają full response na OPTIONS bez auth check.

### Common pitfalls

- **Frontend hides admin button = security illusion**: backend musi enforce.
- **Authz w controller, brak w service layer**: alternative endpoints używające same service bypass authz.

### Świeżynki z research

- **PortSwigger Access Control labs**: https://portswigger.net/web-security/access-control
- **HackTricks Login Bypass**: https://book.hacktricks.xyz/pentesting-web/login-bypass

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Autorize | Test endpoints with/without auth |
| AuthMatrix | Authz matrix across roles |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/05-Authorization_Testing/02-Testing_for_Bypassing_Authorization_Schema
- OWASP Authorization CS: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- PortSwigger Access Control: https://portswigger.net/web-security/access-control

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V4.1.1 | Access control rules at trusted layer. |
| V4.2.1 | Authz checks not bypassed by parameter tampering. |
| V4.2.2 | CSRF defense per state-changing operation. |
