# WSTG-IDNT-02 — Test User Registration Process

## Cel

Audyt procesu rejestracji: weryfikacja email, walidacja danych, mass assignment (privilege escalation w request body), enumeracja userów przez "Username already taken", rate limiting (mass account creation), CAPTCHA.

> **Test mostly manual**: registration flow wymaga interakcji + analyzy responses. Cross-ref WSTG-IDNT-04 (account enumeration markers).

## Automatyzacja Nuclei

```bash
# Account enumeration markers (registration "username taken" pattern)
nuclei -l burp-export.xml -im burp -t templates/wstg-idnt-04-account-enumeration.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Mass assignment test**: dodać `"role":"admin"`, `"isAdmin":true`, `"is_staff":true`, `"permissions":[...]` do body rejestracji.
2. **Email verification**: czy wymagana? Jeśli nie - dummy email = active account = spam/abuse vector.
3. **Rate limiting**: spróbować 100 rejestracji z tego samego IP w 1 minutę.
4. **Username enumeration**: rejestracja existing user → "Username already taken" (cross-ref IDNT-04).
5. **Password policy**: minimum length, complexity, breached password check (HIBP API).
6. **Injection testing**: SQLi/XSS/SSTI w polach username/email/firstName/lastName.

### Co MUSI być sprawdzone (12 punktów)

- [ ] Email verification required pre-activation
- [ ] Token verification: CSPRNG, jednorazowy, krótki TTL
- [ ] Mass assignment: `role`, `isAdmin`, `is_staff`, `permissions`, `verified`, `email_verified`
- [ ] Rate limiting (X requests/min from same IP)
- [ ] CAPTCHA on registration
- [ ] Tymporarne email blocked (mailinator)
- [ ] Password policy enforcement (min length, breached check)
- [ ] Username enumeration ("already taken" message)
- [ ] Timing attack na rejestracji
- [ ] Injection testing każde pole
- [ ] Unicode confusables w username
- [ ] Verification email contains: token only (nie full account state)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Proces rejestracji — bezpieczeństwo

- **Weryfikacja email**: wymagaj potwierdzenia adresu email przed aktywacją konta
- Token weryfikacyjny: CSPRNG, jednorazowy, krótki TTL (24h max), hashowany w DB
- **CAPTCHA/rate limiting**: zapobiegaj masowemu tworzeniu kont (bot registration)
- Blokuj tymczasowe adresy email (mailinator, guerrillamail) jeśli to wymagane biznesowo
- Ogranicz ilość rejestracji z jednego IP/sesji

### Walidacja danych rejestracyjnych

- **Username**: case-insensitive, unikalne, allowlist znaków, min/max długość
- **Email**: waliduj format, sprawdź duplikaty (case-insensitive), zweryfikuj MX record
- **Hasło**: min. 8 znaków (z MFA) lub 15 (bez MFA), max 64+, brak ograniczeń na typ znaków
- Sprawdzaj hasło na liście skompromitowanych (HaveIBeenPwned, SecLists)
- **Nie ujawniaj** czy email/username już istnieje — generyczne komunikaty

### Mass Assignment / Privilege Escalation

- NIE akceptuj pól `role`, `isAdmin`, `is_staff`, `permissions` z danych użytkownika
- Użyj allowlist pól akceptowanych przy rejestracji (strong parameters)
- Testuj: dodaj `"role":"admin"`, `"isAdmin":true` do request body
- Sprawdź czy ukryte pola formularza mogą być manipulowane

### Enumeracja użytkowników przez rejestrację

- Komunikat "Username already taken" ujawnia istniejących użytkowników
- Użyj **generycznych komunikatów**: "Jeśli email jest dostępny, zostanie wysłany link weryfikacyjny"
- **Timing attack**: porównaj czas odpowiedzi przy istniejącym vs nowym username
- Testuj enumerację na: rejestracji, logowaniu, forgot password — WSZYSTKIE muszą być spójne

### Injection w polach rejestracji

- Testuj SQLi, XSS, SSTI w polach: username, email, imię, nazwisko
- Sprawdź czy dane są sanityzowane i walidowane server-side
- Testuj Unicode confusables: `Аdmin` (cyrylica A) vs `Admin` (łacińskie A)
- Null bytes, białe znaki na początku/końcu, podwójne spacje

## Pentesterskie deep dive

### Mniej znane techniki

- **Email verification bypass via timing**: aplikacja często wysyła verify email asynchronicznie - atakujący może wykorzystać window before email sent (race condition).
- **Email confirmation token reuse**: niektóre aplikacje pozwalają na reuse tokenu - registered → revoke → re-register z tym samym tokenem.
- **Username homograph attack**: rejestracja `аdmin` (cyrylica а U+0430) - vizualnie identyczna z `admin` ale unique w DB → phishing pivot.
- **Email aliasing exploitation**: `user+alias@gmail.com` aliases do `user@gmail.com` w Gmail. Aplikacja może traktować jako różne accounts → bypass verification.
- **Mass assignment via different parsers**: aplikacja waliduje JSON ale akceptuje też form-encoded, gdzie strict parameter binding nie istnieje.
- **Race condition na "first admin"**: niektóre aplikacje mają special "first registration = admin" logic. Race między dwoma simultaneous registrations może skończyć z dwoma admins.

### Common pitfalls

- **Email verification w GET endpoint**: `/verify?token=X` activates account. Atakujący włącza link w `<img src>` na stronie z XSS - automatic account activation.
- **OAuth registration bez email verification**: jeśli OAuth provider zwraca `email_verified: false`, aplikacja często ignoruje i tworzy active account.

### Świeżynki z research

- **HaveIBeenPwned API**: https://haveibeenpwned.com/API/v3 - integration dla password breach check
- **Sam Curry registration research**: account takeover via OAuth bypass
- **PortSwigger Authentication Lab**: https://portswigger.net/web-security/authentication

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Param Miner | Hidden parameter discovery (mass assignment) | [GitHub](https://github.com/PortSwigger/param-miner) |
| Turbo Intruder | Race condition testing | [GitHub](https://github.com/PortSwigger/turbo-intruder) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/03-Identity_Management_Testing/02-Test_User_Registration_Process
- OWASP Authentication CS: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- HaveIBeenPwned API: https://haveibeenpwned.com/API/v3
- PortSwigger Authentication: https://portswigger.net/web-security/authentication

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.1.1 | Password Security (L1) | Minimum 12 character password. |
| V2.1.7 | Password Security (L1) | Check breached password lists. |
| V5.1.4 | Input Validation (L1) | Mass assignment protection. |
| V6.1.1 | Communication (L1) | Password and authentication requests via TLS. |
