# WSTG-ATHN-07 — Testing for Weak Authentication Methods

## Cel

Audyt password policy i authentication strength: minimum długość, allowed chars (passphrases), max długość, blokowanie znanych breach passwords (HaveIBeenPwned), enforced password change after compromise.

> **Test mostly manual**: rejestracja test account z różnymi hasłami → analiza akceptacji.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Min length test**: rejestracja z 1-char password → akceptowane?
2. **Max length test**: 1000-char password → akceptowane (NIST: minimum 64)?
3. **Character classes**: passphrase z spacjami i Unicode → akceptowane (NIST permits all)?
4. **Breach check**: rejestracja z `password123` (in HIBP) → blokowane?
5. **Forced rotation**: czy aplikacja wymusza okresową zmianę (NIST odradza chyba że compromised)?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Min length: 8 (z MFA) lub 15 (bez)
- [ ] Max length: minimum 64 chars
- [ ] Pozwoli na passphrases (spaces, special chars, Unicode)
- [ ] Brak max length truncation bez user notice
- [ ] HaveIBeenPwned API check (breached passwords blocked)
- [ ] Top-N common passwords blocked
- [ ] Password ≠ username/email
- [ ] Brak forced rotation (chyba że breach detected)
- [ ] Password strength meter na rejestracji
- [ ] Bcrypt/Argon2id storage (cross WSTG-CRYP-04)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Password_Storage_Cheat_Sheet.md

### Polityka siły hasła (NIST SP800-63B)

- **Minimalna długość**: 8 znaków z MFA, 15 znaków bez MFA
- **Maksymalna długość**: minimum **64 znaki** — pozwól na passphrases
- **Nie obcinaj hasła cicho** (silent truncation) — użytkownik musi wiedzieć o limitach
- Pozwól na **WSZYSTKIE znaki** włącznie z Unicode i spacjami — brak reguł kompozycji (duże/małe/cyfry/specjalne)
- NIST **ODRADZA** wymuszanie okresowej zmiany haseł — zmiana TYLKO po wycieku
- Włącz **password strength meter** (np. zxcvbn-ts) — pomaga użytkownikowi stworzyć silne hasło

### Blokowanie słabych haseł

- Sprawdzaj hasła przeciw **bazom wycieknietych haseł**: [HaveIBeenPwned Passwords API](https://haveibeenpwned.com/API/v3#PwnedPasswords)
- Blokuj **top-N najpopularniejszych haseł** — listy dostępne w SecLists
- Blokuj hasła identyczne z username, email, nazwą aplikacji

### Przechowywanie haseł — algorytmy hashowania

- **Argon2id** (REKOMENDOWANY): min 19 MiB pamięci, 2 iteracje, 1 stopień równoległości
- **scrypt**: min CPU/memory cost 2^17, block size 8 (1024 bytes), parallelization 1
- **bcrypt**: work factor 10+, limit hasła 72 bajty
- **PBKDF2** (jeśli FIPS-140 wymagany): work factor 600000+, HMAC-SHA-256
- **NIGDY**: MD5, SHA-1 (do haseł), SHA-256 bez salt+cost

### Zmiana hasła

- Wymagaj podania **bieżącego hasła** przy zmianie — chroni przed account takeover (XSS, CSRF)
- Po zmianie: wyloguj wszystkie inne sesje, unieważnij remember-me tokens
- Powiadom email — informuj użytkownika o zmianie hasła (alerting)

## Pentesterskie deep dive

### Mniej znane techniki

- **Password truncation**: bcrypt limit 72 bytes - długie passphrases truncated. User myśli że ma 100-char password, faktycznie 72.
- **Unicode normalization mismatch**: registration NFC vs login NFD → password check fails dla legitymnego usera.
- **Password as-is in URL** (forgot password reset): `?password=newpwd` w URL - logged everywhere.
- **Password complexity = anti-pattern**: forced "1 uppercase + 1 number + 1 special" prowadzi do `Password1!` patterns.

### Common pitfalls

- **Password length max=20**: niektóre legacy aplikacje truncate po 20 chars - bypass.
- **Password ≠ username check tylko exact match**: `admin` vs `Admin1` not caught.

### Świeżynki z research

- **NIST SP 800-63B**: https://pages.nist.gov/800-63-3/sp800-63b.html
- **HaveIBeenPwned API**: https://haveibeenpwned.com/API/v3
- **zxcvbn (password strength)**: https://github.com/dropbox/zxcvbn

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Param Miner | Hidden password param discovery |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/07-Testing_for_Weak_Authentication_Methods
- OWASP Authentication CS: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP Password Storage CS: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- NIST SP 800-63B: https://pages.nist.gov/800-63-3/sp800-63b.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V2.1.1 | Min 12 chars password. |
| V2.1.5 | Allow passphrases (no composition rules). |
| V2.1.7 | Check breached password lists. |
| V2.4.1 | Argon2/bcrypt/scrypt/PBKDF2 storage. |
