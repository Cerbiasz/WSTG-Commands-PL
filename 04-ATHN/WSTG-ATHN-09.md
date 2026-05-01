# WSTG-ATHN-09 — Testing for Weak Password Change or Reset Functionalities

## Cel

Audyt password change (authenticated) i password reset (forgot password): czy reset wymaga aktualnego hasła, token reset jest CSPRNG random + jednorazowy + krótki TTL, czy odpowiedź forgot-password ujawnia istnienie konta, czy Host Header injection możliwy w reset link.

> **Test mostly manual**: wymaga interakcji z reset flow.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Password change**: czy wymagane current password? (defense vs XSS/CSRF takeover).
2. **Forgot password response**: czy generic ("Reset link sent if account exists")?
3. **Reset token analysis**: random, jednorazowy, TTL <= 1h?
4. **Host Header injection**: zmień Host w forgot-password request → czy reset link w email zawiera attacker hostname?
5. **Token reuse**: użyj same token 2 razy → czy działa?

### Co MUSI być sprawdzone (12 punktów)

- [ ] Password change wymaga current password
- [ ] Reset request response generic (no enumeration)
- [ ] Reset request response time consistent (no timing leak)
- [ ] Reset token: CSPRNG, ≥128 bits entropy
- [ ] Reset token jednorazowy
- [ ] Reset token TTL: 15-60 min
- [ ] Reset token hashed w DB (jak hasło)
- [ ] Reset link sent przez email (nie w response)
- [ ] Host Header injection blocked
- [ ] Po reset: invalidate all sessions
- [ ] Po reset: invalidate remember-me tokens
- [ ] Email notification po password change

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Forgot_Password_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Forgot Password — bezpieczny flow

1. Użytkownik podaje email/username
2. Serwer zwraca **identyczny komunikat** niezależnie czy konto istnieje ("If an account exists, a reset link has been sent")
3. **Identyczny czas odpowiedzi** — nie ujawniaj istnienia konta przez timing
4. Token wysyłany emailem/SMS (side-channel) — NIGDY w odpowiedzi HTTP
5. Użytkownik klika link z tokenem → formularz zmiany hasła
6. Po zmianie: redirect na login (NIE automatyczny login) + powiadomienie email

### Tokeny resetowania — wymagania bezpieczeństwa

- Generowane przez **CSPRNG** (SecureRandom, secrets, crypto.randomBytes) — min 128 bit entropii
- **Jednorazowe** — unieważnione po użyciu
- **Krótki czas ważności**: 15-60 minut
- **Powiązane z konkretnym użytkownikiem** w bazie danych
- **Hashowane w bazie** (SHA-256) — nie przechowuj raw token (jak hasła)
- **Rate limiting** na endpoincie — zapobiegaj flood tokenami (email/SMS spam)

### Host Header Injection

- NIE używaj `Host` header do budowania URL resetowania — atakujący może podmienić
- Atakujący wysyła forgot-password z `Host: evil.com` → email zawiera link `https://evil.com/reset?token=xxx`
- Użytkownik klika → token wysyłany do atakującego
- **Obrona**: hardcode domain w aplikacji, walidacja Host header przeciw allowlist

### Po resetowaniu hasła

- **Unieważnij wszystkie sesje** użytkownika — atakujący mógł mieć aktywne sesje
- **Unieważnij remember-me tokens**
- **Powiadom email** — informuj o zmianie hasła
- **Wymagaj re-autentykacji MFA** jeśli ustawione

### Zmiana hasła (authenticated)

- Wymagaj podania **bieżącego hasła** — chroni przed XSS/CSRF takeover
- Po zmianie: opcjonalnie wyloguj inne sesje
- Powiadom email

## Pentesterskie deep dive

### Mniej znane techniki

- **Host Header Injection**: aplikacja używa `Host` header do generation reset link → atakujący wysyła `Host: evil.com` → email contains attacker URL.
- **Reset token w referrer**: jeśli reset page ma external link (np. CDN tracking), token może wyciec w Referer header.
- **Race condition na reset**: send 2 simultaneous reset requests → 2 valid tokens, jeden w 30 min later.
- **OAuth reset bypass**: aplikacja allows password reset via OAuth provider link without confirming current password = full takeover via stolen OAuth token.
- **Reset token w URL → browser history → shared device**: token persistent w history.

### Common pitfalls

- **Email "Click here to reset your password" - link nie expires**: token without TTL.
- **Reset token reuse**: aplikacja nie invaliduje token po success → atakujący może replay.
- **Forgot password ujawnia istnienie konta przez timing**: 200ms vs 50ms diff.

### Świeżynki z research

- **PortSwigger Forgot Password Lab**: https://portswigger.net/web-security/authentication
- **OWASP Forgot Password CS**: https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
- **Sam Curry Account Takeover research**: https://samcurry.net/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Param Miner | Hidden parameter discovery |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/09-Testing_for_Weak_Password_Change_or_Reset_Functionalities
- OWASP Forgot Password CS: https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html
- HackTricks Account Takeover: https://book.hacktricks.xyz/pentesting-web/account-takeover

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V2.5.1 | Initial password generation. |
| V2.5.6 | Password reset tokens have lifetime. |
| V2.5.7 | One-time password reset tokens. |
| V3.3.1 | Logout invalidates session. |
