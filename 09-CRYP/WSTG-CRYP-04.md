# WSTG-CRYP-04 — Testing for Weak Encryption

## Cele

- Zidentyfikowac uzycie slabych algorytmow szyfrowania lub hashowania

## KOMENDY

### hash-identifier - identyfikacja typu hash

```bash
hash-identifier
# Wklej znaleziony hash i narzedzie zidentyfikuje typ

```

### hashid - identyfikacja typu hash

```bash
hashid 'HASH_VALUE'
hashid -m 'HASH_VALUE'

```

### Sprawdzenie czy hasla sa przechowywane jako MD5

```bash
echo -n "password123" | md5sum
# Porownaj z hashem znalezionym w aplikacji

```

### Sprawdzenie czy hasla sa przechowywane jako SHA-1

```bash
echo -n "password123" | sha1sum

```

### Sprawdzenie sily bcrypt hash (prawidlowe podejscie)

```bash
# bcrypt hash powinien wygladac jak: $2b$12$...
# Sprawdz cost factor - powinien byc >= 10

```

### john - lamanie slabych hashy

```bash
john --format=raw-md5 hash_file.txt
john --format=raw-sha1 hash_file.txt
john --format=raw-sha256 hash_file.txt

```

### hashcat - lamanie slabych hashy

```bash
hashcat -m 0 hash_file.txt wordlist.txt    # MD5
hashcat -m 100 hash_file.txt wordlist.txt  # SHA-1
hashcat -m 1400 hash_file.txt wordlist.txt # SHA-256
hashcat -m 3200 hash_file.txt wordlist.txt # bcrypt

```

### Sprawdzenie uzycia Base64 jako "szyfrowania"

```bash
echo "ENCODED_VALUE" | base64 -d

```

### Sprawdzenie uzycia ROT13

```bash
echo "ENCODED_VALUE" | tr 'A-Za-z' 'N-ZA-Mn-za-m'

```

### Sprawdzenie sily kluczy w JWT

```bash
# Dekodowanie JWT header:
echo "JWT_HEADER_PART" | base64 -d 2>/dev/null
# Sprawdz algorytm: HS256, RS256, none

```

### jwt_tool - testowanie JWT

```bash
python3 jwt_tool.py "JWT_TOKEN" -C -d wordlist.txt
python3 jwt_tool.py "JWT_TOKEN" -X a    # test alg:none
python3 jwt_tool.py "JWT_TOKEN" -X k    # key confusion

```

### Sprawdzenie certyfikatow z slabymi algorytmami

```bash
openssl s_client -connect TARGET:443 < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -E "Signature Algorithm|Public-Key"

```

### CyberChef offline - analiza encodingow

```bash
# Uzyj CyberChef do identyfikacji wielowarstwowego kodowania

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na analizie kryptograficznej

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przeanalizuj cookies i tokeny - zidentyfikuj typ kodowania/szyfrowania
2. Sprawdz czy hasla w bazie danych sa hashowane z salt (bcrypt, scrypt, argon2)
3. Szukaj uzycia MD5 lub SHA-1 do hashowania hasel (slabe)
4. Sprawdz czy kody resetowania hasla sa przewidywalne
5. Sprawdz JWT: algorytm (unikaj HS256 z slabym kluczem, none), klucz
6. Sprawdz czy API klucze sa Base64 encoded zamiast zaszyfrowanych
7. Sprawdz czy dane wrazliwe w bazie sa szyfrowane (nie zakodowane)
8. Zweryfikuj dlugosc kluczy: RSA >= 2048bit, AES >= 128bit


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cryptographic_Storage_Cheat_Sheet.md, Key_Management_Cheat_Sheet.md

### Algorytmy — co uzywac, czego unikac

- **Szyfrowanie symetryczne**: AES-128 minimum, AES-256 preferowany, tryb **GCM** (authenticated encryption)
- **Szyfrowanie asymetryczne**: ECC Curve25519 (preferowany) lub RSA >= 2048 bit
- **Hashowanie hasel**: Argon2id (rekomendowany), bcrypt (cost >= 10), scrypt, PBKDF2 (FIPS)
- **Hashowanie integralnosci**: SHA-256+, SHA-3
- **NIGDY nie uzywaj**: MD5, SHA-1 (do hasel), DES, 3DES, RC4, Blowfish, ECB mode
- **NIGDY**: custom/wlasne algorytmy kryptograficzne

### Tryby szyfrowania blokowego

- **GCM** (REKOMENDOWANY) — authenticated encryption, zapewnia poufnosc + integralnosc
- **CCM** — alternatywa dla GCM
- **CTR/CBC** — jesli GCM niedostepny, ALE wymagaja osobnego MAC (Encrypt-then-MAC)
- **ECB** — NIGDY (ten sam plaintext → ten sam ciphertext, wzorce widoczne)

### Secure Random Number Generation (CSPRNG)

- Java: `SecureRandom` | Python: `secrets` | PHP: `random_bytes()` | Node: `crypto.randomBytes()`
- .NET: `RandomNumberGenerator` | Go: `crypto/rand` | C: `getrandom(2)` | Ruby: `SecureRandom`
- **NIGDY**: `Math.random()`, `rand()`, `random()`, `mt_rand()` — przewidywalne

### Zarzadzanie kluczami

- **Separacja kluczy od danych**: klucze na filesystem, dane w DB (lub odwrotnie)
- **Envelope encryption**: Data Encryption Key (DEK) szyfrowany Key Encryption Key (KEK)
- **Przechowywanie kluczy**: HSM, AWS KMS, Azure Key Vault, HashiCorp Vault, GCP Cloud KMS
- **NIE**: hardkoduj w kodzie, NIE commituj do VCS, NIE w env vars (ryzyko phpinfo/proc/environ)
- **Rotacja kluczy**: po kompromitacji, po uplywie cryptoperiod, po zaszyfrowaniu duzej ilosci danych

### RSA — bezpieczne uzycie

- **OAEP padding** (Optimal Asymmetric Encryption Padding) — ZAWSZE
- NIGDY: PKCS#1 v1.5 padding — podatny na Bleichenbacher attack

### UUID/GUID a bezpieczenstwo

- UUID v4 — losowe, bezpieczne jesli generowane przez CSPRNG
- UUID v1 — oparte na timestamp + MAC address — NIE losowe, mozliwe do odgadniecia
- NIE polegaj na "randomowosci" UUID bez weryfikacji implementacji

### Defence in Depth

- Zaszyfrowane dane powinny byc chronione tez przez access control
- NIE polegaj na bezpieczenstwie zaszyfrowanych URL parameters
- Kazda warstwa obrony moze zawodzic — redundancja jest kluczowa

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AES Killer | Deszyfrowanie i analiza komunikacji AES | [GitHub](https://github.com/Ebryx/AES-Killer) |
| BurpCrypto | Operacje kryptograficzne na payloadach w Burp | [GitHub](https://github.com/whwlsfb/BurpCrypto) |
