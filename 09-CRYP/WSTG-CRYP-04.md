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

- Uzywaj silnych algorytmow: AES-256, RSA-2048+, SHA-256+ — unikaj MD5, SHA1, DES
- Rotuj klucze regularnie — implementuj mechanizm rotacji bez przerwy serwisu
- Przechowuj klucze oddzielnie od danych — uzywaj HSM lub dedicated key vault
- Nie hardkoduj kluczy w kodzie zrodlowym — uzywaj zmiennych srodowiskowych lub secret manager
- Uzywaj roznych kluczy do roznych celow (szyfrowanie, podpis, MAC)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AES Killer | Deszyfrowanie i analiza komunikacji AES | [GitHub](https://github.com/Ebryx/AES-Killer) |
| BurpCrypto | Operacje kryptograficzne na payloadach w Burp | [GitHub](https://github.com/whwlsfb/BurpCrypto) |
