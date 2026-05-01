# WSTG-BUSL-03 — Test Integrity Checks

## Cel

Audyt integrity checks: HMAC validation per cena/ID/order, JWT signature, ViewState MAC validation, server-side price recalculation, idempotency keys.

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify signed parameters**: HMAC, JWT, encrypted blobs w request body.
2. **Tampering test**: zmień value, zostaw signature → akceptowane?
3. **Constant-time comparison**: timing diff dla różnych signatures (Burp Repeater + monitor latency).
4. **JWT test**: alg=none, signature change.
5. **Server-side validation**: czy serwer recalculates prices niezależnie od client value?

### Co MUSI być sprawdzone (8 punktów)

- [ ] HMAC sygnatura validated server-side
- [ ] HMAC constant-time comparison (timing attack defense)
- [ ] JWT signature validated (cross WSTG-SESS-10)
- [ ] ViewState MAC validation (ASP.NET)
- [ ] Server-side price recalculation
- [ ] Replay protection (nonce/timestamp)
- [ ] Idempotency keys
- [ ] Order_id integrity (cannot be tampered)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cryptographic_Storage_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Kontrola integralności — mechanizmy

- **HMAC** (Hash-based Message Authentication Code): podpis danych kluczem serwera
- **Podpisy cyfrowe**: RSA/ECDSA — silniejsze niż HMAC, asymetryczne
- **Checksums**: SHA-256 hash danych — wykrywa modyfikacje (ale nie chroni bez klucza)
- **JWT z podpisem**: RS256/ES256 — integralność payload potwierdzona podpisem

### Co chronić integralnością

- **Ceny i kwoty**: serwer musi przeliczać ceny — nie ufać wartościom od klienta
- **Dane sesji**: ViewState (ASP.NET), cookie-based sessions — muszą być podpisane
- **Tokeny**: JWT, reset tokens, invite tokens — podpisane i weryfikowane
- **Parametry workflow**: step number, status, verified flags — server-side state machine
- **Pliki**: checksumy przy upload/download — weryfikuj integralność

### Typowe ataki na integralność

- **Modyfikacja ceny w tranzycie**: zmień `amount: 100` na `amount: 0.01` w Burp
- **JWT manipulation**: zmień payload (role: admin) bez znajomości klucza (alg:none attack)
- **ViewState tampering**: jeśli MAC validation wyłączony — modyfikuj dane
- **Replay attack**: ponowne wysłanie prawidłowego requestu (np. podwójna płatność)
- **Hash collision**: dla MD5/SHA-1 - znajdź 2 inputs z tym samym hash

### Defense

- **HMAC** z silnym secret (≥256 bit entropy)
- **Constant-time comparison**: `hmac.compare_digest()` (Python), `MessageDigest.isEqual()` (Java)
- **Strong hash algorithm**: SHA-256+, NIE MD5/SHA-1
- **Server-side state**: nie ufaj danym z client cookies/JWT for state

## Pentesterskie deep dive

### Mniej znane techniki

- **Length extension attack**: jeśli aplikacja używa `MD5(secret + data)` zamiast HMAC → atakujący extends data without knowing secret.
- **Hash collision**: MD5 collisions możliwe (Flame malware exploited this).
- **Timing attack na HMAC compare**: jeśli `==` zamiast constant-time, atakujący leaks expected HMAC byte-by-byte.

### Common pitfalls

- **HMAC validated ale nie integralność wszystkich pól**: tylko part of body covered.
- **Stale signature ważne forever**: brak timestamp w signature payload.

### Świeżynki z research

- **PortSwigger Insecure Deserialization Lab**: https://portswigger.net/web-security/deserialization
- **HackTricks Length Extension**: https://book.hacktricks.xyz/cryptography/hash-length-extension-attack

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Hackvertor | HMAC manipulation |
| HashID | Hash type identification |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/03-Test_Integrity_Checks
- OWASP Cryptographic Storage CS: https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V6.4.1 | Integrity protection on critical operations. |
| V6.2.5 | Authenticated encryption (GCM). |
