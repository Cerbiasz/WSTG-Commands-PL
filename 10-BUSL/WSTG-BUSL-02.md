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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Forging Requests — kategorie atakow

- **CSRF**: zmuszenie przegladarki uzytkownika do wykonania requestu bez jego wiedzy
- **Parameter tampering**: modyfikacja ukrytych pol formularza, cen, ID
- **Replay attack**: ponowne wyslanie prawidlowego requestu
- **IDOR**: zmiana identyfikatorow obiektow (user_id, order_id) na cudze

### Obrona przed CSRF

- **Synchronizer Token**: unikalny token per sesja/request w formularzu (nie w cookie)
- **SameSite cookies**: `SameSite=Strict` lub `SameSite=Lax` — blokuj cross-origin requesty
- **Double Submit Cookie**: token w cookie + w body/header — porownanie server-side
- **Custom headers**: wymagaj custom headera (np. `X-Requested-With`) — przegladarki nie dodaja automatycznie cross-origin
- **Origin/Referer validation**: sprawdz header Origin/Referer — ale moze byc pusty

### Obrona przed Parameter Tampering

- **Server-side validation**: NIGDY nie ufaj danym od klienta — przeliczaj ceny, waliduj uprawnienia
- **HMAC/podpis**: podpisuj krytyczne dane (cena, ID) kluczem serwera — weryfikuj przy odbiorze
- **Integrity tokens**: hash parametrow + secret — wykrywaj modyfikacje
- **Allowlist parametrow**: akceptuj TYLKO oczekiwane pola (strong parameters)
- **Idempotency tokens**: jednorazowe tokeny — zapobiegaj replay attacks

### Przewidywalne identyfikatory

- Sekwencyjne ID (user/1, user/2) → **IDOR** — atakujacy zgaduje ID innych uzytkownikow
- Uzywaj **UUID v4** zamiast sekwencyjnych ID w URL-ach i parametrach
- Sprawdzaj autoryzacje na KAZDYM dostepie do obiektu — nie polegaj na "nieodgadnialnosci" ID

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Turbo Intruder | Szybkie wysylanie duzej liczby requestow z custom kodem | [BApp Store](https://portswigger.net/bappstore/9abfe09175d74b16842a3bbb0aa6a42c) |
| AutoRepeater | Automatyczne powtarzanie requestow z modyfikacjami | [GitHub](https://github.com/nccgroup/AutoRepeater) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.3.1 | Business Logic Security | Verify that the application will only process business logic flows for the same user in the expected sequential step order and without skipping steps. |
| V2.2.1 | Input Validation | Verify that input is validated to enforce business or functional expectations for that input. This should either use positive validation against an allow list of values, patterns, and ranges, or be based on comparing the input to an expected structure and logical limits according to predefined rules. For L1, this can focus on input which is used to make specific business or security decisions. For L2 and up, this should apply to all input. |
