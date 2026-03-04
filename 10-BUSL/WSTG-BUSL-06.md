# WSTG-BUSL-06 — Testing for the Circumvention of Work Flows

## Cele

- Pominac lub zmienic kolejnosc krokow w procesie biznesowym

## KOMENDY

### Testowanie bezposredniego dostepu do kroku 3 (pomijajac krok 1 i 2)

```bash
curl -v TARGET/checkout/payment
curl -v TARGET/checkout/confirmation
curl -v TARGET/order/complete

```

### Testowanie pominiecia weryfikacji email

```bash
curl -v -X POST TARGET/api/verify-skip -d "email=test@test.com&verified=true"
curl -v TARGET/dashboard -H "Cookie: session=SESSION_TOKEN"

```

### Testowanie pominiecia kroku platnosci

```bash
# Krok 1: Dodaj do koszyka
curl -v -X POST TARGET/api/cart/add -d "item=1&qty=1" -H "Cookie: session=SESSION"
# Krok 3: Bezposrednio potwierdz zamowienie (pomijajac platnosc)
curl -v -X POST TARGET/api/order/confirm -H "Cookie: session=SESSION"

```

### Testowanie zmiany kolejnosci krokow

```bash
# Normalny flow: register -> verify email -> set profile
# Testuj: register -> set profile (pomijajac verify)
curl -v -X POST TARGET/api/profile -H "Cookie: session=UNVERIFIED_SESSION" \
  -d "name=Test&role=admin"

```

### Testowanie modyfikacji parametru kroku

```bash
curl -v -X POST TARGET/api/process -d "step=5&data=complete"
curl -v -X POST TARGET/api/wizard -d "current_step=final"

```

### Testowanie cofania do poprzedniego kroku z nowymi danymi

```bash
# Po platnosci cofnij sie do koszyka i zmien cene:
curl -v -X POST TARGET/api/cart/update -d "item=1&price=0.01" -H "Cookie: session=PAID_SESSION"
curl -v -X POST TARGET/api/order/confirm -H "Cookie: session=PAID_SESSION"

```

### Testowanie bezposredniego dostepu do URL succesow

```bash
curl -v TARGET/payment/success
curl -v TARGET/order/thank-you
curl -v TARGET/registration/complete

```

### Testowanie manipulacji statusem w parametrach

```bash
curl -v -X POST TARGET/api/order/status -d "order_id=123&status=completed"
curl -v -X POST TARGET/api/order/status -d "order_id=123&payment_status=paid"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice workflow

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zmapuj caly workflow aplikacji (rejestracja, zakupy, platnosci)
2. W Burp Suite -> Sitemap: zidentyfikuj wszystkie kroki procesu
3. Probuj bezposrednio odwiedzic URL koncowych krokow (bez przechodzenia przez wczesniejsze)
4. Testuj cofanie sie do poprzednich krokow po zakonczeniu procesu
5. Sprawdz czy serwer waliduje kolejnosc krokow (state machine na serwerze)
6. Testuj modyfikacje hidden fields ktore sledza postep procesu
7. Sprawdz czy mozna powtorzyc krok (np. dwukrotna platnosc -> dwukrotna dostawa)

