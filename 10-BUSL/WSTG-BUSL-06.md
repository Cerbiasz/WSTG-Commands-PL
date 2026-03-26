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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md, Transaction_Authorization_Cheat_Sheet.md

### Workflow Circumvention — typowe ataki

- **Pominiecie kroku**: bezposredni dostep do URL koncowego (np. /order/complete)
- **Zmiana kolejnosci**: wykonanie kroku 3 przed krokiem 2
- **Cofanie sie**: powrot do kroku 1 po zakonczeniu kroku 3, zmiana danych
- **Modyfikacja stanu**: zmiana parametru `step=5` lub `status=completed`
- **Pominiecie platnosci**: przejscie od koszyka bezposrednio do potwierdzenia

### Server-Side State Machine — obrona

- Przechowuj **stan procesu na serwerze** — nie w ukrytych polach formularza
- Kazdy krok musi **walidowac** ze poprzedni krok zostal poprawnie ukonczony
- Uzywaj **state tokens**: unikalny token per krok, weryfikowany server-side
- NIE polegaj na kolejnosci URL-i — sprawdzaj logiczny stan procesu

### Krytyczne workflow do testowania

| Proces | Kroki | Co testowac |
|--------|-------|-------------|
| E-commerce | Koszyk → Platnosc → Potwierdzenie | Pominiecie platnosci |
| Rejestracja | Formularz → Weryfikacja email → Profil | Pominiecie weryfikacji |
| KYC | Dane osobowe → Dokument → Weryfikacja | Pominiecie weryfikacji dokumentu |
| Platnosc | Inicjacja → 3D Secure → Callback | Falszywy callback |
| Przelew | Dane → Autoryzacja → Wykonanie | Pominiecie autoryzacji |

### Obrona szczegolowa

- **Idempotency**: kazda operacja z unikalnym kluczem — powtorzenie = ignorowane
- **Transaction authorization**: krytyczne operacje wymagaja osobnego potwierdzenia (MFA, SMS code)
- **Audit trail**: loguj kazdy krok workflow z timestampem i user ID
- **Timeout**: workflow z ograniczonym czasem na ukonczenie — porzucone workflow sa anulowane

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Stepper | Multi-step repeater do testowania wieloetapowych workflowow | [GitHub](https://github.com/CoreyD97/Stepper) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.3.1 | Business Logic Security | Verify that the application will only process business logic flows for the same user in the expected sequential step order and without skipping steps. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.3.2 | Business Logic Security | Verify that business logic limits are implemented per the application's documentation to avoid business logic flaws being exploited. |
