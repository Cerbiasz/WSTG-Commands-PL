# WSTG-ATHZ-04 — Testing for Insecure Direct Object References (IDOR)

## Cel

Wykrycie IDOR (CWE-639): atakujący modyfikuje ID w URL/body (`/api/users/123`) → uzyskuje dostęp do cudzych zasobów. Numer #1 w OWASP API Top 10 (BOLA - Broken Object Level Authorization).

> **Test mostly manual**: wymaga 2 user accounts + diff testing each ID-bearing endpoint.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **2 accounts**: user A (ID 100), user B (ID 200).
2. **Endpoint enumeration**: każdy endpoint with ID parameter.
3. **Per endpoint test**: jako user A, użyj user B's ID → dostęp?
4. **Method variants**: GET/PUT/PATCH/DELETE - może GET protected ale DELETE nie?
5. **Burp Autorize**: automated testing per role.

### Co MUSI być sprawdzone (12 punktów)

- [ ] URL path: `/api/users/123/orders` → zmień 123
- [ ] Query parameters: `?invoice_id=1001` → 1002
- [ ] POST body: `{"account_id": "901"}`
- [ ] HTTP method variants (GET vs PUT vs DELETE)
- [ ] File names: `/uploads/report_userA.pdf`
- [ ] GraphQL aliases: `query{userA:user(id:100){...},userB:user(id:200){...}}`
- [ ] Sequential ID enumeration (predictable)
- [ ] UUID guessable (v1 timestamp-based)
- [ ] Indirect references via session
- [ ] Tenant isolation (multi-tenant apps)
- [ ] Hidden form field IDs
- [ ] WebSocket message IDs

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Czym jest IDOR

- IDOR (CWE-639) = Authorization Bypass Through User-Controlled Key
- Atakujący modyfikuje identyfikator obiektu (ID w URL, query param, body) aby uzyskać dostęp do cudzych zasobów
- Skutki: odczyt/modyfikacja/usunięcie cudzych danych, horizontal/vertical privilege escalation

### Mitygacje IDOR

- **Unikaj eksponowania ID** użytkownikowi — pobieraj dane na podstawie sesji/JWT (np. `/api/my-profile` zamiast `/api/user/123`)
- **Indirect references**: używaj mapowania per-sesja (np. OWASP ESAPI AccessReferenceMap) — wewnętrzny ID nie jest widoczny
- **Per-object access control**: sprawdzaj przy KAŻDYM użyciu czy użytkownik ma prawo do KONKRETNEGO obiektu
  - Nie wystarczy sprawdzić że użytkownik jest zalogowany — musisz zweryfikować że obiekt należy do niego
- **UUID/hash zamiast sekwencyjnych ID**: utrudnia zgadywanie, ale to NIE jest wystarczająca obrona sama w sobie
  - Security through obscurity — randomizacja ID musi być UZUPEŁNIONA access control checks

### Typowe wektory IDOR

- URL path: `/api/user/123/orders` → zmień 123 na 456
- Query parameters: `?invoice_id=1001` → `?invoice_id=1002`
- POST body: `{"account_id": "901"}` → `{"account_id": "523"}`
- Nazwy plików: `/uploads/report_userA.pdf` → `/uploads/report_userB.pdf`
- Cookies: `userId=100` → `userId=101`
- HTTP headers: `X-Account-Id: 100`

### Defense in depth — checklist

1. **Indirect references** (ESAPI AccessReferenceMap) — bezpośrednie ID nie są wystawione
2. **Per-object access control** — każdy access do obiektu sprawdza ownership
3. **UUIDs zamiast sequential** — utrudnia enumeration
4. **Logging** każdej próby dostępu — alertuj na anomalies
5. **Rate limiting** na endpoints with IDs — spowalnia enumeration

## Pentesterskie deep dive

### Mniej znane techniki

- **GraphQL aliases**: `query{a:user(id:1),b:user(id:2),c:user(id:3)...}` - bypass per-query rate limit, mass enumerate.
- **JSON parameter pollution**: `{"id":1,"id":2}` - niektóre parsery biorą first/last - bypass authz check on different value.
- **HTTP Parameter Pollution**: `?id=1&id=2` - server takes last, authz check parses first.
- **Numeric vs string ID confusion**: `?user_id=123` accepted, `?user_id="123"` accepted differently in some frameworks.
- **Time-based IDOR**: ID `12345` accessible at midnight (cron job creates), accessible till next day.
- **Predictable UUID v1**: timestamp-based UUID v1 → atakujący może predict patterns.

### Common pitfalls

- **Authz check tylko na primary route, brak na include**: `GET /orders/123` checks ownership, ale `GET /users/me?include=orders[123]` nie.
- **Sequential IDs "for performance"**: atakujący enumerates wszystkich users.
- **UUID v4 random ale brak access control**: security through obscurity.

### Świeżynki z research

- **PortSwigger IDOR Lab**: https://portswigger.net/web-security/access-control/idor
- **HackTricks IDOR**: https://book.hacktricks.xyz/pentesting-web/idor
- **OWASP API Top 10 - BOLA**: https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Autorize | Auto-detect IDOR |
| AuthMatrix | Per-role IDOR testing |
| Turbo Intruder | High-speed enumeration |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/05-Authorization_Testing/04-Testing_for_Insecure_Direct_Object_References
- OWASP IDOR Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html
- PortSwigger IDOR: https://portswigger.net/web-security/access-control/idor
- OWASP API Top 10 BOLA: https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V4.1.3 | Principle of least privilege. |
| V4.2.1 | Authz not bypassed by parameter tampering. |
| V4.3.3 | Sensitive resources require ownership check. |
