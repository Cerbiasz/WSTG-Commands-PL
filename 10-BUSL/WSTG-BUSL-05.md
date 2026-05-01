# WSTG-BUSL-05 — Test Number of Times a Function Can Be Used Limits

## Cel

Audyt limitów użycia funkcji: kupony jednorazowe, free trial limits, voting limits, password reset limits. Bypass via case manipulation, encoding, multiple sessions/accounts, IP rotation.

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify single-use features**: coupons, vouchers, free trials, vote, sample download.
2. **Reuse test**: użyj raz → próbuj użyć ponownie → blocked?
3. **Bypass techniques**: case manipulation, encoding, whitespace, Unicode.
4. **Multi-session bypass**: użyj coupon na sesji A, sesji B (cookie clear).
5. **Multi-account bypass**: user A i user B - coupon sharing?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Coupon reuse same session
- [ ] Coupon reuse different session
- [ ] Coupon reuse different account
- [ ] Case manipulation (`COUPON50` vs `coupon50`)
- [ ] Whitespace tricks (` COUPON50`, `COUPON50 `)
- [ ] Unicode confusables (cyrylica `С`)
- [ ] URL encoding `%43OUPON50`
- [ ] IP rotation (X-Forwarded-For)
- [ ] Race condition on redemption (cross WSTG-BUSL-04)
- [ ] Email aliases (`user+1@gmail.com`, `user+2@gmail.com`)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Limity użycia — co ograniczać

- **Kupony/rabaty**: jednorazowe — per użytkownik, per konto, per sesję
- **Darmowe próby**: trial period, free downloads — limit per konto/IP/urządzenie
- **Głosowania**: jedna osoba = jeden głos — weryfikacja tożsamości
- **Reset hasła**: max. X requestów na godzinę — zapobiegaj email bombing
- **Logowanie**: lockout po N błędnych próbach
- **API calls**: rate limiting per API key/user/IP

### Techniki obejścia limitów — co testować

| Technika | Opis |
|----------|------|
| Case manipulation | `COUPON50` vs `coupon50` vs `Coupon50` |
| Spacje | `" COUPON50"`, `"COUPON50 "`, `"COUPON 50"` |
| Encoding | `%43OUPON50` (URL encoded C) |
| Różne sesje | Użyj kuponu z sesji A, potem z sesji B |
| Różne konta | Użyj kuponu na koncie A, potem na koncie B |
| IP spoofing | `X-Forwarded-For: 1.1.1.1` — obejście IP-based limitów |
| Race condition | Wiele requestów jednocześnie — limit nie zdąży zadziałać |
| Unicode confusables | `СOUPON50` (cyrylica C) vs `COUPON50` (łacińskie C) |

### Obrona

- **Normalizacja inputu**: trim, lowercase, NFC Unicode normalization PRZED comparison
- **Server-side state**: redemption_count w DB, atomic operation
- **Multiple identifiers**: limit per user_id + email + IP (defense in depth)
- **Rate limiting layers**: per IP + per user + globalnie
- **CAPTCHA na wrażliwych operacjach**: po N próbach

## Pentesterskie deep dive

### Mniej znane techniki

- **OAuth multi-account abuse**: jeden numer telefonu, dwa OAuth providers (Google + Facebook) → 2 konta z tym samym phone number.
- **Mobile app vs web limit różny**: mobile API może mieć inny limit lub żadnego.
- **Trial reset via account deletion**: usuń account → zarejestruj ponownie → nowy trial.

### Common pitfalls

- **Limit IP-based ale za CDN**: wszystkie requesty z tego samego CDN IP - false positive.
- **Limit per email exact match**: `user@gmail.com` ≠ `User@Gmail.com` w DB.

### Świeżynki z research

- **PortSwigger Business Logic labs**: https://portswigger.net/web-security/logic-flaws
- **HackerOne disclosed coupons abuse**: https://hackerone.com/hacktivity

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Hackvertor | Encoding manipulation |
| Turbo Intruder | Race + bypass testing |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/05-Test_Number_of_Times_a_Function_Can_Be_Used_Limits
- OWASP Abuse Case CS: https://cheatsheetseries.owasp.org/cheatsheets/Abuse_Case_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V11.1.4 | Anti-automation controls. |
| V2.2.2 | Defense against credential stuffing. |
