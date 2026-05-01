# WSTG-ATHZ-03 — Testing for Privilege Escalation

## Cel

Wykrycie vertical privilege escalation (user → admin) i horizontal escalation (user A → user B): mass assignment role w body, JWT manipulation, forced browsing admin endpoints, mass-assignment-via-update.

> **Test mostly manual**: wymaga 2 user accounts (user + admin) + diff testing.

## Automatyzacja Nuclei

```bash
# Bypass headers (cross WSTG-ATHZ-02)
nuclei -l burp-export.xml -im burp -t templates/wstg-athz-02-bypass-headers.yaml

# Attack surface (admin panels)
nuclei -l burp-export.xml -im burp -t templates/wstg-info-04-attack-surface.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **2 accounts setup**: user + admin role.
2. **Endpoint enumeration**: lista wszystkich admin endpoints.
3. **Forced browsing**: jako user, próba dostępu do admin endpoints.
4. **Mass assignment**: w PUT /api/users/me, dodaj `role=admin` → czy backend akceptuje?
5. **JWT manipulation**: edit `role` claim → czy aplikacja akceptuje (bez signature validation)?
6. **Session puzzling**: czy reset password / registration ustawia auth state?

### Co MUSI być sprawdzone (12 punktów)

- [ ] Forced browsing wszystkich admin endpoints jako user
- [ ] Mass assignment w PUT/PATCH (role, isAdmin, permissions)
- [ ] JWT role claim edit (cross WSTG-SESS-10)
- [ ] Session puzzling (cross WSTG-SESS-08)
- [ ] Hidden form fields (`<input type="hidden" name="role">`)
- [ ] API version downgrade
- [ ] HTTP method switching
- [ ] Header bypass (cross WSTG-ATHZ-02)
- [ ] Cookie tampering (`role=admin`)
- [ ] OAuth scope escalation
- [ ] Multi-step privilege check (atakujący czyta state z 2-step flow)
- [ ] Promote action - czy admin promote prevent unauthorized?

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authorization_Cheat_Sheet.md, Access_Control_Cheat_Sheet.md

### Vertical Privilege Escalation — wektory ataku

- **Parametr roli w request**: `role=admin`, `isAdmin=true`, `userType=administrator`
- **Modyfikacja JWT claims**: zmiana `"role":"user"` na `"role":"admin"` w JWT payload
- **Forced browsing**: bezpośredni dostęp do `/admin/`, `/management/`, `/internal/`
- **HTTP method switching**: endpoint chroni GET ale nie POST/PUT/DELETE
- **API version bypass**: `/api/v1/admin` — starsza wersja API bez kontroli dostępu

### Obrona przed privilege escalation

- **Waliduj role SERVER-SIDE** na KAŻDYM request — nie polegaj na client-side
- Sprawdzaj uprawnienia do **KONKRETNEJ AKCJI**, nie tylko typ użytkownika
- **Deny by default** — jeśli brak jawnej reguły, ODMÓW dostępu
- Użyj **centralnego middleware** do kontroli dostępu — nie rozpraszaj logiki autoryzacji
- **Separuj funkcje administracyjne** od zwykłych użytkowników na poziomie kodu i infrastruktury
  - Oddzielny panel admin na innej subdomenie/porcie
  - Osobna warstwa middleware dla admin endpointów

### Modele kontroli dostępu

- **RBAC** (Role-Based): proste ale podatne na "role explosion" — role per zasób
- **ABAC** (Attribute-Based): bardziej granularne — atrybuty user, resource, action, context
- **ReBAC** (Relationship-Based): kontrola w oparciu o relacje (autor → swój post)

### Mass assignment

- **NIE akceptuj** pól `role`, `isAdmin`, `permissions`, `is_staff` z user input
- Allowlist pól (strong parameters / DTOs)
- Audit log changes do critical fields

## Pentesterskie deep dive

### Mniej znane techniki

- **Privilege escalation via `promote` action**: aplikacja allowing admin promote user → atakujący admin może add backdoor admin.
- **Concurrent role check race**: zmiana roli + parallel API call może execute z poprzednią rolą.
- **OAuth scope creep**: refresh token może requestować nowe scopes (broader than initial grant).
- **Multi-tenant tenant escape**: tenant_id manipulation w request body → access cross-tenant data.

### Common pitfalls

- **role check tylko na frontend**: atakujący direct API call.
- **role check w controller, brak w underlying service**: alternate entry.

### Świeżynki z research

- **PortSwigger Access Control labs**: https://portswigger.net/web-security/access-control
- **HackerOne disclosed reports - "privilege escalation"**: https://hackerone.com/hacktivity

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Autorize | Different role testing |
| AuthMatrix | Privilege matrix |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/05-Authorization_Testing/03-Testing_for_Privilege_Escalation
- OWASP Authorization CS: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V4.1.3 | Principle of least privilege. |
| V4.2.1 | Authz not bypassed by parameter tampering. |
| V5.1.4 | Mass assignment protection. |
