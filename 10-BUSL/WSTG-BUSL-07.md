# WSTG-BUSL-07 — Test Defenses Against Application Misuse

## Cel

Audyt obron przed misuse: rate limiting (per IP/user/global), CAPTCHA, anomaly detection, monitoring, WAF, abuse cases - czy aplikacja wykrywa atypowy behavior i reaguje?

> **Test manual-only**.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Rate limit test**: 100 requestów/sekundę na sensitive endpoint - blocked? CAPTCHA?
2. **WAF detection**: send malicious payload → blocked? bypassable?
3. **Anomaly detection**: nagła zmiana lokalizacji geo, nowy device → trigger MFA?
4. **Monitoring**: czy system loguje failed auth, suspicious patterns? Alert do SOC?
5. **Abuse cases**: każda funkcja ma defined abuse case + defense?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Rate limit per IP
- [ ] Rate limit per user
- [ ] Rate limit globalny
- [ ] CAPTCHA po N failed attempts
- [ ] WAF detection + bypass tests
- [ ] Geolokalizacja anomaly
- [ ] Device fingerprinting
- [ ] Failed auth logging + alerting
- [ ] Brute-force lockout
- [ ] Honeypot endpoints (canary detection)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md

### Defenses Against Application Misuse

- **Abuse cases obok use cases**: dla KAŻDEJ funkcji zdefiniuj scenariusze nadużywania
- Przykład: "Jako atakujący chcę obejść WAF", "Jako bot chcę ominąć CAPTCHA"
- Wbuduj obrony w design — nie dodawaj post-factum

### Rate Limiting — warstwowe

- **Per IP**: ogranicz requesty z jednego IP (uwaga: NAT, proxy)
- **Per użytkownik/konto**: ogranicz operacje per zalogowany użytkownik
- **Per endpoint**: krytyczne endpointy (login, reset) mają niższe limity
- **Globalnie**: ogranicz całkowitą przepustowość — obrona przed DDoS
- Progresywne opóźnienia: 1s, 2s, 4s po kolejnych próbach

### WAF Bypass — co testować

- Case manipulation: `<ScRiPt>`, `SELECT` vs `select` vs `SeLeCt`
- Encoding: URL encoding (`%27`), double encoding (`%2527`), Unicode
- Komentarze SQL: `/**/`, `/*!50000*/` (MySQL version comment)
- Alternatywne payloady: `<img src=x onerror=alert(1)>` zamiast `<script>alert(1)</script>`
- Content-Type switching: `application/json` zamiast `application/x-www-form-urlencoded`
- HTTP/2 smuggling: bypass WAF action header parsing

### Monitoring i alerting

- Loguj WSZYSTKIE failed authentication, authz, payment, file upload attempts
- Alertuj na anomalie: spike of 5xx, unusual user-agents, brute force patterns
- Centralized logging: ELK, Splunk, SIEM
- Real-time response: auto-block IP po wykryciu attack pattern

### Honeypots

- Hidden links/fields visible tylko dla bots → klikających = bot detected
- Email harvesting traps
- API endpoint który zawsze zwraca 200 ale loguje + alerts

## Pentesterskie deep dive

### Mniej znane techniki

- **WAF bypass via HTTP/2 desync**: różne parsing frontend vs backend.
- **CAPTCHA solver services**: 2captcha, anti-captcha (commercial).
- **Distributed botnet bypass IP rate limit**: 1000 IPs po 1 attempt each.
- **JS-based bot detection bypass via headless browser w stealth mode**.

### Common pitfalls

- **Rate limit per IP only**: NAT/proxy = wiele users blocked or spoofed via X-Forwarded-For.
- **WAF blocks tylko obvious attacks**: `' OR 1=1` blocked but `' OR 1#=1` passes.

### Świeżynki z research

- **OWASP Abuse Case CS**: https://cheatsheetseries.owasp.org/cheatsheets/Abuse_Case_Cheat_Sheet.html
- **OWASP Automated Threat Handbook**: https://owasp.org/www-project-automated-threats-to-web-applications/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Wafw00f (CLI) | WAF identification |
| Hackvertor | Encoding bypass |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/07-Test_Defenses_Against_Application_Misuse
- OWASP Abuse Case CS: https://cheatsheetseries.owasp.org/cheatsheets/Abuse_Case_Cheat_Sheet.html
- OWASP Automated Threats: https://owasp.org/www-project-automated-threats-to-web-applications/

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V11.1.4 | Anti-automation controls. |
| V11.1.5 | Defense against business flow abuse. |
