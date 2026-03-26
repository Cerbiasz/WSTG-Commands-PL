# WSTG-BUSL-07 — Test Defenses Against Application Misuse

## Cele

- Przegladnac zabezpieczenia przed naduzyciami aplikacji
- Zweryfikowac mozliwosc obejscia zabezpieczen

## KOMENDY

### Testowanie rate limiting

```bash
for i in $(seq 1 100); do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" TARGET/api/login -X POST -d "user=admin&pass=test${i}")
    echo "Request $i: HTTP $RESPONSE"
done

```

### Testowanie rate limiting z roznych IP

```bash
for i in $(seq 1 20); do
    curl -s -o /dev/null -w "IP 1.1.1.$i: %{http_code}\n" TARGET/api/login \
      -X POST -d "user=admin&pass=test" -H "X-Forwarded-For: 1.1.1.${i}"
done

```

### Testowanie WAF rules

```bash
curl -v "TARGET/page?id=1' OR 1=1--"
curl -v "TARGET/page?id=1'/**/OR/**/1=1--"
curl -v "TARGET/page?id=1%27%20OR%201%3D1--"

```

### Testowanie obejscia WAF

```bash
curl -v "TARGET/?param=<script>alert(1)</script>"
curl -v "TARGET/?param=<ScRiPt>alert(1)</ScRiPt>"
curl -v "TARGET/?param=<img src=x onerror=alert(1)>"
curl -v -H "Content-Type: application/json" TARGET/api -d '{"param":"<script>alert(1)</script>"}'

```

### Testowanie CAPTCHA bypass

```bash
# Sprawdz czy CAPTCHA jest walidowana po stronie serwera:
curl -v -X POST TARGET/login -d "user=test&pass=test&captcha="
curl -v -X POST TARGET/login -d "user=test&pass=test"
# Wyslij stare rozwiazanie CAPTCHA:
curl -v -X POST TARGET/login -d "user=test&pass=test&captcha=OLD_CAPTCHA_VALUE"

```

### Testowanie account lockout

```bash
for i in $(seq 1 15); do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST TARGET/login -d "user=victim&pass=wrong${i}")
    echo "Attempt $i: HTTP $RESPONSE"
done
# Sprawdz czy konto jest zablokowane:
curl -v -X POST TARGET/login -d "user=victim&pass=correct_password"

```

### Testowanie automatyzacji (bot detection)

```bash
curl -v TARGET/api/endpoint -H "User-Agent: python-requests/2.28.0"
curl -v TARGET/api/endpoint -H "User-Agent: curl/7.88.1"
curl -v TARGET/api/endpoint -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

```

### Agresywne fuzzowanie

```bash
wfuzz -c --hc 404 -z range,1-1000 TARGET/api/item/FUZZ

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice zabezpieczen

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Testuj rate limiting na krytycznych endpointach (login, reset password, API)
2. Sprawdz czy CAPTCHA jest egzekwowana po kazdej probie (nie tylko po kilku blednych)
3. Testuj obejscie rate limitingu: X-Forwarded-For, X-Real-IP, rozne User-Agents
4. Sprawdz czy account lockout dziala i czy mozna go wykorzystac do DoS
5. Testuj WAF bypass: rozne encodingi, case manipulation, komentarze SQL
6. Sprawdz czy aplikacja loguje podejrzana aktywnosc
7. Testuj czy aplikacja blokuje agresywne skanowanie (wiele 404, szybkie requesty)
8. Sprawdz odpowiedzi na abuse: czy sa informacyjne (ulatwiaja atakujacemu)?


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md

### Defenses Against Application Misuse

- **Abuse cases obok use cases**: dla KAZDEJ funkcji zdefiniuj scenariusze naduzywania
- Przyklad: "Jako atakujacy chce obejsc WAF", "Jako bot chce omnic CAPTCHA"
- Wbuduj obrony w design — nie dodawaj post-factum

### Rate Limiting — warstwowe

- **Per IP**: ogranicz requesty z jednego IP (uwaga: NAT, proxy)
- **Per uzytkownik/konto**: ogranicz operacje per zalogowany uzytkownik
- **Per endpoint**: krytyczne endpointy (login, reset) maja nizsze limity
- **Globalnie**: ogranicz calkowita przepustowosc — obrona przed DDoS
- Progresywne opoznienia: 1s, 2s, 4s po kolejnych probach

### WAF Bypass — co testowac

- Case manipulation: `<ScRiPt>`, `SELECT` vs `select` vs `SeLeCt`
- Encoding: URL encoding (`%27`), double encoding (`%2527`), Unicode
- Komentarze SQL: `/**/`, `/*!50000*/` (MySQL version comment)
- Alternatywne payloady: `<img src=x onerror=alert(1)>` zamiast `<script>alert(1)</script>`
- Content-Type switching: `application/json` zamiast `application/x-www-form-urlencoded`

### CAPTCHA — wdrozenie i bypass

- Waliduj CAPTCHA **server-side** — nie po stronie klienta
- CAPTCHA musi byc **jednorazowa** — stare rozwiazanie nie moze byc reuse
- Uzyj **invisible CAPTCHA** (reCAPTCHA v3) — mniej irytujaca dla uzytkownikow
- Testuj: puste pole CAPTCHA, brak parametru, stare rozwiazanie, OCR bypass

### Monitoring i alerting

- Loguj WSZYSTKIE podejrzane wzorce: duza ilosc 404, szybkie requesty, nietypowe User-Agent
- Alertuj na: skanowanie portow, directory brute force, credential stuffing
- Integruj z SIEM do centralnego monitorowania i korelacji zdarzen

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.4.1 | Anti-automation | Verify that anti-automation controls are in place to protect against excessive calls to application functions that could lead to data exfiltration, garbage-data creation, quota exhaustion, rate-limit breaches, denial-of-service, or overuse of costly resources. |
| V16.3.3 | Security Events | Verify that the application logs the security events that are defined in the documentation and also logs attempts to bypass the security controls, such as input validation, business logic, and anti-automation. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.4.2 | Anti-automation | Verify that business logic flows require realistic human timing, preventing excessively rapid transaction submissions. |
