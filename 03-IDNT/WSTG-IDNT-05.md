# WSTG-IDNT-05 — Testing for Weak or Unenforced Username Policy

## Cel

Audyt polityki nazw użytkowników: case-insensitivity, denylist zarezerwowanych nazw (admin, root), Unicode confusables (cyrylica `а` vs łaciński `a`), zero-width characters, sequential user IDs (`user001`, `user002`).

> **Test mostly manual**: wymaga próbnych rejestracji + analyzy. Częściowo automatyzowalne (rejestracja zarezerwowanych nazw), ale destruktywne.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Reserved names test**: spróbować zarejestrować `admin`, `root`, `null`, `undefined` — czy aplikacja blokuje?
2. **Case-insensitivity**: zarejestruj `Admin`, czy `admin` traktowane jako duplicate?
3. **Unicode confusables**: zarejestruj `аdmin` (Cyrillic а U+0430), czy aplikacja normalizuje (NFC)?
4. **Whitespace handling**: ` admin`, `admin ` — czy traktowane jako `admin`?
5. **Sequential ID enumeration**: `/api/users/1`, `/api/users/2` — czy IDs są sekwencyjne (przewidywalne)?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Reserved names blocked (admin, root, system, postmaster)
- [ ] Case-insensitive uniqueness (Admin == admin)
- [ ] Trim whitespace before save
- [ ] Unicode normalization (NFC) before compare
- [ ] Cyrillic confusables blocked
- [ ] Zero-width chars blocked
- [ ] RTL override chars blocked
- [ ] Min/max length enforced
- [ ] Allowlist of characters (alphanumeric + `.`, `-`, `_`)
- [ ] User IDs are random UUIDs (nie sequential)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md

### Polityka nazw użytkowników

- **Case-insensitive**: `Admin`, `admin`, `ADMIN` muszą być traktowane jako to samo konto
- Użyj **allowlist znaków**: alfanumeryczne + ograniczone znaki specjalne (`.`, `-`, `_`)
- **Min/max długość**: np. 3-64 znaki — zapobiegaj krótkim i bardzo długim nazwom
- Trimuj białe znaki na początku i końcu — `" admin"` != `"admin"` to błąd
- User ID powinno być **losowe** (UUID) — nie sekwencyjne (user001, user002)

### Zarezerwowane nazwy — denylist

- Blokuj nazwy systemowe: `root`, `admin`, `administrator`, `system`, `null`, `undefined`, `NaN`
- Blokuj nazwy serwisowe: `postmaster`, `webmaster`, `hostmaster`, `abuse`, `noreply`
- Blokuj słowa kluczowe: `true`, `false`, `login`, `register`, `api`, `graphql`
- Uwzględnij warianty case i Unicode confusables

### Email jako identyfikator

- Pozwól użytkownikom używać email jako username, ale **weryfikuj email**
- Umożliw zmianę adresu email **bez zmiany konta** — oddziel identyfikator od emaila
- Waliduj format email: nie akceptuj `test@test@test.com`, `user@.com`
- Uwzględnij aliasy email: `user+tag@gmail.com` — czy to ten sam użytkownik?

### Unicode i znaki specjalne — zagrożenia

- **Unicode confusables**: cyrylica `А` (U+0410) wygląda jak łacińskie `A` (U+0041)
- **Null bytes**: `admin%00` może być traktowane jako `admin` po obcięciu
- **Right-to-left override**: U+202E może zmienić wyświetlanie nazwy
- **Zero-width characters**: U+200B (zero-width space) — niewidoczny ale zmienia unikatowość
- Normalizuj Unicode (NFC) przed porównaniem i zapisem

### Testowanie

- Czy można zarejestrować konto z nazwą istniejącego użytkownika (case variant, Unicode)?
- Czy nazwy systemowe są zablokowane?
- Czy komunikaty błędów ujawniają politykę nazewnictwa?
- Czy schemat nazw wewnętrznych kont jest przewidywalny (sekwencyjne ID)?
- Czy można wstawić znaki specjalne (spacje, null bytes, Unicode) w username?

## Pentesterskie deep dive

### Mniej znane techniki

- **Homograph account hijack**: rejestracja `paypaӏ.com` (where `ӏ` is Cyrillic U+04CF, looks like `l`) - phishing pivot.
- **Email punycode confusion**: `user@xn--paypl-pjk.com` (punycode) renders as similar domain.
- **Username case insensitivity bypass**: aplikacja traktuje `Admin` ≠ `admin` w DB ale auth filter robi case-insensitive lookup → możliwy collision.
- **NFKC vs NFC normalization**: aplikacja może używać NFC (default) ale baza danych NFKC → ścieżka do collision.
- **Zero-width injection**: `adm​in` (with zero-width space U+200B between m and i) - looks like `admin` but unique entry.
- **Sequential user ID enumeration**: `/api/users/1` accessible → loop attacker iterates through all accounts.

### Common pitfalls

- **Trim only leading whitespace**: aplikacje trim leading spaces ale nie trailing → `admin` and `admin ` different accounts.
- **Email aliases not normalized**: `User@Gmail.Com` vs `user@gmail.com` - Gmail treats same but app may not.
- **Unicode reserved names**: `àdmin` (with à) is not blocked even though "admin" is.

### Świeżynki z research

- **Unicode security**: https://www.unicode.org/reports/tr36/
- **HackTricks Username**: https://book.hacktricks.xyz/pentesting-web/username-related-attacks
- **PayloadsAllTheThings Unicode**: https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Unicode%20Injection

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Hackvertor | Unicode normalization testing | [GitHub](https://github.com/PortSwigger/hackvertor) |
| Param Miner | Hidden parameter discovery | [GitHub](https://github.com/PortSwigger/param-miner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/03-Identity_Management_Testing/05-Testing_for_Weak_or_Unenforced_Username_Policy
- OWASP Authentication CS: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- HackTricks Username Attacks: https://book.hacktricks.xyz/pentesting-web/username-related-attacks
- Unicode Security TR36: https://www.unicode.org/reports/tr36/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.1.9 | Password Security (L1) | Username/email truncated, normalized. |
| V3.2.3 | Session (L1) | Session token entropy ≥ 64 bits. |
