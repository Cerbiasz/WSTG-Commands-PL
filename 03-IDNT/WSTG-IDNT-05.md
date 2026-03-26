# WSTG-IDNT-05 — Testing for Weak or Unenforced Username Policy

## Cele

- Okreslenie czy konsekwentna struktura nazw kont czyni aplikacje podatna
- Sprawdzenie polityki nazw uzytkownikow (dlugosc, znaki, format)
- Testowanie wymuszania regul nazewnictwa

## KOMENDY

### Rejestracja z bardzo krotka nazwa

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"a","password":"Test@1234","email":"short@test.com"}' -v

```

### Rejestracja z nazwa numeryczna

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"12345","password":"Test@1234","email":"num@test.com"}' -v

```

### Rejestracja ze znakami specjalnymi

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"user@#$%","password":"Test@1234","email":"special@test.com"}' -v

```

### Rejestracja ze spacjami

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"user name","password":"Test@1234","email":"space@test.com"}' -v

```

### Rejestracja z Unicode/emoji

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"\u0410\u0434\u043c\u0438\u043d","password":"Test@1234","email":"unicode@test.com"}' -v

```

### Rejestracja z nazwami systemowymi

```bash
for name in root admin administrator system null undefined NaN true false; do echo "--- $name ---"; curl -s -o /dev/null -w "%{http_code}" -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d "{\"username\":\"$name\",\"password\":\"Test@1234\",\"email\":\"$name@test.com\"}"; echo; done

```

### Testowanie case sensitivity

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"TestUser","password":"Test@1234","email":"case1@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"testuser","password":"Test@1234","email":"case2@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"TESTUSER","password":"Test@1234","email":"case3@test.com"}' -v

```

### Rejestracja z bialymi znakami na poczatku/koncu

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":" admin","password":"Test@1234","email":"lead@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"admin ","password":"Test@1234","email":"trail@test.com"}' -v

```

### Testowanie maksymalnej dlugosci nazwy

```bash
python3 -c "print('A'*256)" | xargs -I{} curl -s -o /dev/null -w "%{http_code}" -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"{}","password":"Test@1234","email":"long@test.com"}'

```

### Testowanie formatu email jako username

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"user@domain.com","password":"Test@1234","email":"email@test.com"}' -v

```

### Testowanie null bytes

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"admin%00","password":"Test@1234","email":"null@test.com"}' -v

```

## KOMENDY Z WORDLISTAMI

### Testowanie przewidywalnych wzorcow nazw uzytkownikow

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fs BASELINE_SIZE

```

### Testowanie z lista domyslnych nazw uzytkownikow

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/cirt-default-usernames.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fs BASELINE_SIZE

```

### Testowanie z lista popularnych imion

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/Names/names.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fs BASELINE_SIZE

```

### Testowanie z lista SAP default

```bash
ffuf -w Desktop/WSTG/SecLists-master/Usernames/sap-default-usernames.txt:USER -u "https://TARGET/api/register" -X POST -H "Content-Type: application/json" -d '{"username":"USER","password":"Test@1234","email":"USER@test.com"}' -mc all -fs BASELINE_SIZE

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przetestuj formularz rejestracji z roznymi formatami nazw uzytkownikow
2. Sprawdz czy aplikacja wymusza minimalna/maksymalna dlugosc nazwy
3. Zweryfikuj czy znaki specjalne sa prawidlowo filtrowane
4. Sprawdz czy istnieje blacklista zarezerwowanych nazw (admin, root, system)
5. W Burp Repeater przetestuj rozne warianty nazw (ze spacjami, null bytes, Unicode)
6. Sprawdz czy polityka nazw jest spowjna miedzy GUI a API
7. Przeanalizuj komunikaty bledow pod katem ujawniania polityki nazewnictwa
8. Sprawdz czy mozna odgadnac schemat nadawania nazw wewnetrznych kont (np. user001, user002)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md

### Polityka nazw uzytkownikow

- **Case-insensitive**: `Admin`, `admin`, `ADMIN` musza byc traktowane jako to samo konto
- Uzyj **allowlist znakow**: alfanumeryczne + ograniczone znaki specjalne (`.`, `-`, `_`)
- **Min/max dlugosc**: np. 3-64 znaki — zapobiegaj krotkim i bardzo dlugim nazwom
- Trimuj biale znaki na poczatku i koncu — `" admin"` != `"admin"` to blad
- User ID powinno byc **losowe** (UUID) — nie sekwencyjne (user001, user002)

### Zarezerwowane nazwy — denylist

- Blokuj nazwy systemowe: `root`, `admin`, `administrator`, `system`, `null`, `undefined`, `NaN`
- Blokuj nazwy serwisowe: `postmaster`, `webmaster`, `hostmaster`, `abuse`, `noreply`
- Blokuj slowa kluczowe: `true`, `false`, `login`, `register`, `api`, `graphql`
- Uwzglednij warianty case i Unicode confusables

### Email jako identyfikator

- Pozwol uzytkownikom uzywac email jako username, ale **weryfikuj email**
- Umozliw zmiane adresu email **bez zmiany konta** — oddziel identyfikator od emaila
- Waliduj format email: nie akceptuj `test@test@test.com`, `user@.com`
- Uwzglednij aliasy email: `user+tag@gmail.com` — czy to ten sam uzytkownik?

### Unicode i znaki specjalne — zagrożenia

- **Unicode confusables**: cyrylica `А` (U+0410) wyglada jak lacinskie `A` (U+0041)
- **Null bytes**: `admin%00` moze byc traktowane jako `admin` po obcieciu
- **Right-to-left override**: U+202E moze zmienic wyswietlanie nazwy
- **Zero-width characters**: U+200B (zero-width space) — niewidoczny ale zmienia unikatowość
- Normalizuj Unicode (NFC) przed porownaniem i zapisem

### Testowanie

- Czy mozna zarejestrowac konto z nazwa istniejacego uzytkownika (case variant, Unicode)?
- Czy nazwy systemowe sa zablokowane?
- Czy komunikaty bledow ujawniaja politykę nazewnictwa?
- Czy schemat nazw wewnetrznych kont jest przewidywalny (sekwencyjne ID)?
- Czy mozna wstawic znaki specjalne (spacje, null bytes, Unicode) w username?

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.2.5 | Password Security | Verify that passwords of any composition can be used, without rules limiting the type of characters permitted. There must be no requirement for a minimum number of upper or lower case characters, numbers, or special characters. |
| V6.2.1 | Password Security | Verify that user set passwords are at least 8 characters in length although a minimum of 15 characters is strongly recommended. |
