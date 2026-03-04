# WSTG-BUSL-02 — Test Ability to Forge Requests

## Cele

- Szukac przewidywalnej/zgadywalnej/ukrytej funkcjonalnosci
- Przetestowac mozliwosc podrabiania requestow

## KOMENDY

### Testowanie sekwencyjnych ID

```bash
curl -v TARGET/api/users/1
curl -v TARGET/api/users/2
curl -v TARGET/api/users/100

```

### Testowanie modyfikacji ukrytych pol formularza

```bash
curl -v -X POST TARGET/submit -d "name=test&hidden_field=modified_value"
curl -v -X POST TARGET/submit -d "name=test&price=0.01"
curl -v -X POST TARGET/submit -d "name=test&role=admin"
curl -v -X POST TARGET/submit -d "name=test&discount=100"

```

### Testowanie modyfikacji zakodowanych parametrow

```bash
# Base64 encoded params:
echo -n '{"user":"admin","role":"admin"}' | base64
curl -v "TARGET/page?token=BASE64_ENCODED_VALUE"

```

### Testowanie przewidywalnych tokenow

```bash
# Wygeneruj kilka tokenow i szukaj wzorca:
curl -s TARGET/api/generate-token | jq '.token'
curl -s TARGET/api/generate-token | jq '.token'
curl -s TARGET/api/generate-token | jq '.token'

```

### Testowanie modyfikacji parametrow zamowienia

```bash
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" \
  -d '{"item_id": 1, "quantity": 1, "price": 0.01, "discount": 99}'

```

### Testowanie CSRF - podrabianie requestow z innej domeny

```bash
curl -v -X POST TARGET/api/change-email -H "Origin: https://evil.com" \
  -H "Referer: https://evil.com/attack" -d "email=attacker@evil.com"

```

### Testowanie zmiany metody HTTP

```bash
curl -v -X GET TARGET/api/admin/delete-user?id=1
curl -v -X POST TARGET/api/admin/delete-user -d "id=1"
curl -v -X PUT TARGET/api/admin/delete-user -d "id=1"

```

### Testowanie dodatkowych parametrow

```bash
curl -v -X POST TARGET/api/register -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test","is_admin":true,"role":"superadmin"}'

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice biznesowej

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Repeater: modyfikuj ukryte pola formularzy
2. Zidentyfikuj sekwencyjne identyfikatory (user ID, order ID) i przetestuj IDOR
3. Sprawdz czy parametry ceny/ilosci moga byc modyfikowane po stronie klienta
4. Testuj modyfikacje zakodowanych parametrow (Base64, URL encode, hex)
5. Sprawdz czy tokeny sa przewidywalne (generuj wiele i porownuj)
6. Testuj dodawanie dodatkowych parametrow do requestow (mass assignment)
7. Sprawdz czy serwer weryfikuje integralnosc danych (HMAC, podpis)

