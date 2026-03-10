# WSTG-ATHN-02 — Testing for Default Credentials

## Cele

- Okreslenie czy aplikacja posiada domyslne hasla
- Przetestowanie znanych domyslnych kombinacji login/haslo
- Sprawdzenie kont serwisowych i administracyjnych

## KOMENDY

### Proba logowania z domyslnymi credentials

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"admin"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"password"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"root","password":"root"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"test","password":"test"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"administrator","password":"administrator"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' -v
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' -v

```

### Nmap sprawdzenie domyslnych kont HTTP

```bash
nmap --script http-default-accounts -p 80,443,8080,8443 TARGET
nmap --script http-default-accounts --script-args http-default-accounts.fingerprintfile=http-default-accounts-fingerprints.lua -p 80,443 TARGET

```

### Nuclei - szablony domyslnych loginow

```bash
nuclei -u https://TARGET -t default-logins/
nuclei -u https://TARGET -tags default-login
nuclei -u https://TARGET -t http/default-logins/

```

### Sprawdzenie znanych paneli administracyjnych

```bash
for path in /admin /administrator /wp-admin /phpmyadmin /manager/html /console /jenkins /webmail; do echo -n "$path: "; curl -s -o /dev/null -w "%{http_code}" "https://TARGET$path"; echo; done

```

## KOMENDY Z WORDLISTAMI

### Hydra brute force z domyslnymi credentials

```bash
hydra -C Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/ftp-betterdefaultpasslist.txt TARGET ftp
hydra -C Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/ssh-betterdefaultpasslist.txt TARGET ssh
hydra -C Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/telnet-betterdefaultpasslist.txt TARGET telnet

```

### Hydra HTTP POST form z domyslnymi loginami

```bash
hydra -L Desktop/WSTG/SecLists-master/Usernames/cirt-default-usernames.txt -P Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/ftp-betterdefaultpasslist.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### Medusa z domyslnymi credentials

```bash
medusa -h TARGET -U Desktop/WSTG/SecLists-master/Usernames/cirt-default-usernames.txt -P Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/ssh-betterdefaultpasslist.txt -M ssh

```

### ffuf z parami user:pass z cirt-net collection

```bash
ffuf -w Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/cirt-net_collection.txt:CREDS -u "https://TARGET/api/login" -X POST -H "Content-Type: application/json" -d '{"username":"CREDS","password":"CREDS"}' -mc 200

```

### fuzzdb domyslne credentials HTTP

```bash
hydra -C Desktop/WSTG/fuzzdb-master/wordlists-user-passwd/generic-listpairs/http_default_userpass.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

### fuzzdb domyslne credentials Tomcat

```bash
hydra -C Desktop/WSTG/fuzzdb-master/wordlists-user-passwd/tomcat/tomcat_mgr_default_userpass.txt TARGET http-get "/manager/html"

```

### fuzzdb domyslne credentials PostgreSQL

```bash
hydra -C Desktop/WSTG/fuzzdb-master/wordlists-user-passwd/postgres/postgres_default_userpass.txt TARGET postgres

```

### fuzzdb domyslne credentials MySQL

```bash
hydra -L Desktop/WSTG/fuzzdb-master/wordlists-user-passwd/generic-listpairs/http_default_users.txt -P Desktop/WSTG/fuzzdb-master/wordlists-user-passwd/generic-listpairs/http_default_pass.txt TARGET mysql

```

### Tomcat default credentials (base64 encoded)

```bash
ffuf -w Desktop/WSTG/SecLists-master/Passwords/Default-Credentials/tomcat-betterdefaultpasslist_base64encoded.txt:CREDS -u "https://TARGET/manager/html" -H "Authorization: Basic CREDS" -mc 200

```

### Oracle default passwords

```bash
hydra -C Desktop/WSTG/fuzzdb-master/wordlists-user-passwd/oracle/_oracle_default_passwords.txt TARGET oracle-listener

