# WSTG-ATHN-02 — Testing for Default Credentials

## Cel

Wykrycie kont z domyślnymi/wbudowanymi credentials: admin/admin (Tomcat manager), root/root (legacy systems), guest/guest (RabbitMQ), Tomcat/Jenkins/JBoss panele bez zmiany defaults po deploy.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-athn-02-default-credentials.yaml
```

Pasywnie wykrywa markery default creds w HTML/JS (komentarze, prefilled values, documentation).

### Active default-login testing

```bash
# Pełna baza default credentials per service
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/default-logins/

# Konkretne wysokorezykowne:
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/default-logins/tomcat/ \
       -t resources/nuclei-templates/http/default-logins/jenkins/ \
       -t resources/nuclei-templates/http/default-logins/jboss/ \
       -t resources/nuclei-templates/http/default-logins/grafana/

# Hydra brute-force z SecLists
hydra -l admin -P resources/seclists/Passwords/Common-Credentials/10-million-password-list-top-1000.txt \
      target.com http-post-form "/login:user=^USER^&pass=^PASS^:Invalid"
```

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| Markery default creds w HTML | ✓ |
| Prefilled login form | ✓ |
| Active default-login per service | http/default-logins/ |
| Common Credentials brute-force | hydra + SecLists |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Tech-stack identification**: WSTG-INFO-08 → wiemy jaki framework / panel.
2. **Per-service defaults**: dla każdego service uruchomić odpowiedni `default-logins/<service>` template.
3. **Common credentials brute-force**: `admin/admin`, `admin/password`, `admin/admin123`, `root/root`, `tomcat/tomcat`.
4. **Application-specific defaults**: WordPress (admin/admin), Jenkins (admin/admin po install), Grafana (admin/admin).
5. **Document and recommend**: zmiana wszystkich defaults pre-prod.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Tomcat manager: `admin/admin`, `tomcat/tomcat`, `manager/manager`, `admin/`
- [ ] Jenkins: `admin/admin` po fresh install
- [ ] phpMyAdmin: `root/` (no password)
- [ ] Adminer: `root/`
- [ ] Grafana: `admin/admin`
- [ ] Kibana: `elastic/changeme`
- [ ] WordPress: `admin/admin`
- [ ] JBoss: `admin/admin` (admin-console)
- [ ] WebLogic: `weblogic/welcome1`
- [ ] Cisco devices: `cisco/cisco`, `admin/admin`

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Credential_Stuffing_Prevention_Cheat_Sheet.md

### Domyślne credentials — eliminacja

- **Zmień WSZYSTKIE** domyślne dane logowania PRZED wdrożeniem na produkcję
- Sprawdź: panele administracyjne, bazy danych, serwery aplikacji, middleware, IoT, routery
- Wymuś zmianę domyślnego hasła przy pierwszym logowaniu — nie pozwól na używanie defaults
- Regularnie audytuj systemy pod kątem kont z domyślnymi credentials

### Credential Stuffing Prevention

- **Credential stuffing**: atakujący używa wycieknietych par login:hasło z innych serwisów
- **Multi-Factor Authentication (MFA)** — PRIMARY defense — nawet ze znanym hasłem atakujący nie przejdzie
- **CAPTCHA**: bot detection na stronie logowania — reCAPTCHA v3, hCaptcha
  - CAPTCHA po N nieudanych próbach (np. 3) — nie irytuj legalnych użytkowników
- **Rate limiting**: ogranicz próby logowania per IP, per konto, per globalnie
  - Progresywne opóźnienia: 1s, 2s, 4s, 8s po kolejnych błędach
  - Lockout konta po N nieudanych prób (np. 10) z automatycznym odblokowaniem po X minutach
- **Device fingerprinting**: identyfikuj znane urządzenia użytkownika — wymagaj MFA z nowych
- **IP reputation**: blokuj znane adresy IP botnetów, VPN, proxy

### Blokowanie znanych wycieknietych haseł

- HaveIBeenPwned Passwords API — sprawdzaj czy hasło wystąpiło w breach
- Blokuj top-N najpopularniejszych haseł z list (rockyou, SecLists)
- Blokuj hasła identyczne z username, email, nazwą aplikacji

## Pentesterskie deep dive

### Mniej znane techniki

- **Tomcat manager via path bypass**: `/manager/html/..;/` na niektórych Tomcat versions może bypass auth filter.
- **Jenkins script console after default login**: po `admin/admin`, `/script` daje Groovy console = pełen RCE.
- **Default creds via Wayback Machine**: stare deploys sometimes documented w internal wiki cached on Wayback.
- **API key as default**: niektóre aplikacje używają znanego "first API key" do bootstrap → atakujący może zgadnąć.

### Common pitfalls

- **"We changed admin password but tomcat:tomcat works"**: każdy service ma własne defaults - Tomcat manager users w `tomcat-users.xml` separate.
- **First-login password change ignorowany**: aplikacja prosi o zmianę ale nie wymusza.

### Świeżynki z research

- **DefaultCreds-cheat-sheet**: https://github.com/ihebski/DefaultCreds-cheat-sheet
- **SecLists Default-Credentials**: https://github.com/danielmiessler/SecLists/tree/master/Passwords/Default-Credentials

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| AdminPanelFinder | Detekcja paneli admin |
| Hydra (CLI) | Brute force |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/02-Testing_for_Default_Credentials
- DefaultCreds CS: https://github.com/ihebski/DefaultCreds-cheat-sheet
- ProjectDiscovery default-logins: https://github.com/projectdiscovery/nuclei-templates/tree/main/http/default-logins

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V14.3.2 | No default credentials, sample apps. |
| V2.1.7 | Check breached password lists. |
