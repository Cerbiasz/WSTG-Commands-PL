# WSTG-BUSL-01 — Test Business Logic Data Validation

## Cel

Wykrycie błędów walidacji danych w kontekście biznesowym: ujemne ceny, ilości większe niż stan magazynu, daty z przeszłości w polach future-only, currency manipulation, integer overflow.

> **Test manual-only**: business logic z definicji wymaga rozumienia kontekstu biznesowego.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Map business rules**: rozmowa z dev/PM o oczekiwanym behavior per field.
2. **Boundary testing**: dla każdego numeric field - test ujemnych, zerowych, ogromnych wartości, zmiennoprzecinkowych w int field.
3. **Type confusion**: integer w string field, array zamiast string.
4. **Workflow specific**: w e-commerce - cena 0.01 dla high-value item, ujemna ilość daje refund.
5. **Currency / locale**: zmień waluta z EUR na zimbabwe dollar?

### Co MUSI być sprawdzone (12 punktów)

- [ ] Ujemne ceny / ilości (refund attack)
- [ ] Cena 0 / 0.01 dla expensive items
- [ ] Integer overflow (np. 9999999999 × 1)
- [ ] Decimal precision (0.001 cents = effective free)
- [ ] Currency manipulation
- [ ] Date validation (past/future)
- [ ] Email format edge cases (`a@b`, `user@.com`)
- [ ] Phone number internationalisation
- [ ] Address fields (PII length limits)
- [ ] Quantity > inventory
- [ ] Discount > price (negative total)
- [ ] Tax calculation manipulation

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, Abuse_Case_Cheat_Sheet.md

### Walidacja danych — hierarchia

- **Syntactic validation**: format danych — typ, długość, zakres, encoding, regex
- **Semantic validation**: znaczenie biznesowe — czy cena jest dodatnia, czy ilość jest sensowna
- **OBIE** warstwy są wymagane — syntaktyczna walidacja nie wyłapie logicznych błędów

### Server-side validation — KLUCZOWE

- Walidacja kliencka (JavaScript) to **UX** — łatwa do ominięcia (Burp, curl, DevTools)
- Walidacja SERVER-SIDE jest **obowiązkowa** — jedyna skuteczna obrona
- Każdy parametr musi być walidowany: typ, długość, zakres, format, dozwolone wartości

### Allowlist vs Denylist

- **Allowlist** (PREFEROWANE): jawnie określ co jest dozwolone — `[a-zA-Z0-9]`
- **Denylist** (SŁABE): próbuj zablokować co jest niebezpieczne — atakujący znajdzie obejście
- Używaj regex do walidacji formatów: email, telefon, ZIP code, daty

### Reguły biznesowe do walidacji

- Cena: musi być **dodatnia**, nie może być **zerowa** (chyba że dozwolone)
- Ilość: minimum 1, maximum sensowne (np. 1000 dla retail)
- Stan magazynu: ilość zamówiona <= stan magazynu
- Data: w przeszłości/przyszłości zależnie od pola (urodzenia vs wygaśnięcia)
- Status: tylko dozwolone wartości (`pending`, `paid`, `shipped`)

## Pentesterskie deep dive

### Mniej znane techniki

- **Integer overflow w JavaScript Number**: `Number.MAX_SAFE_INTEGER + 1 = 9007199254740992` - niektóre frameworki returnują wrong values.
- **Floating point precision**: `0.1 + 0.2 = 0.30000000000000004` - subtraction może dać 0 lub negative.
- **Locale-aware parsing**: `1,234.56` (US) vs `1.234,56` (EU) - aplikacja może parse różnie per locale.
- **String → number coercion**: PHP `"1abc" == 1` - input "1abc" passes type check.

### Common pitfalls

- **Frontend validation only**: bypass via Burp.
- **Server-side parseInt without bounds**: accepts `Infinity` or `NaN` w niektórych frameworks.

### Świeżynki z research

- **PortSwigger Business Logic labs**: https://portswigger.net/web-security/logic-flaws
- **HackTricks Business Logic**: https://book.hacktricks.xyz/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Param Miner | Hidden parameter discovery |
| Logger++ | State change tracking |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/01-Test_Business_Logic_Data_Validation
- OWASP Input Validation CS: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- PortSwigger Business Logic: https://portswigger.net/web-security/logic-flaws

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V5.1.3 | Input validated using positive validation. |
| V5.1.5 | URL redirects only allow whitelisted destinations. |
