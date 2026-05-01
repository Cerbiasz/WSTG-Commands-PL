# WSTG-BUSL-06 — Testing for the Circumvention of Work Flows

## Cel

Wykrycie obejść workflow: pominięcie kroku (skip payment), zmiana kolejności, modyfikacja stanu (`step=5`), powrót do wcześniejszego kroku po zatwierdzeniu, direct access do final step URL.

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Map workflow**: każdy multi-step proces (registration, checkout, password reset).
2. **Step skip test**: zaczynaj normalnie, próbuj skip (np. checkout → confirmation z pominięciem payment).
3. **State manipulation**: edit `step=5` lub `status=completed` w request.
4. **Direct URL access**: `/checkout/confirmation/<order_id>` bez przejścia step-by-step.
5. **Backward replay**: po finalize, replay starszego step → break stanu?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Skip payment in checkout
- [ ] Skip email verification w registration
- [ ] Skip MFA challenge
- [ ] Direct access do final step URL
- [ ] State parameter manipulation
- [ ] Reorder steps
- [ ] Backward replay finalized step
- [ ] Race condition between steps (cross WSTG-BUSL-04)
- [ ] Server-side state machine validation
- [ ] Hidden state w client-side (form fields, localStorage)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md, Transaction_Authorization_Cheat_Sheet.md

### Workflow Circumvention — typowe ataki

- **Pominięcie kroku**: bezpośredni dostęp do URL końcowego (np. /order/complete)
- **Zmiana kolejności**: wykonanie kroku 3 przed krokiem 2
- **Cofanie się**: powrót do kroku 1 po zakończeniu kroku 3, zmiana danych
- **Modyfikacja stanu**: zmiana parametru `step=5` lub `status=completed`
- **Pominięcie płatności**: przejście od koszyka bezpośrednio do potwierdzenia

### Server-Side State Machine — obrona

- Przechowuj **stan procesu na serwerze** — nie w ukrytych polach formularza
- Każdy krok musi **walidować** że poprzedni krok został poprawnie ukończony
- Używaj **state tokens**: unikalny token per krok, weryfikowany server-side
- NIE polegaj na kolejności URL-i — sprawdzaj logiczny stan procesu

### Krytyczne workflow do testowania

| Proces | Kroki | Co testować |
|--------|-------|-------------|
| E-commerce | Koszyk → Płatność → Potwierdzenie | Pominięcie płatności |
| Rejestracja | Formularz → Weryfikacja email → Profil | Pominięcie weryfikacji |
| Zmiana hasła | Stare hasło → Nowe hasło → Potwierdzenie | Pominięcie weryfikacji starego |
| KYC verification | Upload doc → Verify → Activate | Skip verify, direct activate |
| Subscription | Choose plan → Payment → Activate | Skip payment, direct activate |

### Obrona

- Server-side state machine: każdy step transition validated
- Idempotency keys: prevent duplicate operations
- Audit logging: log każdy step transition
- Token per step: state token weryfikowany server-side

## Pentesterskie deep dive

### Mniej znane techniki

- **Concurrent flow exploitation**: zaczyna password reset w jednej karcie, login w innej z innym kontem - czy state crossing?
- **Saga pattern compensation abuse**: w distributed systems, atakujący exploits compensation timing.
- **Idempotency key reuse**: ten sam idempotency key dla różnych operacji - może bypass step check.

### Common pitfalls

- **Hidden form fields contain step state**: client-side modification = state injection.
- **No server-side validation of completed steps**: anyone z URL może access final step.

### Świeżynki z research

- **PortSwigger Business Logic Lab**: https://portswigger.net/web-security/logic-flaws
- **Smashing the State Machine**: https://portswigger.net/research/smashing-the-state-machine

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Stepper | Sequential workflow execution |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/06-Testing_for_the_Circumvention_of_Work_Flows
- OWASP Abuse Case CS: https://cheatsheetseries.owasp.org/cheatsheets/Abuse_Case_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V11.1.1 | Business logic flows in sequential order. |
| V11.1.2 | Business logic flows have all steps performed. |
