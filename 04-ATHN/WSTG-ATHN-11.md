# WSTG-ATHN-11 — Testing Multi-Factor Authentication (MFA)

## Cel

Audyt MFA: enrollment process, MFA challenge bypass (skip step), backup codes, rate limiting na OTP, recovery flow, czy MFA wymagana na wszystkich kanałach (cross WSTG-ATHN-10), czy SMS-based MFA (słabsze) vs TOTP/WebAuthn.

> **Test mostly manual**: wymaga zaenrollowanego konta MFA + analizy challenge flow.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Enrollment audit**: czy MFA enrollment wymaga current password? Czy pozwala na slabe factors (SMS/email tylko)?
2. **MFA bypass attempts**: skip MFA step (direct call to post-MFA endpoint), session token replay, response manipulation.
3. **Brute-force OTP**: rate limit na OTP entry endpoint? Bez limit = 6-digit OTP brute-forceable in 10s.
4. **Backup codes**: jednorazowe? Krótki TTL? Stored hashed?
5. **Recovery flow**: czy bypass MFA via "I lost my device" flow daje atakującemu pełny dostęp?
6. **Per channel**: cross WSTG-ATHN-10 - mobile/API/SSO też wymagają MFA?

### Co MUSI być sprawdzone (15 punktów)

- [ ] MFA wymagana na login (po username/password)
- [ ] MFA wymagana przy zmianie hasła
- [ ] MFA wymagana przy zmianie email/MFA settings
- [ ] MFA enrollment wymaga current password
- [ ] OTP rate limiting (max 5 attempts)
- [ ] OTP TTL (30s standard TOTP, 5 min email)
- [ ] OTP nie reflectowane w response
- [ ] Backup codes: jednorazowe, hashed
- [ ] Recovery flow not bypass-able
- [ ] WebAuthn/FIDO2 preferred
- [ ] SMS only nie jest mandatory MFA (ze względu na SIM swap)
- [ ] Per channel consistency (cross WSTG-ATHN-10)
- [ ] Push notification anti-fatigue (limit pushes per minute)
- [ ] Number matching dla push (Microsoft style)
- [ ] MFA settings change wymagają re-auth

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Multifactor_Authentication_Cheat_Sheet.md

### Hierarchia czynników MFA (od najsilniejszego)

| Czynnik | Typ | Phishing-resistant? | Uwagi |
|---------|-----|---------------------|-------|
| FIDO2/WebAuthn/Passkeys | Something You Have + Are/Know | **TAK** | Najlepsza opcja — kryptograficzne wiązanie z domeną |
| Hardware OTP (YubiKey) | Something You Have | Nie (ale krótki czas życia) | Drogie, ale bardzo bezpieczne |
| Software TOTP | Something You Have | Nie | Dobre — Google Authenticator, Authy |
| Push notification | Something You Have | Nie | Ryzyko "push fatigue" — atakujący spamuje powiadomieniami |
| SMS/telefon | Something You Have | Nie | **SŁABE** — SIM swap, SS7, przechwytywanie |
| Email | Something You Have/Know | Nie | **Najsłabsze** — często to samo hasło |
| Pytania bezpieczeństwa | Something You Know | Nie | **NIST odradza** — nie stanowi MFA z hasłem |

### Kiedy wymagać MFA

- **Logowanie** — główny punkt wymagania MFA
- **Zmiana hasła** lub adresu email
- **Wyłączanie MFA** — wymaga re-autentykacji istniejącym czynnikiem
- **Operacje wrażliwe**: transakcje finansowe, eksport danych, zmiana uprawnień
- **Eskalacja sesji**: przejście z user → admin
- **Wszystkie kanały**: webowe UI, API, mobile app — każdy musi wymagać MFA

### MFA bypass — typowe wektory

- **Skip MFA step**: aplikacja generuje session token PRZED MFA challenge → atakujący direct call do post-MFA endpoints
- **Response manipulation**: zamień `{"mfa_required": true}` na `{"mfa_required": false}` w response
- **OTP brute-force**: 6-digit OTP = 1M kombinacji, bez rate limit = brute force in seconds
- **Session token replay**: pre-MFA session token nadal valid post-MFA
- **Backup codes reuse**: aplikacja nie invaliduje backup code po użyciu
- **Recovery flow**: "I lost my device" → email link bez MFA = bypass

### Push fatigue / MFA spam

- Atakujący wysyła wiele push notifications oczekując że user zatwierdzi (irritation)
- **Obrona**: number matching (Microsoft style) — user musi wpisać 2-digit code z screen
- Rate limit: max 1-2 pushes per minute

## Pentesterskie deep dive

### Mniej znane techniki

- **MFA bypass via session token replay**: pre-MFA session ID == post-MFA session ID → atakujący dostaje token przed MFA, używa po MFA bypass.
- **OTP via response manipulation**: modify `{"mfa_required": true}` to `false` in response → frontend skips MFA challenge.
- **TOTP secret leak via QR code**: enrollment QR code logged in proxy → atakujący zna secret → może wygenerować dowolny OTP.
- **SIM swap attack**: SMS OTP → atakujący port number → otrzymuje OTP. Banking SMS często vulnerable.
- **WebAuthn challenge replay**: niektóre weak implementations re-use challenge → replay attack.
- **Push fatigue (MFA bombing)**: notification spam, eventually user clicks "Approve" by mistake.

### Common pitfalls

- **MFA opcjonalna**: "We support MFA" ale nie wymagana → most users bez MFA = credential stuffing wciąż działa.
- **MFA tylko na web, nie na API**: mobile app token bypass MFA na web (cross WSTG-ATHN-10).
- **Backup codes "for convenience"**: 10 backup codes ważnych forever → secrets equivalent of permanent password.

### Świeżynki z research

- **MFA Bombing research (Microsoft)**: https://www.microsoft.com/en-us/security/blog/2022/09/22/mfa-fatigue/
- **Sam Curry MFA bypass research**: https://samcurry.net/
- **PortSwigger MFA labs**: https://portswigger.net/web-security/authentication
- **HackTricks 2FA Bypass**: https://book.hacktricks.xyz/pentesting-web/2fa-bypass

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Turbo Intruder | High-performance OTP brute-force testing |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/11-Testing_Multi-Factor_Authentication
- OWASP MFA CS: https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- HackTricks 2FA Bypass: https://book.hacktricks.xyz/pentesting-web/2fa-bypass
- PortSwigger Authentication: https://portswigger.net/web-security/authentication

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V2.7.1 | Multi-factor authentication for sensitive operations. |
| V2.8.1 | TOTP/HOTP implementation per RFC 6238. |
| V2.9.1 | Hardware-based factor support (FIDO2). |
