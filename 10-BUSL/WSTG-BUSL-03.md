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

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
