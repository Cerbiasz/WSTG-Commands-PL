# WSTG-BUSL-10 — Test Payment Functionality

## Cele

- Przetestowac odpornosc logiki platnosci
- Zweryfikowac bezpieczenstwo procesu platniczego

## KOMENDY

### Testowanie modyfikacji ceny

```bash
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": 0.01, "quantity": 1}'

```

### Testowanie negatywnej ceny

```bash
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": -100, "quantity": 1}'

```

### Testowanie negatywnej ilosci

```bash
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": 100, "quantity": -1}'

```

### Testowanie zerowej ceny

```bash
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": 0, "quantity": 1}'

```

### Testowanie manipulacji waluta

```bash
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": 100, "currency": "KRW"}'
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": 100, "currency": "XXX"}'

```

### Testowanie modyfikacji kodu rabatowego

```bash
curl -v -X POST TARGET/api/apply-discount -d "code=DISCOUNT50&amount=100"
curl -v -X POST TARGET/api/apply-discount -d "code=DISCOUNT50&discount_percent=100"

```

### Testowanie podwojnego naliczenia rabatu

```bash
curl -v -X POST TARGET/api/apply-discount -d "code=DISCOUNT50" -H "Cookie: session=SESSION"
curl -v -X POST TARGET/api/apply-discount -d "code=DISCOUNT50" -H "Cookie: session=SESSION"

```

### Testowanie race condition na platnosci

```bash
for i in $(seq 1 10); do
    curl -s -X POST TARGET/api/pay -d "order_id=123&amount=100" -H "Cookie: session=SESSION" &
done
wait

```

### Testowanie modyfikacji parametrow po stronie klienta

```bash
# Zmiana calkowitej kwoty:
curl -v -X POST TARGET/api/payment/process -d "order_id=123&total=0.01&items=5"

```

### Testowanie pominiecia kroku platnosci

```bash
curl -v -X POST TARGET/api/order/confirm -d "order_id=123&payment_status=completed"

```

### Testowanie modyfikacji callback platnosci

```bash
curl -v -X POST TARGET/api/payment/callback -H "Content-Type: application/json" \
  -d '{"order_id": "123", "status": "success", "amount": "0.01"}'

```

### Testowanie modyfikacji ilosci po platnosci

```bash
curl -v -X POST TARGET/api/order/update -d "order_id=123&quantity=100" -H "Cookie: session=SESSION"

```

### Testowanie integer overflow na kwocie

```bash
curl -v -X POST TARGET/api/checkout -H "Content-Type: application/json" \
  -d '{"item_id": 1, "price": 99999999999, "quantity": 99999999999}'

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice platnosci

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Proxy: przechwytuj request platnosci i modyfikuj cene/ilosc
2. Testuj caly flow: koszyk -> platnosc -> potwierdzenie - szukaj punktow modyfikacji
3. Sprawdz czy cena jest przeliczana po stronie serwera (nie ufaj klientowi)
4. Testuj manipulacje walut (zmiana z USD na tansza walute)
5. Testuj race condition na platnosci (wielokrotne uzycie jednorazowego kodu)
6. Sprawdz czy callback platnosci weryfikuje podpis/HMAC bramki platniczej
7. Testuj cofanie platnosci i sprawdz czy towar jest nadal dostepny
8. Sprawdz czy historia zamowien poprawnie odzwierciedla zmiany


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transaction_Authorization_Cheat_Sheet.md, Abuse_Case_Cheat_Sheet.md

### Bezpieczenstwo platnosci — kluczowe zasady

- **Cena ustalana SERVER-SIDE**: serwer musi przeliczac calkowita kwote na podstawie produktow w koszyku
- NIGDY nie ufaj cenie/kwocie przeslanej przez klienta — zawsze przelicz z bazy danych
- **Integralnosc danych**: podpisuj HMAC-em parametry platnosci (kwota, waluta, order_id)
- **Idempotency**: kazda platnosc z unikalnym kluczem — zapobiegaj double charging

### Typowe ataki na platnosci

| Atak | Opis | Obrona |
|------|------|--------|
| Price manipulation | Zmiana ceny w request body | Server-side price calculation |
| Negative price/quantity | Ujemne wartosci daja "zwrot" | Waliduj: cena > 0, ilosc > 0 |
| Currency switching | Zmiana waluty na tansza | Waliduj walute server-side |
| Coupon stacking | Wielokrotne uzycie kuponu | Atomic operation, jednorazowe kupony |
| Race condition | Podwojne klikniecie "Zaplac" | Idempotency keys |
| Skip payment step | Bezposredni dostep do /order/complete | Server-side state machine |
| Callback manipulation | Falszywy callback "payment success" | Weryfikuj podpis bramki platniczej |
| Integer overflow | Ogromna ilosc * cena = overflow = niska kwota | Waliduj zakresy, uzyj Decimal |

### Bramka platnicza — bezpieczna integracja

- **Webhook/callback**: weryfikuj podpis (HMAC/RSA) od bramki platniczej
- **Nie ufaj parametrom w URL callback** — sprawdz stan platnosci przez API bramki
- **Server-to-server**: krytyczne dane (kwota, status) potwierdzane server-side, nie przez klienta
- **3D Secure**: implementuj dla kart — dodatkowa warstwa autoryzacji
- **PCI DSS**: nie przechowuj pelnych numerow kart — uzyj tokenizacji bramki

### Autoryzacja transakcji

- **Re-autentykacja**: wymagaj hasla/MFA przed krytycznymi operacjami finansowymi
- **Transaction signing**: uzytkownik potwierdza dokladna kwote i odbiorce (nie generic "potwierdz")
- **Limity transakcji**: dzienny/miesięczny limit — wymaga dodatkowej weryfikacji po przekroczeniu
- **Cooling period**: opoznienie dla duzych transakcji — czas na wykrycie oszustwa

### Testowanie

- Modyfikuj cene, ilosc, walute, rabat w Burp Repeater
- Testuj negatywne i zerowe wartosci
- Testuj race condition na platnosci (wiele requestow jednoczesnie)
- Sprawdz czy callback jest weryfikowany (wyslij falszywy callback)
- Testuj pominiecie kroku platnosci (bezposredni dostep do potwierdzenia)
- Sprawdz integer overflow na ilosc * cena

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
