# WSTG-APIT-02 — API Broken Object Level Authorization (BOLA)

## Cel

BOLA = #1 podatność w OWASP API Top 10 2023. Atakujący zmienia ID obiektu w URL/body → uzyskuje dostęp do cudzych danych. Cross-ref WSTG-ATHZ-04 (IDOR jest tym samym).

> **Test mostly manual**: wymaga 2 user accounts + diff testing per endpoint.

## Automatyzacja Nuclei

```bash
# Cross-ref - to jest IDOR z perspektywy API
nuclei -l burp-export.xml -im burp -t templates/wstg-athz-02-bypass-headers.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **API endpoint enumeration**: każdy endpoint with ID parameter (cross WSTG-APIT-01).
2. **2 accounts setup**: user A + user B z own resources.
3. **Cross-user test**: jako user A, requestować user B's resources via ID swap.
4. **Method variants**: GET (read), PUT (update), DELETE (delete).
5. **Burp Autorize**: automated per-role testing.

### Co MUSI być sprawdzone (10 punktów)

- [ ] `/api/users/{id}` - cross user
- [ ] `/api/orders/{id}` - cross user
- [ ] `/api/users/{id}/documents` - nested resources
- [ ] Per HTTP method (GET/PUT/DELETE)
- [ ] POST body `{"user_id": ...}`
- [ ] Query parameters
- [ ] File names (`/uploads/report_userA.pdf`)
- [ ] GraphQL aliases `query{a:user(id:1),b:user(id:2)}`
- [ ] Tenant isolation (multi-tenant)
- [ ] WebSocket message IDs

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### BOLA/IDOR — #1 podatność API (OWASP API Top 10)

- **Broken Object Level Authorization** — najczęstszy typ podatności w API
- Atakujący zmienia ID obiektu w URL/body aby uzyskać dostęp do cudzych danych
- Dotyczy: GET (odczyt), PUT/PATCH (modyfikacja), DELETE (usuwanie)

### Gdzie szukać BOLA

| Endpoint | Atak |
|----------|------|
| `/api/users/{id}` | Zmień `id` na innego użytkownika |
| `/api/orders/{id}` | Odczytaj zamówienia innego użytkownika |
| `/api/users/{id}/documents` | Nested resources innego użytkownika |
| `/api/invoices/{id}/download` | Pobierz fakturę innego użytkownika |
| Request body: `{"user_id": 123}` | Zmień user_id na cudze |

### Obrona przed BOLA

- **Per-object access control**: sprawdzaj przy KAŻDYM użyciu czy user ma prawo do KONKRETNEGO obiektu
- **Indirect references**: używaj indirect tokens zamiast prawdziwych ID
- **Avoid sequential IDs**: UUID v4 zamiast numerów - utrudnia enumeration
- **Audit logging**: każda próba dostępu logged
- **Burp Autorize / AuthMatrix**: automatyzacja testowania per-endpoint

### API Top 10 (2023)

1. **API1:2023 - Broken Object Level Authorization** (BOLA) — ten test
2. **API2:2023 - Broken Authentication**
3. **API3:2023 - Broken Object Property Level Authorization**
4. **API4:2023 - Unrestricted Resource Consumption**
5. **API5:2023 - Broken Function Level Authorization**
6. **API6:2023 - Unrestricted Access to Sensitive Business Flows**
7. **API7:2023 - Server Side Request Forgery**
8. **API8:2023 - Security Misconfiguration**
9. **API9:2023 - Improper Inventory Management**
10. **API10:2023 - Unsafe Consumption of APIs**

## Pentesterskie deep dive

### Mniej znane techniki

- **GraphQL alias enumeration**: bypass per-query rate limit, mass enumerate users.
- **Indirect BOLA via include**: `?include=orders[123]` może bypass primary route check.
- **Numeric vs string ID confusion**: niektóre frameworks różnie traktują `"123"` vs `123`.
- **Time-based BOLA**: ID dostępne tylko w określone godziny (cron creates).
- **API4 (rate limit) bypass via different IP per request**.

### Common pitfalls

- **Authz check tylko na primary route**: alternative routes share same service bypass.
- **UUID v4 random ale brak access control**: security through obscurity.

### Świeżynki z research

- **OWASP API Top 10**: https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/
- **PortSwigger Access Control**: https://portswigger.net/web-security/access-control
- **HackTricks IDOR**: https://book.hacktricks.xyz/pentesting-web/idor

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Autorize | Cross-user authz testing |
| AuthMatrix | Per-endpoint + per-role matrix |
| Turbo Intruder | High-speed enumeration |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/12-API_Testing/02-Testing_API_Broken_Object_Level_Authorization
- OWASP API Top 10 2023: https://owasp.org/API-Security/
- OWASP IDOR CS: https://cheatsheetseries.owasp.org/cheatsheets/Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V4.2.1 | Authz not bypassed by parameter tampering. |
| V4.3.3 | Sensitive resources require ownership check. |
