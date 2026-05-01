# WSTG-SESS-01 — Testing for Session Management Schema

## Cel

Audyt schemy zarządzania sesjami: entropia Session ID (≥64 bits), CSPRNG generator, brak meaningful data w ID, custom name (nie default JSESSIONID/PHPSESSID), session ID tylko w cookies (nie w URL).

> **Test mostly manual**: wymaga statystycznej analizy Session ID + reverse engineering pattern.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Capture session IDs**: 100+ login sessions → analiza patterns (Burp Sequencer).
2. **Entropy analysis**: czy ID jest random vs predictable (sequential, timestamp-based)?
3. **Decoder check**: czy ID zawiera Base64-decoded user data?
4. **Default name**: PHPSESSID/JSESSIONID/ASP.NET_SessionId = framework fingerprint.
5. **URL transmission**: czy aplikacja akceptuje session w URL parameters?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Session ID entropy ≥ 64 bits (Burp Sequencer FIPS test)
- [ ] CSPRNG generator (nie Math.random/timestamp)
- [ ] Session ID jest meaningless (Base64 decode = noise)
- [ ] Custom session name (nie default framework)
- [ ] Cookie tylko (nie URL parameters)
- [ ] Server odrzuca unknown session ID
- [ ] Session regeneration po login
- [ ] HSTS dla HTTPS-only (cross WSTG-CONF-07)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Właściwości Session ID

- **Entropia**: Session ID musi mieć minimum **64 bitów entropii** — użyj CSPRNG (Cryptographically Secure PRNG)
- **Długość**: min 16 znaków hex (64 bitów entropii) — przy base64 odpowiednio mniej znaków
- **Zawartość**: Session ID musi być bezznaczeniowy (meaningless) — NIE może zawierać danych użytkownika, PII, ani logiki biznesowej
- **Nazwa**: zmień domyślną nazwę sesji frameworka (PHPSESSID, JSESSIONID, ASP.NET_SessionId) na generyczną np. `id` — utrudnia fingerprinting
- Jeśli część ID jest stała/przewidywalna — efektywna entropia jest zmniejszona, wydłuż ID

### Implementacja zarządzania sesjami

- Używaj **wbudowanego zarządzania sesjami frameworka** (J2EE, ASP.NET, PHP) — nie twórz własnego
- Preferuj **cookies** jako mechanizm wymiany Session ID — URL parameters ujawniają ID w logach, Referer, historii przeglądarki
- Jeśli użytkownik przesyła Session ID innym mechanizmem niż cookie (np. URL param) — **odrzuć go** (obrona przed session fixation)

### Cookie Attributes

- Patrz WSTG-SESS-02 dla pełnej dokumentacji

## Pentesterskie deep dive

### Mniej znane techniki

- **Burp Sequencer FIPS analysis**: 20000+ tokens → statystyczna ocena entropii (FIPS 140-2 tests).
- **Session ID base64 decode**: jeśli zawiera username/timestamp = predictable.
- **Time-based prediction**: PHP `rand()` seeded from time → atakujący przewiduje session IDs z timestamp.

### Świeżynki z research

- **PortSwigger Session labs**: https://portswigger.net/web-security
- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Sequencer (built-in) | Token entropy analysis |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/01-Testing_for_Session_Management_Schema
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.2.3 | Session token entropy ≥ 64 bits. |
| V3.2.4 | Session token created using approved CSPRNG. |
| V3.2.2 | Session ID never disclosed in URL/error/log. |
