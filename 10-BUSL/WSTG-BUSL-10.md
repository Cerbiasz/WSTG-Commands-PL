# WSTG-BUSL-10 — Test Payment Functionality

## Cel

Audyt płatności: server-side price recalculation, integer overflow, negative quantities, currency switching, coupon stacking, race condition na payment submit, callback signature validation.

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Price tampering**: zmień cena w request body → akceptowane?
2. **Negative values**: ujemna cena/ilość = refund?
3. **Currency switching**: zmień EUR na ZWL (zimbabwe dollar)?
4. **Coupon stacking**: użyj 5 kuponów jednocześnie → akceptowane?
5. **Race condition**: 2× klik "Pay" simultaneously - cross WSTG-BUSL-04.
6. **Callback manipulation**: bypass payment via fake callback (`?status=success`).

### Co MUSI być sprawdzone (15 punktów)

- [ ] Server-side price recalculation
- [ ] Negative price/quantity blocked
- [ ] Currency validation server-side
- [ ] Coupon stacking limited
- [ ] Idempotency keys (no double charge)
- [ ] Skip payment step blocked
- [ ] Callback signature validated
- [ ] Integer overflow protection
- [ ] Decimal precision (no 0.001 free items)
- [ ] HMAC on critical params (amount, order_id)
- [ ] PCI DSS compliance (no card data stored bez tokenization)
- [ ] 3DS authentication
- [ ] Refund authorization checks
- [ ] Wallet balance race conditions
- [ ] Order status integrity (`status=paid` w request body blocked)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transaction_Authorization_Cheat_Sheet.md, Abuse_Case_Cheat_Sheet.md

### Bezpieczeństwo płatności — kluczowe zasady

- **Cena ustalana SERVER-SIDE**: serwer musi przeliczać całkowitą kwotę na podstawie produktów w koszyku
- NIGDY nie ufaj cenie/kwocie przesłanej przez klienta — zawsze przelicz z bazy danych
- **Integralność danych**: podpisuj HMAC-em parametry płatności (kwota, waluta, order_id)
- **Idempotency**: każda płatność z unikalnym kluczem — zapobiegaj double charging

### Typowe ataki na płatności

| Atak | Opis | Obrona |
|------|------|--------|
| Price manipulation | Zmiana ceny w request body | Server-side price calculation |
| Negative price/quantity | Ujemne wartości dają "zwrot" | Waliduj: cena > 0, ilość > 0 |
| Currency switching | Zmiana waluty na tańszą | Waliduj walutę server-side |
| Coupon stacking | Wielokrotne użycie kuponu | Atomic operation, jednorazowe kupony |
| Race condition | Podwójne kliknięcie "Zapłać" | Idempotency keys |
| Skip payment step | Bezpośredni dostęp do /order/complete | Server-side state machine |
| Callback manipulation | Fałszywy callback "payment success" | Weryfikuj podpis bramki płatniczej |
| Integer overflow | Ogromna ilość * cena = overflow = niska kwota | Waliduj zakresy, użyj Decimal |

### Bramka płatnicza — bezpieczna integracja

- **Callback validation**: weryfikuj signature/HMAC z payment gateway
- **Webhook security**: TLS + signature + IP allowlist
- **Polling fallback**: nie polegaj wyłącznie na webhook - poll status (płatności zawodzą)
- **Idempotency**: gateway provides idempotency keys - przekaż client requested id
- **Server-to-server confirmation**: post-callback, server kontaktuje gateway aby potwierdzić

### PCI DSS Compliance

- **Tokenization**: card data tokenized przez payment gateway (Stripe, Braintree)
- **No raw card data storage**: aplikacja NIGDY nie touchuje raw card numbers
- **HTTPS everywhere**: WSZYSTKIE auth + payment requests
- **Logging**: nie loguj card numbers, CVV, full PAN
- **Network segmentation**: payment service na osobnym network segment

### 3D Secure (3DS)

- **3DS1** (legacy): challenge-based authentication
- **3DS2** (rekomendowane): risk-based, less friction
- Supported by all major card networks (Visa, MC, Amex)
- Increases conversion + reduces fraud

## Pentesterskie deep dive

### Mniej znane techniki

- **Stripe webhook signature bypass**: jeśli aplikacja sprawdza tylko presence header, nie value - atakujący sends fake webhook.
- **Currency manipulation chain**: `?amount=100&currency=EUR` → `?amount=100&currency=USD` (USD < EUR ratio).
- **Decimal precision attack**: `0.001` x 1000 = 1.000 ale stored as 1.0 (lost cent).
- **Coupon code prediction**: sequential coupon codes (`PROMO0001`, `PROMO0002`) - mass enumeration.
- **Refund-as-purchase**: API allows POST z negative amount as refund without authentication.

### Common pitfalls

- **Server validates price ALE client-side discount**: discount calculated client → atakujący sets discount=99%.
- **Integer overflow in JavaScript**: `Number.MAX_SAFE_INTEGER + 1` overflow.
- **Callback verification w GET param**: `?signature=xxx` - replay possible.

### Świeżynki z research

- **PortSwigger Business Logic Lab**: https://portswigger.net/web-security/logic-flaws
- **HackerOne Payment Bypass reports**: https://hackerone.com/hacktivity?queryString=payment
- **Stripe Webhooks documentation**: https://stripe.com/docs/webhooks/signatures

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Hackvertor | HMAC manipulation |
| Turbo Intruder | Race condition testing |
| Param Miner | Hidden parameter discovery |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/10-Test_Payment_Functionality
- OWASP Transaction Authorization CS: https://cheatsheetseries.owasp.org/cheatsheets/Transaction_Authorization_Cheat_Sheet.html
- PCI DSS: https://www.pcisecuritystandards.org/

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V11.1.7 | Application protects against integer overflow. |
| V6.4.1 | Integrity protection on critical operations (payments). |
| V11.1.6 | Application protects against race conditions. |