```

### Leaked databases passwords for spray attack

```bash
hydra -L Desktop/WSTG/SecLists-master/Usernames/top-usernames-shortlist.txt -P Desktop/WSTG/SecLists-master/Passwords/Leaked-Databases/rockyou-10.txt TARGET https-post-form "/api/login:username=^USER^&password=^PASS^:F=Invalid"

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz dokumentacje technologii uzywanej przez aplikacje pod katem domyslnych credentials
2. Wyszukaj w Google "default credentials [nazwa_aplikacji]"
3. Sprawdz panele administracyjne (Tomcat Manager, phpMyAdmin, Jenkins) z domyslnymi hasalmi
4. Przetestuj konta serwisowe i systemowe z domyslnymi haslami
5. Sprawdz czy aplikacja wymusza zmiane domyslnego hasla po pierwszym logowaniu
6. W Burp Intruder przetestuj kombinacje domyslnych credentials
7. Sprawdz pliki konfiguracyjne pod katem zakodowanych credentials
8. Przetestuj domyslne credentials dla baz danych, serwerow pocztowych i innych uslug


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Credential_Stuffing_Prevention_Cheat_Sheet.md

### Domyslne credentials — eliminacja

- **Zmien WSZYSTKIE** domyslne dane logowania PRZED wdrozeniem na produkcje
- Sprawdz: panele administracyjne, bazy danych, serwery aplikacji, middleware, IoT, routery
- Wymus zmiane domyslnego hasla przy pierwszym logowaniu — nie pozwol na uzywanie defaults
- Regularnie audytuj systemy pod katem kont z domyslnymi credentials

### Credential Stuffing Prevention

- **Credential stuffing**: atakujacy uzywa wycieknietych par login:haslo z innych serwisow
- **Multi-Factor Authentication (MFA)** — PRIMARY defense — nawet ze znanym haslem atakujacy nie przejdzie
- **CAPTCHA**: bot detection na stronie logowania — reCAPTCHA v3, hCaptcha
  - CAPTCHA po N nieudanych probach (np. 3) — nie irytuj legalnych uzytkownikow
- **Rate limiting**: ogranicz proby logowania per IP, per konto, per globalnie
  - Progresywne opoznienia: 1s, 2s, 4s, 8s po kolejnych bledach
  - Lockout konta po N nieudanych prob (np. 10) z automatycznym odblokowaniem po X minutach
- **Device fingerprinting**: identyfikuj znane urzadzenia uzytkownika — wymagaj MFA z nowych
- **IP reputation**: blokuj znane adresy IP botnetow, VPN, proxy

### Blokowanie znanych wycieknietych hasel

- Sprawdzaj nowe hasla przeciw **HaveIBeenPwned Passwords API** (k-anonymity — bezpieczne)
- Blokuj top-N najpopularniejszych hasel — listy dostepne w SecLists
- Blokuj hasla identyczne z username, email, nazwa aplikacji

### Wykrywanie anomalii

- Logowania z nowych lokalizacji (geolokalizacja IP)
- Nietypowe User-Agent (np. curl, skrypt zamiast przegladarki)
- Wiele kont logowanych z jednego IP w krotkim czasie
- Logowania w nietypowych godzinach
- Powiadomienie uzytkownika o nowym logowaniu z nieznanego urzadzenia

### Komunikaty bledow

- **Generyczne komunikaty** — "Invalid username or password" — nie ujawniaj czy uzytkownik istnieje
- Identyczny czas odpowiedzi dla istniejacego i nieistniejacego uzytkownika — obrona timing attacks
- Nie ujawniaj informacji o polityce blokowania konta w komunikatach bledow

### Logging i monitoring

- Loguj WSZYSTKIE proby logowania (udane i nieudane) z: timestamp, IP, UA, username
- Alertuj na: nagly wzrost nieudanych logow, credential stuffing patterns, brute force
- Integruj z SIEM do centralnego monitorowania

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
