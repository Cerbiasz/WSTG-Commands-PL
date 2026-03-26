# WSTG-ATHN-07 — Testing for Weak Authentication Methods

## Cele

- Przetestowac odpornosc na brute force
- Ocenic polityki hasel
- Sprawdzic sile mechanizmow uwierzytelniania

## KOMENDY

### Test polityki hasel - proby rejestracji ze slabymi haslami

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"weaktest1","password":"123","email":"w1@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"weaktest2","password":"password","email":"w2@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"weaktest3","password":"aaaa","email":"w3@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"weaktest4","password":"12345678","email":"w4@test.com"}' -v
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"weaktest5","password":"Password1","email":"w5@test.com"}' -v

```

### Test zmiany hasla na slabe

```bash
curl -s -X POST "https://TARGET/api/change-password" -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" -d '{"old_password":"StrongPass@1","new_password":"123"}' -v

```

### Sprawdzenie czy haslo moze byc takie samo jak username

```bash
curl -s -X POST "https://TARGET/api/register" -H "Content-Type: application/json" -d '{"username":"testuser","password":"testuser","email":"same@test.com"}' -v

```

### Patator - brute force HTTP POST

```bash
patator http_fuzz url="https://TARGET/api/login" method=POST body='{"username":"admin","password":"FILE0"}' header="Content-Type: application/json" 0=Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt -x ignore:code=401

```

### Sprawdzenie HTTP Basic Auth

```bash
curl -s -v "https://TARGET/" -u "admin:admin"
curl -s -v "https://TARGET/" -u "admin:password"

```

### Sprawdzenie Digest Auth

```bash
curl -s -v --digest -u "admin:admin" "https://TARGET/"

```

## KOMENDY Z WORDLISTAMI

### Hydra brute force HTTP POST form

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Hydra z darkweb top 10000

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/darkweb2017_top-10000.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Hydra z xato-net milion hasel

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/xato-net-10-million-passwords-1000000.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid" -t 4

```

### Hydra z leaked databases

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Leaked-Databases/rockyou-75.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Medusa brute force

```bash
medusa -h TARGET -u admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt -M http -m DIR:/api/login

```

### ffuf brute force

```bash
ffuf -w Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt:PASS -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"PASS"}' -fc 401

```

### ffuf z darkweb top 1000

```bash
ffuf -w Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/darkweb2017_top-1000.txt:PASS -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"PASS"}' -fc 401

```

### Hydra z Pwdb top 100000

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/Pwdb_top-100000.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Hydra SSH brute force

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt TARGET ssh

```

### Hydra z leaked databases - phpbb

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Leaked-Databases/phpbb-cleaned-up.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Password spray z 200 najpopularniejszych hasel

```bash
hydra -L Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/2025-199_most_used_passwords.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### John the Ripper (offline hash cracking)

```bash
john --wordlist=Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt hashes.txt

```

### Hashcat (offline hash cracking)

