# WSTG-SESS-08 — Testing for Session Puzzling

## Cel

Wykrycie session variable overloading: ta sama session variable używana w różnych kontekstach (login, password reset, registration). Atakujący inicjuje flow A który ustawia variable → użycie w flow B z innym znaczeniem = privilege escalation.

> **Test mostly manual**: wymaga business logic understanding + multi-step exploitation.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify session variables**: monitorować Burp aby zobaczyć jakie variables aplikacja używa per flow.
2. **Cross-flow inspection**: czy `$_SESSION['user']` używane w login + reset password + registration?
3. **Flow injection**: inicjuj password reset (sets `user='admin'`) → przejdź do dashboard - czy zalogowany jako admin?
4. **State machine**: czy aplikacja sprawdza state transitions (login → dashboard valid; reset → dashboard invalid)?
5. **Race condition**: simultaneous requests w różnych flows → race conditions exploitable?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Session variables namespaced (np. `auth_user`, `reset_user`)
- [ ] State machine validation (np. authenticated state vs reset state)
- [ ] Reset password flow nie ustawia auth state
- [ ] Registration flow nie ustawia auth state pre-verification
- [ ] OAuth flow not session-puzzling (state parameter validation)
- [ ] Race conditions in multi-step flows
- [ ] Session variables cleared between flows
- [ ] Session regenerated po każdym sensitive flow

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Czym jest Session Puzzling

- Ta sama zmienna sesji używana w RÓŻNYCH kontekstach (np. "user" w login i reset password)
- Atakujący: inicjuje flow A który ustawia zmienną → używa jej w flow B z innym znaczeniem
- Przykład: reset password ustawia `$_SESSION['user'] = 'admin'` → atakujący przechodzi do dashboard

### Izolacja zmiennych sesji

- **Oddzielne namespace** per funkcjonalność — nie dziel zmiennych między modułami
- Używaj precyzyjnych nazw: `$_SESSION['auth_user']` zamiast `$_SESSION['user']`
- Nie używaj tej samej zmiennej do różnych celów (autentykacja, autoryzacja, reset)

### Walidacja stanów sesji

- Implementuj **state machine** — sprawdzaj czy użytkownik przeszedł WYMAGANE kroki
- Przykład: nie pozwalaj na dostęp do dashboard bez przejścia przez login
- W każdym handler sprawdź expected state vs actual state

### Czyszczenie sesji między flows

- Po każdym kompletnym flow: clear session variables nie related do następnego flow
- Po reset password completion: clear reset state, force re-login
- Session.regenerate() nie wystarcza - trzeba też clear variables

## Pentesterskie deep dive

### Mniej znane techniki

- **Reset password → login bypass**: jeśli reset flow sets `user_id`, dashboard sprawdza tylko `if (user_id) authorized` → bypass.
- **Registration → privilege escalation**: rejestracja sets pending_user, ale auth filter sprawdza tylko `user` (general).
- **OAuth state confusion**: OAuth flow A sets state, flow B uses different OAuth provider with same state.

### Common pitfalls

- **Generic session variable name like 'user'**: używana w wszystkich flows.
- **No state machine**: linear handler bez sprawdzania expected sequence.

### Świeżynki z research

- **PortSwigger Authentication labs**: https://portswigger.net/web-security/authentication
- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Repeater | Multi-flow exploitation |
| Logger++ | Track session variable changes |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/08-Testing_for_Session_Puzzling
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V11.1.1 | Business logic flows in sequential order. |
| V11.1.2 | Business logic flows have all steps performed. |
