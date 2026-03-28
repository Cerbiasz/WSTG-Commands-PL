# WSTG-ATHN-09 — Testing for Weak Password Change or Reset Functionalities

## Cele

- Determine whether the password change and reset functionality allows accounts to be compromised

## KOMENDY

### Test reset hasla

```bash
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com"

```

### Sprawdzenie tokenu reset

```bash
# Czy token jest przewidywalny? Czy wygasa? Czy jest jednorazowy?
curl -s "https://TARGET/reset-password?token=TOKEN_VALUE"

```

### Test zmiany hasla bez starego hasla

```bash
curl -X POST "https://TARGET/change-password" -H "Cookie: session=TOKEN" -d "new_password=newpass&confirm_password=newpass"

```

### CSRF na zmiane hasla

```bash
curl -X POST "https://TARGET/change-password" -H "Cookie: session=TOKEN" -d "old_password=old&new_password=new&confirm_password=new"
# Sprawdz czy jest CSRF token

```

### Test predictability tokenu

```bash
# Wygeneruj wiele tokenow i porownaj wzorce
for i in $(seq 1 5); do curl -s -X POST "https://TARGET/forgot-password" -d "email=test${i}@test.com" -v 2>&1 | grep "token\|Location"; done

```

### Host header poisoning na reset

```bash
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com" -H "Host: evil.com"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test logiczny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz caly flow resetu hasla (request -> email -> token -> zmiana)
2. Testuj czy token wygasa po uzyciu
3. Testuj czy token wygasa po czasie
4. Sprawdz czy mozna zmienic haslo innego uzytkownika
5. Testuj Host header injection na endpoint resetu
6. Sprawdz czy stare haslo jest wymagane przy zmianie
7. Testuj CSRF na formularzu zmiany hasla
8. Sprawdz politykę nowego hasła (dlugosc, zlozonosc)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Forgot_Password_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Forgot Password — bezpieczny flow

1. Uzytkownik podaje email/username
2. Serwer zwraca **identyczny komunikat** niezaleznie czy konto istnieje ("If an account exists, a reset link has been sent")
3. **Identyczny czas odpowiedzi** — nie ujawniaj istnienia konta przez timing
4. Token wysylany emailem/SMS (side-channel) — NIGDY w odpowiedzi HTTP
5. Uzytkownik klika link z tokenem → formularz zmiany hasla
6. Po zmianie: redirect na login (NIE automatyczny login) + powiadomienie email

### Tokeny resetowania — wymagania bezpieczenstwa

- Generowane przez **CSPRNG** (SecureRandom, secrets, crypto.randomBytes) — min 128 bit entropii
- **Jednorazowe** — uniewazni po uzyciu
- **Krotki czas waznosci**: 15-60 minut
- **Powiazane z konkretnym uzytkownikiem** w bazie danych
- **Hashowane w bazie** (SHA-256) — nie przechowuj raw token (jak hasla)
- **Rate limiting** na endpoincie — zapobiegaj flood tokenami (email/SMS spam)

### Host Header Injection

- NIE uzywaj `Host` header do budowania URL resetowania — atakujacy moze podmienić
- URL resetowania powinien byc **hardcoded** lub zwalidowany przeciw liście zaufanych domen
- Atak: `Host: evil.com` → email z linkiem `https://evil.com/reset?token=xxx` → atakujacy kradnie token

### Zmiana hasla vs Reset hasla

- **Zmiana hasla**: wymaga aktywnej sesji + podania AKTUALNEGO hasla
- **Reset hasla**: NIE wymaga aktualnego hasla (uzytkownik go nie pamieta) — token jako dowod tozsamosci
- Po resecie: uniewazni WSZYSTKIE aktywne sesje uzytkownika

### Referrer Leakage

- Strona resetowania: ustaw `Referrer-Policy: noreferrer` — token z URL nie wycieknie do stron zewnetrznych
- Nie umieszczaj linkow zewnetrznych na stronie resetowania hasla

### Dodatkowe metody odzyskiwania

- **PIN przez SMS** (6-12 cyfr): OTP wysylany SMS-em + ograniczona sesja tylko do zmiany hasla
- **Security questions**: TYLKO jako dodatkowy czynnik, NIE jako jedyny mechanizm
- **Offline methods**: pre-generated recovery codes (np. 10 jednorazowych kodow przy setup MFA)
- Uzytkownik MUSI miec sposob na odzyskanie konta nawet jesli straci dostep do MFA

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.2.2 | Password Security | Verify that users can change their password. |
| V6.2.3 | Password Security | Verify that password change functionality requires the user's current and new password. |
| V6.2.8 | Password Security | Verify that the application verifies the user's password exactly as received from the user, without any modifications such as truncation or case transformation. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.4.3 | Authentication Factor Lifecycle and Recovery | Verify that a secure process for resetting a forgotten password is implemented, that does not bypass any enabled multi-factor authentication mechanisms. |


---

## HackTricks Tips

### Token Leakage

- **Referer**: po kliknięciu reset link → nawiguj do third-party → token w `Referer` header
- **API response**: sprawdź JSON body na `resetToken`
- **Wayback/gau**: szukaj wcześniej wydanych reset links

### Host Header Poisoning

Inject `Host: attacker.com` lub `X-Forwarded-Host: attacker.com` → ofiara dostaje reset link na domenę atakującego

### Email Parameter Manipulation

```
email=victim@mail.com&email=attacker@mail.com
email=victim@mail.com%0ACc:attacker@mail.com
{"email":["victim@mail.com","attacker@mail.com"]}
```

### Token Weaknesses

- Analizuj entropię z **Burp Sequencer**; szukaj tokenów opartych na timestamp/userID/email
- **UUID v1**: `guidtool` do prediction/generation
- Test czy expired tokens nadal działają
- Test czy twój token działa dla emaila ofiary (not session-bound)

### Username Collision

Register `"admin "` (ze spacją) → reset → token idzie na twój email → reset konta "admin"