```bash
hashcat -m 0 -a 0 hashes.txt Desktop/WSTG/SecLists-master/Passwords/Leaked-Databases/rockyou-75.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przetestuj polityki hasel: minimalna dlugosc, wymagane znaki, zlozonosc
2. Sprawdz czy aplikacja blokuje najczesciej uzywane hasla
3. W Burp Intruder skonfiguruj atak brute force i monitoruj odpowiedzi
4. Sprawdz czy istnieje rate limiting na endpoincie logowania
5. Przetestuj czy haslo moze byc takie samo jak username lub email
6. Sprawdz czy aplikacja wymaga silnego hasla przy zmianie
7. Przetestuj HTTP Basic/Digest authentication jesli jest uzywane
8. Sprawdz czy tokeny sesji sa wystarczajaco losowe i dlugie


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Password_Storage_Cheat_Sheet.md

### Polityka sily hasla (NIST SP800-63B)

- **Minimalna dlugosc**: 8 znakow z MFA, 15 znakow bez MFA
- **Maksymalna dlugosc**: minimum **64 znaki** — pozwol na passphrases
- **Nie obcinaj hasla cicho** (silent truncation) — uzytkownik musi wiedziec o limitach
- Pozwol na **WSZYSTKIE znaki** wlacznie z Unicode i spacjami — brak regul kompozycji (duze/male/cyfry/specjalne)
- NIST **ODRADZA** wymuszanie okresowej zmiany hasel — zmiana TYLKO po wycieku
- Wlacz **password strength meter** (np. zxcvbn-ts) — pomaga uzytkownikowi stworzyc silne haslo

### Blokowanie slabych hasel

- Sprawdzaj hasla przeciw **bazom wycieknietych hasel**: [HaveIBeenPwned Passwords API](https://haveibeenpwned.com/API/v3#PwnedPasswords)
- Blokuj **top-N najpopularniejszych hasel** — listy dostepne w SecLists
- Blokuj hasla identyczne z username, email, nazwa aplikacji

### Przechowywanie hasel — algorytmy hashowania

- **Argon2id** (REKOMENDOWANY): min 19 MiB pamieci, 2 iteracje, 1 stopien rownolegloscí
- **scrypt**: min CPU/memory cost 2^17, block size 8 (1024 bytes), parallelization 1
- **bcrypt**: work factor 10+, limit hasla 72 bajty
- **PBKDF2** (jesli FIPS-140 wymagany): work factor 600000+, HMAC-SHA-256
- **NIGDY**: plaintext, MD5, SHA1, SHA256 (bez key stretching)

### Salting i Peppering

- **Salt**: unikalny, losowy string per haslo — nowoczesne algorytmy (Argon2id, bcrypt) generuja go automatycznie
- **Pepper**: wspolny sekret NIE przechowywany z hashami — dodatkowa warstwa obrony
  - Pre-hashing: pepper dodany do hasla PRZED hashowaniem
  - Post-hashing: HMAC na wyniku hashowania (HMAC-SHA256 z pepper jako klucz)
  - Pepper przechowuj w secrets vault lub HSM — NIE w bazie danych

### Work Factor

- Obliczenie hashu powinno trwac **ponizej 1 sekundy** — balans miedzy bezpieczenstwem a wydajnoscia
- Periodycznie zwiekszaj work factor w miare rosnacej mocy hardware
- Re-hashuj hasla przy nastepnym logowaniu uzytkownika z nowym work factorem

### Porownywanie haszy

- Uzywaj **constant-time comparison** — obrona przed timing attacks
- PHP: `password_verify()`, Python: `hmac.compare_digest()`
- Ustaw max input length — obrona przed DoS przez bardzo dlugie hasla

### Zmiana hasla

- Wymagaj aktywnej sesji + weryfikacji aktualnego hasla
- Obrona przed scenariuszem: uzytkownik zapominal sie wylogowac na publicznym komputerze

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.2.1 | Password Security | Verify that user set passwords are at least 8 characters in length although a minimum of 15 characters is strongly recommended. |
| V6.2.4 | Password Security | Verify that passwords submitted during account registration or password change are checked against an available set of, at least, the top 3000 passwords which match the application's password policy, e.g. minimum length. |
| V6.2.5 | Password Security | Verify that passwords of any composition can be used, without rules limiting the type of characters permitted. There must be no requirement for a minimum number of upper or lower case characters, numbers, or special characters. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.2.9 | Password Security | Verify that passwords of at least 64 characters are permitted. |
| V6.2.10 | Password Security | Verify that a user's password stays valid until it is discovered to be compromised or the user rotates it. The application must not require periodic credential rotation. |
| V6.2.11 | Password Security | Verify that the documented list of context specific words is used to prevent easy to guess passwords being created. |
| V6.2.12 | Password Security | Verify that passwords submitted during account registration or password changes are checked against a set of breached passwords. |
