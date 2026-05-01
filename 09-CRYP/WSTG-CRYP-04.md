# WSTG-CRYP-04 — Testing for Weak Encryption

## Cel

Weryfikacja że aplikacja używa nowoczesnej kryptografii: AES-128/256 GCM (lub ChaCha20-Poly1305) dla symmetric, ECC Curve25519/RSA 2048+ z OAEP dla asymmetric, Argon2id/bcrypt dla password hashing, brak MD5/SHA-1/DES/RC4/ECB.

> **Test manual / code review**: weak encryption wymaga analizy implementacji (source code, decompiled binaries, libraries used). Nuclei nie ma direct testu — niektóre wskaźniki HTTP-side (np. cookie format, JWT alg).

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Identify crypto in HTTP traffic**: ciphertext patterns w cookies/params (base64 length 16/32/64 bytes hint AES/SHA), JWT tokens (header `alg`).
2. **JWT analysis**: JWT `alg` header — `none`, `HS256` z public key, `RS256` ale weak key. Burp JWT Editor.
3. **Library version check**: cross WSTG-INFO-09 — niektóre wersje libraries (OpenSSL, BouncyCastle) miały CVE w crypto.
4. **Test code paths z input**: jeśli aplikacja przyjmuje encrypted data od użytkownika → test podatności jak padding oracle (CRYP-02).
5. **Source code review**: jeśli dostępny, grep `MD5`, `SHA1`, `DES`, `RC4`, `ECB`, `Math.random`, `rand()`.
6. **Crypto behavior tests**: identyczne plaintext daje identyczne ciphertext = ECB lub no IV. Test przez 2 identyczne registrations / 2 password resets.

### Co MUSI być sprawdzone (12 punktów)

- [ ] JWT alg header (nie `none`, nie `HS256` z guessable secret)
- [ ] Hashed passwords (jeśli dostępne via SQL injection / DB leak): bcrypt/argon2 vs MD5/SHA-1
- [ ] Encrypted cookies length divisible by 16 (AES) — test za pomocą bit flipping
- [ ] CSRF tokens — random per session vs predictable
- [ ] Reset password tokens — UUID v4 (random) vs UUID v1 (timestamp-based)
- [ ] Session tokens — sufficiently long (>= 128 bits entropy)
- [ ] OAuth state parameter — random per request
- [ ] Captcha solutions — server-side validated, not client-side
- [ ] Library versions (cross WSTG-INFO-09) — outdated libs z crypto CVE
- [ ] Random number generation — secrets/SecureRandom vs Math.random
- [ ] ECB pattern test (identical plaintext → identical ciphertext)
- [ ] Custom crypto algorithm (red flag - never roll your own)

### Per scenario — typowe wskaźniki

| Wskaźnik | Algorytm | Ryzyko |
|---|---|---|
| `eyJhbGciOiJub25lIn0...` | JWT `alg: none` | Token forgery (krytyczne) |
| `eyJhbGciOiJIUzI1NiIs...` | JWT HS256 | Brute-force secret jeśli simple |
| `0d4c4...` 32 hex chars | MD5 hash | Rainbow table attack na passwords |
| `a94a8...` 40 hex chars | SHA-1 | Collision attacks (deprecated) |
| `$2y$10$...` | bcrypt | Bezpieczne (jeśli cost ≥ 10) |
| `$argon2id$v=19$m=...` | Argon2id | Bezpieczne (gold standard) |
| `pbkdf2_sha256$...` | PBKDF2 | OK (jeśli iterations ≥ 100k) |
| Identical plaintext → identical ciphertext | ECB | Patterns visible (zła) |
| UUID v1 (`...:1ee:...`) | timestamp-based | Predictable |
| UUID v4 (`...:4...`) | random | OK if CSPRNG |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cryptographic_Storage_Cheat_Sheet.md, Key_Management_Cheat_Sheet.md

### Algorytmy — co używać, czego unikać

- **Szyfrowanie symetryczne**: AES-128 minimum, AES-256 preferowany, tryb **GCM** (authenticated encryption)
- **Szyfrowanie asymetryczne**: ECC Curve25519 (preferowany) lub RSA >= 2048 bit
- **Hashowanie haseł**: Argon2id (rekomendowany), bcrypt (cost >= 10), scrypt, PBKDF2 (FIPS)
- **Hashowanie integralności**: SHA-256+, SHA-3
- **NIGDY nie używaj**: MD5, SHA-1 (do haseł), DES, 3DES, RC4, Blowfish, ECB mode
- **NIGDY**: custom/własne algorytmy kryptograficzne

### Tryby szyfrowania blokowego

- **GCM** (REKOMENDOWANY) — authenticated encryption, zapewnia poufność + integralność
- **CCM** — alternatywa dla GCM
- **CTR/CBC** — jeśli GCM niedostępny, ALE wymagają osobnego MAC (Encrypt-then-MAC)
- **ECB** — NIGDY (ten sam plaintext → ten sam ciphertext, wzorce widoczne)

### Secure Random Number Generation (CSPRNG)

