# WSTG-BUSL-02 — Test Ability to Forge Requests

## Cel

Wykrycie czy atakujący może sfałszować requesty: parameter tampering (zmiana ID/cen w hidden fields), CSRF, replay attacks, bypass workflow przez direct request crafting.

> **Test manual-only**: wymaga business logic understanding + custom requests via Burp.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Hidden field analysis**: każdy `<input type="hidden">` może zawierać manipulable values.
2. **API direct call**: bypass UI, wywołać API directly z modified body.
3. **Replay test**: capture valid request → replay z zmodyfikowanymi params.
4. **Workflow forging**: wymyślić request który normalnie nie jest UI-accessible.
5. **HMAC/signature verification**: czy aplikacja używa HMAC do podpisu critical params?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Hidden form field manipulation
- [ ] Cookie tampering (np. cart cookie z prices)
- [ ] HTTP method switching
- [ ] State parameter manipulation
- [ ] Direct API call bez UI
- [ ] Request replay
- [ ] HMAC signature validation
- [ ] CSRF token validation per request
- [ ] Mass assignment in body
- [ ] Timestamp manipulation (signed requests)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Forging Requests — kategorie ataków

- **CSRF**: zmuszenie przeglądarki użytkownika do wykonania requestu bez jego wiedzy
- **Parameter tampering**: modyfikacja ukrytych pól formularza, cen, ID
- **Replay attack**: ponowne wysłanie prawidłowego requestu
- **IDOR**: zmiana identyfikatorów obiektów (user_id, order_id) na cudze

### Obrona przed CSRF

- **Synchronizer Token**: unikalny token per sesja/request w formularzu (nie w cookie)
- **SameSite cookies**: `SameSite=Strict` lub `SameSite=Lax` — blokuj cross-origin requesty
- **Double Submit Cookie**: token w cookie + w body/header — porównanie server-side
- **Custom headers**: wymagaj custom headera (np. `X-Requested-With`) — przeglądarki nie dodają automatycznie cross-origin
- **Origin/Referer validation**: sprawdź header Origin/Referer — ale może być pusty

### Obrona przed Parameter Tampering

- **Server-side validation**: NIGDY nie ufaj danym od klienta — przeliczaj ceny, waliduj uprawnienia
- **HMAC/podpis**: podpisuj krytyczne dane (cena, ID) kluczem serwera — weryfikuj przy odbiorze
- **Integrity tokens**: hash parametrów + secret — wykrywaj modyfikacje
- **Allowlist parametrów**: akceptuj TYLKO oczekiwane pola (strong parameters)

### Obrona przed Replay Attacks

- **Nonce**: unikalny token per request — odrzuć request z reused nonce
- **Timestamp**: wymagaj recent timestamp w request (max 5 min) - chroni przed replay
- **Idempotency key**: unique ID per operation - duplicate ignored

## Pentesterskie deep dive

### Mniej znane techniki

- **HTTP method override**: aplikacja akceptuje `_method=DELETE` w POST body → bypass form CSRF protection.
- **JSON parameter pollution**: `{"id":1,"id":2}` - server takes one value, validation checks other.
- **HMAC bypass via constant-time comparison missing**: timing attack reveals expected HMAC.

### Common pitfalls

- **CSRF token validated tylko on presence, nie value**: empty token accepted.
- **Server-side prices ale client-side discounts**: discount calculated client-side.

### Świeżynki z research

- **PortSwigger CSRF Lab**: https://portswigger.net/web-security/csrf
- **HackTricks Parameter Pollution**: https://book.hacktricks.xyz/pentesting-web/parameter-pollution

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Repeater | Manual request modification |
| Param Miner | Hidden parameter discovery |
| Hackvertor | HMAC manipulation |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/02-Test_Ability_to_Forge_Requests
- OWASP CSRF Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V4.2.2 | CSRF defense per state-changing operation. |
| V11.1.1 | Business logic flows in sequential order. |
