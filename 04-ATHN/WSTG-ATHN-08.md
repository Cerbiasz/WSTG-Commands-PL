# WSTG-ATHN-08 — Testing for Weak Security Question Answer

## Cel

Audyt mechanizmu pytań bezpieczeństwa: czy pytania są guessable (data urodzenia, nazwisko panieńskie matki) z OSINT, czy odpowiedzi są case-insensitive trim'owane, czy aplikacja używa pytań jako MFA czy fallback do password reset.

> **Test mostly manual**: NIST 800-63 odradza pytania bezpieczeństwa jako auth factor.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Question quality audit**: czy pytania są specific (NIST OK) czy generic (data ur, ulubiony kolor)?
2. **Answer normalization test**: case-insensitive, trim whitespace - czy `Cat` = `cat ` = `CAT`?
3. **OSINT recoverability**: dla 3 random pytań, ile można znaleźć w 5 min OSINT (LinkedIn/Facebook)?
4. **Brute-force test**: rate limiting na security question → czy bruteforce możliwy?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Aplikacja NIE używa pytań jako primary auth factor
- [ ] Pytania są memorable, consistent, applicable, confidential, specific
- [ ] Brak pytań typu "data urodzenia" (publicly available)
- [ ] Rate limiting na security question endpoint
- [ ] Multiple questions required (nie pojedyncze)
- [ ] Fallback do password reset z proper email link (cross WSTG-ATHN-09)
- [ ] User-defined questions allowed (lepsze niż predefined)
- [ ] OSINT susceptibility minimized

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Choosing_and_Using_Security_Questions_Cheat_Sheet.md

### UWAGA: NIST SP 800-63 — pytania bezpieczeństwa NIE są akceptowalnym czynnikiem uwierzytelniania

- NIST **odradza** używanie pytań bezpieczeństwa jako mechanizmu uwierzytelniania
- Badania Microsoft (2009) i Google (2015) wykazały słabą skuteczność pytań bezpieczeństwa
- Jeśli już musisz używać — traktuj jako **dodatkowy** czynnik, NIGDY jako jedyny

### Cechy dobrych pytań bezpieczeństwa

- **Memorable**: użytkownik musi pamiętać odpowiedź po latach
- **Consistent**: odpowiedź NIE może się zmieniać w czasie (NIE: ulubiony film, kolor)
- **Applicable**: każdy użytkownik musi móc odpowiedzieć
- **Confidential**: odpowiedź musi być trudna do uzyskania przez atakującego (NIE: data urodzenia)
- **Specific**: odpowiedź musi być jednoznaczna

### Złe pytania (UNIKAJ)

| Pytanie | Problem |
|---------|---------|
| Data urodzenia | Łatwo dostępna (social media, publiczne rejestry) |
| Ulubiony film/kolor | Zmienia się w czasie |
| Nazwisko panienskie matki | Łatwo do odnalezienia (social media, genealogia) |
| Pierwszy zwierzak | Często pamiętane przez przyjaciół, social media posty |
| Nazwa szkoły | LinkedIn, biografia |

### Dobre pytania (preferuj)

- "Nazwa pierwszego pluszaka jako dziecko" (specific, memorable, niepubliczny)
- "Imię najlepszego przyjaciela z liceum" (specific)
- "Marka pierwszego samochodu" (specific, hard to find)
- Pozwól użytkownikowi **definiować własne pytania** — często lepsze niż predefiniowane

### Przechowywanie odpowiedzi

- Hashuj odpowiedzi jak hasła (Argon2id/bcrypt)
- Normalizuj input: lowercase, trim whitespace
- NIE przechowuj plaintext

## Pentesterskie deep dive

### Mniej znane techniki

- **Security question OSINT pivot**: 30 minut LinkedIn/Facebook = większość odpowiedzi.
- **Rate limiting bypass via security question**: niektóre apps rate limit login ale nie security question endpoint.
- **Password reset via security question = MFA bypass**: jeśli forgot password używa tylko security question, atakujący z OSINT pomija password.

### Common pitfalls

- **Aplikacja używa security question jako MFA**: weakening of MFA - powinno być TOTP/WebAuthn.
- **Pre-defined dropdown questions**: nawet "what was your first pet" - typowy phishing target.

### Świeżynki z research

- **OWASP Choosing Security Questions CS**: https://cheatsheetseries.owasp.org/cheatsheets/Choosing_and_Using_Security_Questions_Cheat_Sheet.html
- **Google Security Questions Research (2015)**: rzeczywiście public research

## Rozszerzenia Burp Suite

Brak dedykowanych - test manual.

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/08-Testing_for_Weak_Security_Question_Answer
- OWASP Choosing Security Questions CS: https://cheatsheetseries.owasp.org/cheatsheets/Choosing_and_Using_Security_Questions_Cheat_Sheet.html
- NIST SP 800-63: https://pages.nist.gov/800-63-3/

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V6.2.1 | Cryptographic modules fail securely. |
| V2.1.1 | Use of MFA. |
