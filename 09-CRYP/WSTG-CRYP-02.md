# WSTG-CRYP-02 — Testing for Padding Oracle

## Cel

Wykrycie podatności padding oracle: aplikacja używająca CBC mode z osobną walidacją padding (PKCS#7) może wyciec rozróżnienie "zły padding" vs "zła wartość" — atakujący dekryptuje ciphertext bajt po bajcie BEZ klucza.

> **Test manual-heavy**: padding oracle wymaga 256 requestów per byte ciphertext + analizy differential responses (różny status code/timing/error message). Automatyzacja Nuclei nie ma tu zastosowania — używamy `padbuster` lub `PadBuster.pl`.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify CBC ciphertext**: wartości base64-encoded w cookies/URL params/hidden fields które wyglądają na ciphertext (długość % 16 == 0, base64).
2. **Differential probe**: zmodyfikuj 1 bajt ciphertext → obserwuj response. Jeśli różny error/status/timing dla padding-error vs decryption-error = padding oracle.
3. **PadBuster automation**: `padbuster <url> <ciphertext> <block_size> -cookies "auth=<ct>"` — automatyczna dekrypcja.
4. **Encryption attack**: padding oracle pozwala też na ENCRYPTION arbitrary plaintext (nie tylko decryption) — sfałszowanie session token z desired role.
5. **Verify in safer alternatives**: po identyfikacji aplikacja powinna migrować do AES-GCM (authenticated encryption).

### Co MUSI być sprawdzone (8 punktów)

- [ ] Identify base64/hex-encoded ciphertext w session cookies
- [ ] Identify ciphertext w URL params (e.g., `?token=xxx`)
- [ ] Identify ciphertext w hidden form fields
- [ ] Differential probe: bit flip → observe response
- [ ] Different status codes per padding error vs decryption error?
- [ ] Different error messages per padding error?
- [ ] Different response time?
- [ ] PadBuster run against suspected oracle

### Per stack — typowe lokacje ciphertext

| Stack | Lokacja | Algorytm |
|---|---|---|
| ASP.NET ViewState (legacy) | `__VIEWSTATE` hidden field | AES-CBC bez MAC (legacy) → CVE-2017-9248 |
| ASP.NET FormsAuth (legacy) | `.ASPXAUTH` cookie | AES-CBC z MAC (Encrypt-then-MAC) |
| Java JSF | `javax.faces.ViewState` | AES-CBC |
| Symfony | `REMEMBERME` cookie | AES-CBC w starszych wersjach |
| Custom token | `?token=base64...` | typowy custom AES-CBC |
| Django session | `sessionid` | nie używa CBC bezpośrednio (signed cookie) |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cryptographic_Storage_Cheat_Sheet.md

### Authenticated Encryption — obrona przed padding oracle

- **AES-GCM** (REKOMENDOWANY) — zapewnia poufność + integralność + autentyczność w jednej operacji
- **ChaCha20-Poly1305** — alternatywa, dobra wydajność na urządzeniach bez AES-NI
- **CCM** — kolejna opcja authenticated encryption
- Authenticated modes ELIMINUJĄ padding oracle — nie ma osobnego kroku walidacji padding

### Dlaczego CBC jest podatny

- CBC (Cipher Block Chaining) wymaga osobnej walidacji padding (PKCS#7)
- Jeśli serwer rozróżnia "zły padding" od "zła wartość" — atakujący dekryptuje ciphertext bajt po bajcie
- Różnice mogą być: różny kod HTTP (500 vs 200), różny czas odpowiedzi, różny komunikat błędu
- **Encrypt-then-MAC**: jeśli MUSISZ użyć CBC — oblicz HMAC na ciphertext PRZED dekrypcją, zweryfikuj HMAC first

### Bezpieczne porównywanie MAC/HMAC

- Używaj **constant-time comparison** — obrona przed timing attacks
- Python: `hmac.compare_digest()`, Java: `MessageDigest.isEqual()`, PHP: `hash_equals()`
- NIGDY nie porównuj hashów przez `==` lub `equals()` — timing side-channel

### Algorytmy szyfrowania symetrycznego

- **AES-128** minimum, **AES-256** preferowany, z trybem **GCM** lub **CCM**
- **NIGDY**: DES, 3DES, RC4, Blowfish (przestarzałe, słabe klucze)
- **NIGDY**: tryb **ECB** — ten sam plaintext daje ten sam ciphertext (wzorce widoczne)

### Algorytmy asymetryczne

- **ECC Curve25519** (preferowany) lub **RSA >= 2048 bit**
- RSA: ZAWSZE używaj **OAEP padding** (Optimal Asymmetric Encryption Padding) — obrona przed known plaintext attacks
- NIGDY: RSA z PKCS#1 v1.5 padding — podatny na Bleichenbacher attack

### Secure Random Number Generation

- Kryptograficznie bezpieczne PRNG (CSPRNG) dla kluczy, IV, tokenów:
  - Java: `SecureRandom`, Python: `secrets`, PHP: `random_bytes()`, Node: `crypto.randomBytes()`
  - C: `getrandom(2)`, .NET: `RandomNumberGenerator`, Go: `crypto/rand`
- **NIGDY**: `Math.random()`, `rand()`, `mt_rand()` — przewidywalne, NIE do kryptografii

### Zarządzanie kluczami

- Przechowuj klucze ODDZIELNIE od zaszyfrowanych danych (np. klucze na filesystem, dane w DB)
- Używaj **Key Encryption Key (KEK)** do szyfrowania **Data Encryption Key (DEK)** — envelope encryption
- Rotuj klucze: po kompromitacji, po upływie cryptoperiod, po zaszyfrowaniu dużej ilości danych
- Przechowuj klucze w: HSM, AWS KMS, Azure Key Vault, HashiCorp Vault — NIE w kodzie źródłowym
- NIE hard-coduj kluczy w kodzie, NIE commituj do VCS, NIE przechowuj w env vars (phpinfo exposure)

## Pentesterskie deep dive

### Mniej znane techniki

- **POODLE attack on TLS** (CVE-2014-3566): padding oracle on SSL 3.0 / TLS 1.0. Modern TLS 1.2+ z AES-GCM eliminuje, ale legacy serwery nadal vulnerable.
- **Lucky 13 (CVE-2013-0169)**: timing-based padding oracle na TLS 1.0/1.1 CBC mode — różnice w µs pozwalają atakującemu odzyskać plaintext przez wiele requestów.
- **CVE-2017-9248 ASP.NET ViewState**: Telerik UI for ASP.NET → padding oracle → RCE. Klasyczny enterprise finding.
- **Bleichenbacher attack on RSA PKCS#1 v1.5**: gdy backend rozróżnia "valid padding" vs "invalid padding" w RSA decryption — chosen ciphertext attack pozwala odzyskać plaintext (wpływa też na TLS w niektórych wariantach: ROBOT attack 2017).
- **Manger's attack (RSA-OAEP)**: timing attack na OAEP gdy implementacja nie jest constant-time — rzadkie ale teoretyczna luka.
- **CBC bit-flipping bez oracle**: nawet bez padding oracle, jeśli aplikacja ufa plaintext z CBC bez MAC, atakujący może modyfikować specific plaintext bytes (cookie tampering). Nie wymaga decryption — tylko XOR.

### Common pitfalls

- **Generic 500 ukrywający padding oracle**: aplikacja zwraca generic 500 dla wszystkich błędów ale **timing differential** wciąż wskazuje oracle. Wymagana statystyczna analiza.
- **Encrypt-then-MAC z incorrect order**: aplikacje computing MAC PO decryption (zamiast PRZED) wciąż mają oracle.
- **Constant-time comparison ignored in framework**: niektóre stary framework używają `==` zamiast `MessageDigest.isEqual()` → timing leak.

### Świeżynki z research

- **Web Padding Oracle in modern frameworks** — community pattern; mimo świadomości, custom implementations w PHP/Node nadal wprowadzają oracle.
- **POODLE attack research**: https://www.openssl.org/~bodo/ssl-poodle.pdf
- **PadBuster tool**: https://github.com/AonCyberLabs/PadBuster
- **HackTricks Padding Oracle**: https://book.hacktricks.xyz/cryptography/padding-oracle-priv

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Hackvertor | Encoding/encryption manipulation w request | [GitHub](https://github.com/PortSwigger/hackvertor) |
| PadBuster (CLI) | Automated padding oracle exploit | [GitHub](https://github.com/AonCyberLabs/PadBuster) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/09-Testing_for_Weak_Cryptography/02-Testing_for_Padding_Oracle
- OWASP Cryptographic Storage CS: https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html
- PadBuster: https://github.com/AonCyberLabs/PadBuster
- POODLE attack: https://www.openssl.org/~bodo/ssl-poodle.pdf
- HackTricks Padding Oracle: https://book.hacktricks.xyz/cryptography/padding-oracle-priv

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.2.5 | Cryptography (L2) | Authenticated encryption (e.g. GCM) used. |
| V6.2.6 | Cryptography (L2) | NIST insecure modes (e.g. CBC) deprecated. |
| V6.2.4 | Cryptography (L2) | Approved cryptographic functions used. |
