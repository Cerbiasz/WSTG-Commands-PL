# WSTG-IDNT-01 — Test Role Definitions

## Cel

Audyt definicji ról i uprawnień w aplikacji: czy role są jasno zdefiniowane, czy uprawnienia są granularne, czy nie ma role explosion (zbyt wiele ról). Test prerekursywny dla całego ATHZ — bez mapy ról nie można testować autoryzacji.

> **Test manual**: wymaga rozumienia business logic + dostępu do dokumentacji ról. Nuclei nie ma direct testu - cross-ref WSTG-ATHZ dla aktywnych testów uprawnień.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Documentation review**: zebrać role matrix z docs / dev team. Każda rola → expected permissions.
2. **Login as each role**: uzyskać accounts dla każdej zdefiniowanej roli. Nawigacja → mapowanie endpoints accessible per role.
3. **Cross-role test**: dla każdego endpointu `/api/admin/*` testować dostęp jako nie-admin (BOLA/IDOR).
4. **Privilege escalation**: spróbować mass assignment (`role=admin` w request body), JWT manipulation (zmiana `role` claim).
5. **Audit trail check**: czy aplikacja loguje permission checks i naruszenia?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Lista wszystkich ról udokumentowana
- [ ] Per role: expected permissions matrix
- [ ] Login jako każda rola - dostępne endpointy
- [ ] Horizontal escalation: user A → resources of user B
- [ ] Vertical escalation: user → admin
- [ ] Mass assignment in request body (role=admin)
- [ ] JWT `role` claim manipulation
- [ ] Hidden form fields containing role/permission
- [ ] Audit logging permission denials
- [ ] Role inheritance hierarchy (admin includes user permissions?)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Access_Control_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Definicja ról i uprawnień

- **Role**: grupują uprawnienia (admin, user, moderator, manager, readonly)
- **Uprawnienia**: granularne akcje (create_user, delete_order, view_report)
- Unikaj **role explosion** — zbyt wiele ról = trudne do zarządzania
- Preferuj **ABAC/ReBAC** nad RBAC dla fine-grained permissions

### Wymuszanie autoryzacji

- **Server-side ONLY** — NIGDY nie polegaj na client-side (JavaScript, hidden fields, localStorage)
- **Deny by default** — dostęp tylko jeśli jawnie przyznany
- **Centralny middleware** — unikaj rozproszonych checków w kodzie (łatwe do pominięcia)
- **Każdego request** waliduj — nie zakładaj że sesja = autoryzacja

### Separacja uprawnień

- Oddzielne panele admin od user interface (inna subdomena/port)
- Funkcje administracyjne w oddzielnym module/kontrolerze
- Osobny middleware autoryzacji dla admin endpointów

### Testowanie zdefiniowanych ról

- Zmapuj WSZYSTKIE role w systemie i ich oczekiwane uprawnienia
- Zaloguj się jako każda rola → testuj dostęp do endpointów innych ról
- Testuj **horizontal** (user A → zasoby user B) i **vertical** (user → admin) escalation
- Manipuluj parametry: `role=admin`, `isAdmin=true`, JWT claims
- Użyj Burp Autorize/AuthMatrix do automatycznego porównywania

### Logging i audit

- Loguj WSZYSTKIE próby dostępu i naruszenia autoryzacji
- Loguj zmiany uprawnień (kto, kiedy, co zmieniono)
- Alertuj na powtarzające się próby eskalacji
- Regularny audit ról i uprawnień — usuń nieużywane konta i nadmiarowe uprawnienia

## Pentesterskie deep dive

### Mniej znane techniki

- **ABAC bypass via attribute manipulation**: ABAC (Attribute-Based Access Control) decisions polegają na user attributes (department, project). Manipulacja attributes (np. via SAML response) = bypass.
- **JWT role claim escalation**: jeśli `alg: HS256` z weak secret + atakujący zna public key → forge JWT z `role: admin`.
- **Role caching exploitation**: niektóre aplikacje cache role decisions per session - po elevation, zmiana roli nie effective do następnego login. Może być inverse też - downgrade nie disconnects session.
- **Multi-tenant role isolation**: gdy aplikacja serwuje multiple orgs, role w org A musi być isolated od org B. Testować cross-tenant access.
- **GraphQL field-level authz bypass**: niektóre GraphQL implementations check authz na query level ale nie na nested fields - bypass via fragment.

### Common pitfalls

- **Frontend hides admin button = security**: false sense - backend musi enforce. Atakujący direct API call.
- **Role check w controller, brak w service layer**: jeśli inne endpoints używają same service, bypass via alternative entry point.
- **Default role "user" can be changed by self**: rejestracja user może edit own role w PUT /me request body.

### Świeżynki z research

- **OWASP Authorization Testing Cheat Sheet**: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Testing_Automation_Cheat_Sheet.html
- **Burp AuthMatrix / Autorize**: tooling for automated authz testing
- **HackTricks Privilege Escalation**: https://book.hacktricks.xyz/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| AuthMatrix | Matrix testing of authz across roles | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |
| Autorize | Automated authz bypass detection | [GitHub](https://github.com/Quitten/Autorize) |
| JWT Editor | Manipulacja JWT roles | [GitHub](https://github.com/PortSwigger/jwt-editor) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/03-Identity_Management_Testing/01-Test_Role_Definitions
- OWASP Access Control CS: https://cheatsheetseries.owasp.org/cheatsheets/Access_Control_Cheat_Sheet.html
- OWASP Authorization CS: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- HackTricks Privilege Escalation: https://book.hacktricks.xyz/pentesting-web

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.1.1 | General Access Control (L1) | Application enforces access control rules at trusted layer. |
| V4.1.3 | General Access Control (L1) | Principle of least privilege exists. |
| V4.2.1 | Operation Level (L1) | Authorization checks not bypassed by parameter tampering. |
