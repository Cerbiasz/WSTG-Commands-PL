# WSTG-ATHN-03 — Testing for Weak Lock Out Mechanism

## Cel

Weryfikacja czy aplikacja blokuje konto po N nieudanych próbach logowania. Brak lockout = unlimited brute-force / credential stuffing. Też: czy lockout można obejść (password spraying), czy lockout sam jest DoS vector.

> **Test manual**: wymaga próbnych logowań - automatyzacja w Burp Intruder lub hydra.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Lockout test**: 10+ failed logins na test account → czy konto blocked?
2. **Lockout duration**: jeśli blocked, ile trwa? (15-30 min ideal, permanent = DoS risk).
3. **Password spraying bypass**: 1 password × 100 accounts → czy każde konto ma osobny lockout (immune to spraying)?
4. **Account enumeration via lockout**: locked account może mieć inny error → enumeration.
5. **CAPTCHA enforcement**: po N błędach → CAPTCHA pojawia się?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Account locks after 5-10 failed attempts
- [ ] Lockout duration 15-30 min auto-unlock
- [ ] CAPTCHA after N attempts
- [ ] Progressive delays (1s, 2s, 4s, 8s)
- [ ] Per-IP rate limiting (defense vs spraying)
- [ ] Password spraying tested (1 pass × N accounts)
- [ ] Lockout bypass via header tampering (X-Forwarded-For)
- [ ] Locked account error doesn't enumerate

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Credential_Stuffing_Prevention_Cheat_Sheet.md

### Mechanizmy obrony przed brute force

- **Account lockout**: zablokuj konto po 5-10 nieudanych próbach
  - Automatyczne odblokowanie po 15-30 minutach (NIE permanentne — DoS risk)
  - UWAGA: atakujący może celowo blokować konta użytkowników (lock-out attack)
- **Progresywne opóźnienia (throttling)**: 1s, 2s, 4s, 8s, 16s po kolejnych błędach
  - Mniej agresywne niż lockout — nie blokuje konta, ale spowalnia brute force
- **CAPTCHA**: po N nieudanych próbach (np. 3) — reCAPTCHA v3, hCaptcha
  - NIE na pierwszej próbie — irytuje legalnych użytkowników
- **Rate limiting IP**: ogranicz liczbę prób z jednego IP per minute
  - UWAGA: proxy/VPN/NAT — wiele użytkowników może mieć ten sam IP

### Password spraying — obejście lockout

- Atakujący próbuje JEDNO hasło na WIELU kontach (zamiast wielu haseł na jednym koncie)
- Omija account lockout (1 próba per konto)
- **Obrona**: globalne rate limiting, CAPTCHA, wykrywanie wzorców (wiele kont z jednego IP)
- Blokuj popularne hasła (Password1!, Qwerty123) — atakujący próbuje właśnie tych

### Komunikaty błędów

- **Identyczny komunikat** dla locked account vs wrong password — nie ujawniaj statusu blokady
- "Invalid username or password" - generic dla wszystkich przypadków

## Pentesterskie deep dive

### Mniej znane techniki

- **Lockout bypass via X-Forwarded-For rotation**: niektóre aplikacje rate-limit per X-Forwarded-For header → atakujący rotuje IP w header → unlimited attempts.
- **Account enumeration via lockout response time**: locked account może odpowiadać szybciej (no password check) → timing leak.
- **Distributed brute-force**: botnet z 1000 IPs po 1 attempt each = bypass per-IP rate limiting bez lockout.
- **Lockout DoS**: atakujący lockuje znanych userów (np. exec emails z LinkedIn) → permanent DoS bez auto-unlock.

### Common pitfalls

- **Lockout per IP only, nie per account**: password spraying wciąż działa.
- **Permanent lockout w prod**: legitymny user nie może się zalogować po 5 typo → support ticket spam.

### Świeżynki z research

- **PortSwigger Authentication labs**: https://portswigger.net/web-security/authentication
- **HackTricks Brute Force**: https://book.hacktricks.xyz/generic-methodologies-and-resources/brute-force

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Turbo Intruder | High-performance brute force testing |
| IP Rotate | Rotate IP via AWS Gateway |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/03-Testing_for_Weak_Lock_Out_Mechanism
- OWASP Authentication CS: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP Credential Stuffing CS: https://cheatsheetseries.owasp.org/cheatsheets/Credential_Stuffing_Prevention_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V2.2.1 | Anti-automation defense (lockout, CAPTCHA, rate limit). |
| V2.2.2 | Defense against credential stuffing. |
