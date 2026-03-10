# WSTG-BUSL-03 — Test Integrity Checks

## Cele

- Przegladnac obsluge danych pod katem kontroli integralnosci
- Sprobowac nieautoryzowanej modyfikacji danych

## KOMENDY

### Testowanie modyfikacji danych w tranzycie

```bash
curl -v -X POST TARGET/api/payment -H "Content-Type: application/json" \
  -d '{"amount": 1, "currency": "USD", "item": "product_1"}'
# Zmien amount na 0.01:
curl -v -X POST TARGET/api/payment -H "Content-Type: application/json" \
  -d '{"amount": 0.01, "currency": "USD", "item": "product_1"}'

```

### Testowanie HMAC/signature bypass

```bash
# Jezeli request zawiera podpis:
curl -v -X POST TARGET/api/transfer \
  -H "X-Signature: ORIGINAL_SIGNATURE" \
  -d '{"from": "user1", "to": "attacker", "amount": 1000}'
# Testuj z pustym podpisem:
curl -v -X POST TARGET/api/transfer \
  -H "X-Signature: " \
  -d '{"from": "user1", "to": "attacker", "amount": 1000}'
# Testuj bez podpisu:
curl -v -X POST TARGET/api/transfer \
  -d '{"from": "user1", "to": "attacker", "amount": 1000}'

```

### Testowanie manipulacji checksum

```bash
curl -v -X POST TARGET/api/upload \
  -F "file=@test.txt" -F "checksum=0000000000000000"

```

### Testowanie modyfikacji JWT payload

```bash
# Dekoduj JWT:
echo "JWT_PAYLOAD_PART" | base64 -d
# Zmien dane (np. role: admin), zakoduj ponownie, wyslij z oryginalnym podpisem:
curl -v TARGET/api/admin -H "Authorization: Bearer MODIFIED_JWT"

```

### Testowanie modyfikacji kolejnosci parametrow

```bash
curl -v -X POST TARGET/api/order -d "step=3&item=1&verified=true"
curl -v -X POST TARGET/api/order -d "item=1&verified=true&step=3"

```

### Testowanie modyfikacji ViewState (ASP.NET)

```bash
# Jezeli ViewState nie jest podpisany/zaszyfrowany:
curl -v -X POST TARGET/page -d "__VIEWSTATE=MODIFIED_VALUE&__EVENTVALIDATION=ORIGINAL"

```

### Testowanie modyfikacji cookies integralnosci

```bash
curl -v TARGET/dashboard -H "Cookie: user=admin; role=superadmin; verified=true"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice i kryptografii

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Proxy: przechwytuj requesty i modyfikuj dane (ceny, ilosci, ID)
2. Sprawdz czy aplikacja weryfikuje integralnosc danych po stronie serwera
3. Szukaj HMAC/signature w requestach - testuj ich usuniecie lub modyfikacje
4. Testuj modyfikacje zaszyfrowanych/zakodowanych parametrow
5. Sprawdz czy ViewState jest podpisany (ASP.NET MAC validation)
6. Testuj replay attack - wyslij stary request ponownie
7. Sprawdz czy checksumy plikow sa weryfikowane po stronie serwera
8. Testuj modyfikacje danych miedzy krokami workflow (np. zmiana ceny miedzy koszykiem a platnoscia)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cryptographic_Storage_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Kontrola integralnosci — mechanizmy

- **HMAC** (Hash-based Message Authentication Code): podpis danych kluczem serwera
- **Podpisy cyfrowe**: RSA/ECDSA — silniejsze niz HMAC, asymetryczne
- **Checksums**: SHA-256 hash danych — wykrywa modyfikacje (ale nie chroni bez klucza)
- **JWT z podpisem**: RS256/ES256 — integralnosc payload potwierdzona podpisem

### Co chronić integralnoscią

- **Ceny i kwoty**: serwer musi przeliczac ceny — nie ufac wartosciom od klienta
- **Dane sesji**: ViewState (ASP.NET), cookie-based sessions — musza byc podpisane
- **Tokeny**: JWT, reset tokens, invite tokens — podpisane i weryfikowane
- **Parametry workflow**: step number, status, verified flags — server-side state machine
- **Pliki**: checksumy przy upload/download — weryfikuj integralnosc

### Typowe ataki na integralnosc

- **Modyfikacja ceny w tranzycie**: zmien `amount: 100` na `amount: 0.01` w Burp
- **JWT manipulation**: zmien payload (role: admin) bez znajomosci klucza (alg:none attack)
- **ViewState tampering**: jesli MAC validation wylaczony — modyfikuj dane
- **Replay attack**: ponowne wyslanie prawidlowego requestu (np. podwojna platnosc)
- **Parameter pollution**: `price=100&price=0.01` — ktora wartosc uzyje backend?

### Obrona

- Podpisuj HMAC-em wszystkie dane ktorych integralnosc jest krytyczna
- Weryfikuj podpis server-side PRZED przetworzeniem danych
- Uzyj **idempotency tokens** — zapobiegaj replay attacks
- Implementuj **server-side state machine** — nie polegaj na parametrach kroku od klienta
- Loguj i alertuj na nieudane weryfikacje integralnosci — moze wskazywac na atak

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
