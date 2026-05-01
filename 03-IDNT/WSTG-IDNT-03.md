# WSTG-IDNT-03 — Test Account Provisioning Process

## Cel

Audyt provisioning kont (admin tworzy konta) i de-provisioning (usuwanie/dezaktywacja). Krytyczne: czy usunięty user traci natychmiast wszystkie sesje, czy provisioning ma proper authz check, czy invite tokens są bezpieczne.

> **Test mostly manual**: provisioning workflow wymaga admin access + multi-user scenario. Nuclei nie ma direct testu.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Authz check**: kto może provisioning - tylko admin? testować z user role.
2. **De-provisioning effectiveness**: po usunięciu user, czy stary token JWT/session nadal działa?
3. **Invite token security**: brute-force, reuse, scope (czy invitee dostaje większe permissions niż inviter)?
4. **Bulk provisioning**: rate limiting, validation per-record, CSV/JSON injection.
5. **Audit trail**: wszystkie provisioning actions logged?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Provisioning endpoint requires admin role
- [ ] Self-escalation prevention (user can't elevate self)
- [ ] Created account has correct role (no privilege escalation via body)
- [ ] De-provisioning revokes all sessions immediately
- [ ] Refresh tokens revoked
- [ ] JWT denylist for revoked tokens
- [ ] Invite token: CSPRNG, jednorazowy, krótki TTL
- [ ] Invite token reuse blocked
- [ ] Bulk provisioning rate limited
- [ ] Audit log entries (who provisioned/deprovisioned what)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Provisioning kont — kontrola dostępu

- **Tylko autoryzowane role** mogą tworzyć/modyfikować/usuwać konta
- Sprawdzaj uprawnienia na **każdym endpoincie** provisioningu (BOLA/IDOR)
- Waliduj role przypisywane nowym kontom — nie pozwalaj na self-escalation
- Testuj: tworzenie konta admin przez zwykłego usera, tworzenie bez autoryzacji

### De-provisioning — usuwanie kont

- Usunięty/dezaktywowany użytkownik musi natychmiast **utracić** wszystkie sesje i tokeny
- Sprawdź czy token usuniętego użytkownika nadal działa (dangling sessions)
- Odwołaj refresh tokens, invalidate JWT (denylist), usuń sesje server-side
- Audit trail: loguj kto, kiedy i jakie konto stworzył/usunął/zmodyfikował

### Invite/zaproszenia

- Tokeny zaproszeniowe: CSPRNG, jednorazowe, krótki TTL (24-72h)
- Nie pozwalaj na reuse tokenu zaproszenia po aktywacji
- Ogranicz scope zaproszenia — nie pozwalaj zapraszającemu nadać wyższych uprawnień niż posiada
- Sprawdź czy token zaproszenia może być brute-forced

### Bulk provisioning

- Ogranicz rozmiar batch requestów (max. 100 użytkowników na raz)
- Waliduj każdy rekord indywidualnie — nie pozwalaj na injection w CSV/JSON batch
- Rate limiting na endpoincie bulk provisioning

## Pentesterskie deep dive

### Mniej znane techniki

- **Dangling session post-deprovision**: aplikacja usuwa user z DB ale JWT signed valid pozostaje aktywny do expiry → effective bypass deprovision.
- **Invite token via leaked log**: tokens w URL logged on server / proxy → atakujący z log access przejmuje invite.
- **Privilege escalation via "promote" action**: admin promuje user do admin → atakujący-admin może dodać new admin → backdoor.
- **Race condition w deactivate**: deactivate + parallel API call from same user session → API call may succeed.
- **Bulk CSV injection**: CSV uploads z `=cmd|'/c calc'!A1` w cell - if Excel exports → Excel formula injection (CVE-class).

### Common pitfalls

- **Soft-delete sets `deleted_at` ale auth filter checks not always**: edge cases where deleted account can still authenticate.
- **OAuth refresh tokens not invalidated**: classic - access token expires in 1h, but refresh token valid 30 days post-deprovision.

### Świeżynki z research

- **OWASP Authentication CS**: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- **Sam Curry account takeover**: https://samcurry.net/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| AuthMatrix | Authz testing across roles | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/03-Identity_Management_Testing/03-Test_Account_Provisioning_Process
- OWASP Authentication CS: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP Authorization CS: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.3.1 | Session Logout (L1) | Logout invalidates session immediately. |
| V3.3.4 | Session Termination (L2) | Re-authentication after privilege change. |
| V4.1.5 | General Access Control (L2) | Access control fails secure. |