- Java: `SecureRandom` | Python: `secrets` | PHP: `random_bytes()` | Node: `crypto.randomBytes()`
- .NET: `RandomNumberGenerator` | Go: `crypto/rand` | C: `getrandom(2)` | Ruby: `SecureRandom`
- **NIGDY**: `Math.random()`, `rand()`, `random()`, `mt_rand()` — przewidywalne

### Zarządzanie kluczami

- **Separacja kluczy od danych**: klucze na filesystem, dane w DB (lub odwrotnie)
- **Envelope encryption**: Data Encryption Key (DEK) szyfrowany Key Encryption Key (KEK)
- **Przechowywanie kluczy**: HSM, AWS KMS, Azure Key Vault, HashiCorp Vault, GCP Cloud KMS
- **NIE**: hardkoduj w kodzie, NIE commituj do VCS, NIE w env vars (ryzyko phpinfo/proc/environ)
- **Rotacja kluczy**: po kompromitacji, po upływie cryptoperiod, po zaszyfrowaniu dużej ilości danych

### RSA — bezpieczne użycie

- **OAEP padding** (Optimal Asymmetric Encryption Padding) — ZAWSZE
- NIGDY: PKCS#1 v1.5 padding — podatny na Bleichenbacher attack

### UUID/GUID a bezpieczeństwo

- UUID v4 — losowe, bezpieczne jeśli generowane przez CSPRNG
- UUID v1 — oparte na timestamp + MAC address — NIE losowe, możliwe do odgadnięcia
- NIE polegaj na "randomowości" UUID bez weryfikacji implementacji

### Defence in Depth

- Zaszyfrowane dane powinny być chronione też przez access control
- NIE polegaj na bezpieczeństwie zaszyfrowanych URL parameters
- Każda warstwa obrony może zawodzić — redundancja jest kluczowa

## Pentesterskie deep dive

### Mniej znane techniki

- **JWT `none` algorithm bypass**: starsze biblioteki JWT akceptowały `{"alg": "none"}` bez signature → atakujący tworzy dowolny token. Klasyk z 2015. Test: zmień `alg: HS256` → `alg: none`, usuń signature.
- **JWT HS256 → RS256 confusion**: jeśli aplikacja akceptuje `alg: HS256` ale używa public key jako HMAC secret, atakujący zna public key (z `/jwks.json`) i forguje token.
- **HMAC bypass via type juggling (PHP)**: `==` zamiast `===` w PHP może być bypassowany typami (`0 == "abc"` to `true` w PHP < 8.0).
- **CSRF token reuse across users**: aplikacja generuje token raz i reuseuje — atakujący zdobywa token raz i używa go zawsze.
- **Predictable session ID via PHP rand()**: PHP `rand()` jest seeded by current time → atakujący przewiduje session IDs (Schneier classic).
- **ECB mode pattern visibility**: encrypt obrazka ECB pokazuje structure obrazu w ciphertext (klasyczny "ECB Penguin" example).

### Common pitfalls

- **MD5 dla password hashing wciąż występuje**: nawet w 2024+ legacy aplikacje używają MD5(`password + salt`) — natychmiastowy crack.
- **Custom crypto "for added security"**: developers myślą że własna XOR-based encryption jest "bezpieczniejsza" → trywialny crack.
- **`Math.random()` dla CSRF token**: nawet w nowoczesnych frameworkach, niektórzy developers ignorują warnings i używają non-CSPRNG.
- **Hardcoded encryption key w JS bundle**: dla "client-side encryption" — beztroski client-side encryption z hardcoded key = false sense of security.

### Świeżynki z research

- **JWT cracking** — community pattern; HS256 z weak secret → `hashcat -m 16500` brute-force.
- **Post-quantum cryptography migration** — NIST PQC standards (Kyber, Dilithium) zaczynają się pojawiać.
- **Web Crypto API misuse** — community research; niektóre patterns w client-side crypto są fundamentally insecure.
- **HackTricks Cryptography**: https://book.hacktricks.xyz/cryptography
- **PortSwigger JWT Lab**: https://portswigger.net/web-security/jwt

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| JWT Editor | Edycja, podpisywanie, łamanie JWT | [GitHub](https://github.com/PortSwigger/jwt-editor) |
| JWT Heartbreaker | Detekcja CVE-2018-0114 (none, weak HS256) | community ext |
| Hackvertor | Encoding/decoding/decrypt manipulation | [GitHub](https://github.com/PortSwigger/hackvertor) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/09-Testing_for_Weak_Cryptography/04-Testing_for_Weak_Encryption
- OWASP Cryptographic Storage CS: https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html
- OWASP Key Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html
- OWASP Password Storage CS: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- HackTricks Cryptography: https://book.hacktricks.xyz/cryptography
- PortSwigger JWT: https://portswigger.net/web-security/jwt
- jwt.io (decoder + cracker): https://jwt.io/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.2.1 | Cryptography (L1) | All cryptographic modules fail securely. |
| V6.2.3 | Cryptography (L2) | Approved cryptographic algorithms used. |
| V6.2.5 | Cryptography (L2) | Authenticated encryption (e.g. GCM). |
| V2.4.1 | Authenticator (L1) | Passwords stored using approved password hashing functions. |
