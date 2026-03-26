# WSTG-IDNT-04 — Testing for Account Enumeration and Guessable User Account

## Cele

- Enumeracja uzytkownikow na podstawie analizy odpowiedzi serwera
- Identyfikacja przewidywalnych nazw kont
- Wykrycie roznic w odpowiedziach dla istniejacych i nieistniejacych uzytkownikow

## KOMENDY

### Analiza odpowiedzi logowania dla istniejacego i nieistniejacego uzytkownika

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrongpass"}' -v 2>&1
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"nieistniejacyuser12345","password":"wrongpass"}' -v 2>&1

```

### Porownanie czasow odpowiedzi (timing attack)

```bash
for user in admin root test nieistnieje99; do echo -n "$user: "; curl -s -o /dev/null -w "%{time_total}" -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d "{\"username\":\"$user\",\"password\":\"wrongpass\"}"; echo; done

```

### Enumeracja przez endpoint resetowania hasla

```bash
curl -s -X POST "https://TARGET/api/forgot-password" -H "Content-Type: application/json" -d '{"email":"admin@TARGET"}' -v
curl -s -X POST "https://TARGET/api/forgot-password" -H "Content-Type: application/json" -d '{"email":"nieistnieje@TARGET"}' -v

```

### Enumeracja przez endpoint rejestracji

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"admin","password":"Test@1234","email":"enum@test.com"}' -v

```

### Enumeracja przez roznice w kodach HTTP

```bash
curl -s -o /dev/null -w "%{http_code}" -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}'
curl -s -o /dev/null -w "%{http_code}" -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"fakeuser999","password":"wrong"}'

```

### Enumeracja przez endpoint profilu uzytkownika

```bash
for id in $(seq 1 50); do echo -n "ID $id: "; curl -s -o /dev/null -w "%{http_code}" "https://TARGET/api/users/$id"; echo; done

```

### Enumeracja przez endpoint publicznych profili

```bash
curl -s "https://TARGET/user/admin" -v
curl -s "https://TARGET/user/fakeuser999" -v

```

## KOMENDY Z WORDLISTAMI

### ffuf enumeracja uzytkownikow przez formularz logowania

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt:USER -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"invalid"}' -mc all -fs BASELINE_SIZE

```

### ffuf pelna lista uzytkownikow

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/xato-net-10-million-usernames.txt:USER -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"invalid"}' -mc all -fs BASELINE_SIZE -t 10

```

### ffuf enumeracja przez endpoint rejestracji

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/cirt-default-usernames.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fs BASELINE_SIZE

```

### ffuf enumeracja przez reset hasla

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/Names/names.txt:USER -u "https://TARGET/api/forgot-password" -X POST -H "Content-Type: application/json" -d '{"email":"USER@TARGET"}' -mc all -fs BASELINE_SIZE

```

### wfuzz enumeracja uzytkownikow

```bash
wfuzz -w Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt -d '{"username":"FUZZ","password":"invalid"}' -H "Content-Type: application/json" --hh BASELINE_SIZE "https://TARGET/api/login"

```

### hydra enumeracja (sprawdzenie odpowiedzi)

```bash
hydra -L Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt -p invalid TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid username or password"

```

### Enumeracja z lista honeypot

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/Honeypot-Captures/multiplesources-users-fabian-fingerle.de.txt:USER -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"invalid"}' -mc all -fs BASELINE_SIZE -t 10

```

### Enumeracja z Bug-Bounty-Wordlists

```bash
ffuf -w Desktop/WSTG/Bug-Bounty-Wordlists-main/user_field_names.txt:USER -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"invalid"}' -mc all -fs BASELINE_SIZE

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Porownaj dokladnie odpowiedzi serwera dla istniejacych vs nieistniejacych uzytkownikow
2. Sprawdz roznice w: kodzie HTTP, dlugosci odpowiedzi, tresci komunikatu bledu, czasie odpowiedzi
3. W Burp Intruder uzyj listy uzytkownikow i sortuj wyniki po dlugosci odpowiedzi
4. Sprawdz naglowki odpowiedzi pod katem roznic (Set-Cookie, X-headers)
5. Przetestuj enumeracje przez rozne endpointy: login, register, forgot-password, profile
6. Sprawdz czy API GraphQL ujawnia uzytkownikow (introspection)
7. Przeanalizuj kod JavaScript pod katem endpointow sprawdzajacych dostepnosc nazwy uzytkownika
8. Sprawdz sitemapy, robots.txt i publiczne profile pod katem listy uzytkownikow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md

### Enumeracja uzytkownikow — dlaczego jest groźna

- Atakujacy uzyskuje liste istniejacych kont → moze przeprowadzic: brute force, credential stuffing, phishing
- Enumeracja przez: login, rejestracja, forgot password, publiczne profile, API
- Kazdy endpoint ktory odpowiada INACZEJ dla istniejacego vs nieistniejacego konta ujawnia informacje

### Obrona — generyczne komunikaty

- **Identyczny komunikat** dla istniejacego i nieistniejacego konta: "Invalid username or password"
- **Identyczny kod HTTP** — np. 200 z JSON body (nie 404 vs 200)
- **Identyczny czas odpowiedzi** — wykonaj hash hasla NAWET jesli konto nie istnieje (timing attack)
- **Identyczna dlugosc odpowiedzi** — unikaj roznic ktore mozna wykryc w Burp Intruder

### Typowe wektory enumeracji

- **Login**: "User not found" vs "Wrong password" — rozne komunikaty
- **Rejestracja**: "Username already taken" — ujawnia istniejace konta
  - Obrona: "If this email is not registered, we'll send a confirmation"
- **Forgot password**: "Email not found" vs "Reset link sent" — rozne komunikaty
  - Obrona: ZAWSZE "If an account exists, a reset link has been sent"
- **Timing**: sprawdzanie hasla trwa dluzej niz sprawdzanie czy user istnieje
  - Obrona: constant-time response — hashuj dummy password jesli user nie istnieje

### Dodatkowe obrony

- **Rate limiting**: ogranicz proby logowania per IP/konto/globalnie
- **CAPTCHA**: po N nieudanych probach
- **Account lockout**: po N probach (z auto-odblokowaniem)
- **Monitoring**: alertuj na masowe proby enumeracji (wiele roznych username z jednego IP)
- **GraphQL introspection**: wylacz na produkcji — moze ujawniac typy i pola uzytkownikow

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.3.1 | General Authentication Security | Verify that controls to prevent attacks such as credential stuffing and password brute force are implemented according to the application's security documentation. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.3.8 | General Authentication Security | Verify that valid users cannot be deduced from failed authentication challenges, such as by basing on error messages, HTTP response codes, or different response times. Registration and forgot password functionality must also have this protection. |
