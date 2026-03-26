# WSTG-IDNT-02 — Test User Registration Process

## Cele

- Zweryfikowac wymagania tozsamosci przy rejestracji
- Sprawdzic walidacje procesu rejestracji
- Przetestowac odpornosc na duplikaty i zlosliwe dane wejsciowe

## KOMENDY

### Rejestracja nowego uzytkownika - standardowy test

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"testuser1","password":"Test@1234","email":"test1@example.com"}' -v

```

### Proba rejestracji z duplikatem nazwy uzytkownika

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"admin","password":"Test@1234","email":"test2@example.com"}' -v

```

### Proba rejestracji z duplikatem emaila

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"testuser2","password":"Test@1234","email":"admin@TARGET"}' -v

```

### SQL Injection w polu rejestracji

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"test'\'' OR 1=1--","password":"Test@1234","email":"sqli@test.com"}' -v

```

### XSS w polu nazwy uzytkownika

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"<script>alert(1)</script>","password":"Test@1234","email":"xss@test.com"}' -v

```

### Rejestracja z bardzo dluga nazwa uzytkownika (buffer overflow test)

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA","password":"Test@1234","email":"overflow@test.com"}' -v

```

### Rejestracja z pustymi polami

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"","password":"","email":""}' -v

```

### Rejestracja ze slabym haslem

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"weakuser","password":"123","email":"weak@test.com"}' -v

```

### Rejestracja bez wymaganego pola

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"nopass"}' -v

```

### Rejestracja z dodatkowym polem role

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"roletest","password":"Test@1234","email":"role@test.com","role":"admin"}' -v

```

### Proba masowej rejestracji (rate limiting test)

```bash
for i in $(seq 1 20); do curl -s -o /dev/null -w "Attempt $i: %{http_code}\n" -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d "{\"username\":\"massuser$i\",\"password\":\"Test@1234\",\"email\":\"mass$i@test.com\"}"; done

```

### Testowanie case sensitivity nazwy uzytkownika

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"Admin","password":"Test@1234","email":"case@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"ADMIN","password":"Test@1234","email":"case2@test.com"}' -v

```

### Rejestracja ze znakami specjalnymi w emailu

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"specialemail","password":"Test@1234","email":"test+admin@test.com"}' -v

```

## KOMENDY Z WORDLISTAMI

### Enumeracja istniejacych uzytkownikow przez rejestracje (ffuf)

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fc 200

```

### Enumeracja uzytkownikow - pelna lista

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/xato-net-10-million-usernames.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fc 200 -t 10

```

### Enumeracja uzytkownikow - lista cirt default

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/cirt-default-usernames.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fc 200

```

### Enumeracja z lista imion

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/Names/names.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fc 200

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zarejestruj nowe konto i przeanalizuj caly przeplyw w Burp Suite (requesty/response)
2. Sprawdz czy formularz rejestracji posiada ochrone CAPTCHA lub rate limiting
3. W Burp Repeater przetestuj manipulacje parametrow rejestracji (dodanie pola isAdmin, role)
4. Sprawdz czy wiadomosc bledu przy duplikacie ujawnia informacje o istniejacych uzytkownikach
5. Przetestuj rejestracje z tymczasowymi adresami email (mailinator, guerrillamail)
6. Sprawdz czy weryfikacja email jest wymagana do aktywacji konta
7. Przeanalizuj token weryfikacyjny pod katem przewidywalnosci
8. Sprawdz w DevTools czy formularz nie wysyla ukrytych pol


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Proces rejestracji — bezpieczenstwo

- **Weryfikacja email**: wymagaj potwierdzenia adresu email przed aktywacja konta
- Token weryfikacyjny: CSPRNG, jednorazowy, krotki TTL (24h max), hashowany w DB
- **CAPTCHA/rate limiting**: zapobiegaj masowemu tworzeniu kont (bot registration)
- Blokuj tymczasowe adresy email (mailinator, guerrillamail) jesli to wymagane biznesowo
- Ogranicz ilosc rejestracji z jednego IP/sesji

### Walidacja danych rejestracyjnych

- **Username**: case-insensitive, unikalne, allowlist znakow, min/max dlugosc
- **Email**: waliduj format, sprawdz duplikaty (case-insensitive), zweryfikuj MX record
- **Haslo**: min. 8 znakow (z MFA) lub 15 (bez MFA), max 64+, brak ograniczen na typ znakow
- Sprawdzaj haslo na liscie skompromitowanych (HaveIBeenPwned, SecLists)
- **Nie ujawniaj** czy email/username juz istnieje — generyczne komunikaty

### Mass Assignment / Privilege Escalation

- NIE akceptuj pol `role`, `isAdmin`, `is_staff`, `permissions` z danych uzytkownika
- Uzyj allowlist pol akceptowanych przy rejestracji (strong parameters)
- Testuj: dodaj `"role":"admin"`, `"isAdmin":true` do request body
- Sprawdz czy ukryte pola formularza moga byc manipulowane

### Enumeracja uzytkownikow przez rejestracje

- Komunikat "Username already taken" ujawnia istniejacych uzytkownikow
- Uzyj **generycznych komunikatow**: "Jesli email jest dostepny, zostanie wyslany link weryfikacyjny"
- **Timing attack**: porownaj czas odpowiedzi przy istniejacym vs nowym username
- Testuj enumeracje na: rejestracji, logowaniu, forgot password — WSZYSTKIE musza byc spojne

### Injection w polach rejestracji

- Testuj SQLi, XSS, SSTI w polach: username, email, imie, nazwisko
- Sprawdz czy dane sa sanityzowane i walidowane server-side
- Testuj Unicode confusables: `Аdmin` (cyrylica A) vs `Admin` (lacinskie A)
- Null bytes, biale znaki na poczatku/koncu, podwojne spacje

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.4.1 | Authentication Factor Lifecycle and Recovery | Verify that system generated initial passwords or activation codes are securely randomly generated, follow the existing password policy, and expire after a short period of time or after they are initially used. These initial secrets must not be permitted to become the long term password. |
| V2.2.1 | Input Validation | Verify that input is validated to enforce business or functional expectations for that input. This should either use positive validation against an allow list of values, patterns, and ranges, or be based on comparing the input to an expected structure and logical limits according to predefined rules. For L1, this can focus on input which is used to make specific business or security decisions. For L2 and up, this should apply to all input. |
| V2.2.2 | Input Validation | Verify that the application is designed to enforce input validation at a trusted service layer. While client-side validation improves usability and should be encouraged, it must not be relied upon as a security control. |
