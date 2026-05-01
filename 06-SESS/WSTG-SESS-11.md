# WSTG-SESS-11 — Testing for Concurrent Sessions

## Cel

Audyt obsługi wielu jednoczesnych sesji per user: czy aplikacja allows multi-device login, czy zmiana hasła invaliduje other sessions, czy "Sign out all devices" działa, czy active sessions widoczne w settings.

> **Test mostly manual**: wymaga 2 devices/browsers + interakcji.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Login z 2 different browsers**: czy obie sesje działają equally?
2. **Active sessions visibility**: czy user widzi listę aktywnych sesji w settings?
3. **Password change test**: zmień hasło na browser A → czy browser B wylogowany?
4. **Sign out all devices**: czy endpoint istnieje? Czy działa?
5. **Concurrent session limit**: jeśli aplikacja limits do 1 session, czy nowy login wylogowuje stary?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Multi-device login allowed (lub limit określony per design)
- [ ] Active sessions widoczne (IP, UA, czas, lokalizacja)
- [ ] Password change wylogowuje other sessions
- [ ] Reset password wylogowuje all sessions (po reset)
- [ ] "Sign out all devices" endpoint
- [ ] User-initiated session revocation (per device)
- [ ] Concurrent session limit (banking: 1; standard: unlimited)
- [ ] Notification email gdy nowy login z innego device

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Kontrola jednoczesnych sesji

- Zdecyduj czy aplikacja pozwala na wiele jednoczesnych sesji per użytkownik
- **Aplikacje wrażliwe (bankowość, admin)**: ogranicz do 1 aktywnej sesji — nowe logowanie unieważnia stare
- **Aplikacje ogólne**: pozwól na wiele sesji, ale INFORMUJ użytkownika o aktywnych sesjach
- Implementuj widok "aktywne sesje" — użytkownik widzi listę (IP, UA, czas, lokalizacja)

### Unieważnianie sesji przy zmianie hasła

- Po zmianie hasła: unieważnij WSZYSTKIE aktywne sesje POZA bieżącą
- Chroni przed scenariuszem: wykradzione credentials → atakujący zalogowany → użytkownik zmienia hasło → atakujący nadal zalogowany
- To samo po: resetowaniu hasła, kompromitacji konta, zmianie uprawnień

### "Logout everywhere" / "Wyloguj ze wszystkich urządzeń"

- Implementuj endpoint do unieważnienia WSZYSTKICH sesji użytkownika
- Wymagaj re-auth (current password / MFA) - chroni przed CSRF wymuszającym DoS
- Po wylogowaniu wszystkich: notyfikacja email

### Notyfikacje login

- Wysyłaj email gdy nowy login z innego device/lokalizacji
- Treść: device info, IP, czas, link "to nie ja - zmień hasło"
- Implementuj device fingerprinting (browser+IP+geolocation)

## Pentesterskie deep dive

### Mniej znane techniki

- **Session enumeration via active sessions endpoint**: jeśli endpoint pokazuje session IDs, atakujący po IDOR może see other users' sessions.
- **Password change race condition**: jeśli session invalidation jest async, atakujący może zdążyć przed cleanup.
- **OAuth refresh token longevity**: nawet po password change, OAuth refresh tokens mogą być valid jeszcze 30 dni.

### Common pitfalls

- **Password change wylogowuje tylko current session**: other devices nadal valid.
- **No "Sign out all devices" endpoint**: user nie ma sposobu na cleanup.
- **Session limit bez user notification**: nowy login cicho wylogowuje stary - user confused.

### Świeżynki z research

- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- **Sam Curry session management research**: https://samcurry.net/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Repeater | Multi-session testing |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/11-Testing_for_Concurrent_Sessions
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.6.1 | Concurrent session limits enforced. |
| V3.7.1 | Active sessions visible to user. |
| V3.3.4 | Re-authentication after privilege change. |
