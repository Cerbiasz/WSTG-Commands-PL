# WSTG-SESS-09 — Testing for Session Hijacking

## Cel

Audyt obrony przed session hijacking: TLS enforcement (sniffing), HttpOnly cookies (XSS), HSTS (downgrade), session ID nigdy w URL, token sidejacking prevention.

## Automatyzacja Nuclei

```bash
# Session in URL detection
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-09-session-hijacking.yaml

# Cookie attributes
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-02-cookie-attributes.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Cookie audit**: Secure + HttpOnly + SameSite (cross WSTG-SESS-02).
2. **TLS enforcement**: HTTPS only + HSTS (cross WSTG-CONF-07, WSTG-CRYP-01).
3. **URL session check**: czy session ID w URL params/path?
4. **Token binding**: czy aplikacja binds session do user fingerprint (IP, UA, device)?
5. **Concurrent session**: czy aplikacja allows multi-device login?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Session cookie: Secure + HttpOnly + SameSite
- [ ] HTTPS only + HSTS
- [ ] Session ID nigdy w URL
- [ ] `__Host-` prefix dla session cookies
- [ ] Session bound to fingerprint (IP/UA - debatable, can break legitimate scenarios)
- [ ] Concurrent session limits
- [ ] Active session view (user sees their sessions)
- [ ] Session regenerated po login (cross WSTG-SESS-03)
- [ ] CSP `frame-ancestors` (clickjacking session theft)
- [ ] Browser storage NIE zawiera session token

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md, JSON_Web_Token_for_Java_Cheat_Sheet.md

### Wektory session hijacking

- **Sniffing (sieć)**: przechwycenie cookie w niezaszyfrowanym ruchu HTTP — obrona: TLS + Secure flag
- **XSS**: JavaScript `document.cookie` wykrada cookie — obrona: HttpOnly flag
- **Man-in-the-Middle**: atakujący między klientem a serwerem — obrona: HSTS + TLS
- **Malware/browser extension**: odczyt cookies z przeglądarki — obrona: krótki timeout + fingerprinting
- **Physical access**: odczyt cookies z dysku/pamięci — obrona: session cookies (bez Expires)

### Obrona — atrybuty cookies

- **Secure** — cookie TYLKO przez HTTPS — chroni przed sniffingiem
- **HttpOnly** — cookie niedostępne dla JavaScript — chroni przed XSS
- **SameSite=Strict/Lax** — ogranicza cross-site wysyłanie — chroni przed CSRF
- **`__Host-` prefix** — wymusza Secure + Path=/ + brak Domain — najsilniejsza izolacja

### Token Sidejacking Prevention (technika z OWASP JWT Cheat Sheet)

- **User context fingerprint**: dodaj losowy string w hardened cookie (`__Secure-Fgp; Secure; HttpOnly; SameSite=Strict`)
- Przechowuj **SHA-256 hash** fingerprint w JWT payload (nie raw value)
- Sprawdzaj że request fingerprint = JWT fingerprint
- Atakujący kradnący JWT bez cookie nie może go wykorzystać

### Anomaly detection

- Loguj IP, User-Agent, geolokalizację per session
- Wykrywaj nagłe zmiany (różny continent, różny UA) → alert + force re-auth

## Pentesterskie deep dive

### Mniej znane techniki

- **Session sidejacking via Wi-Fi**: open Wi-Fi + cookie bez Secure flag = trivial sniffing.
- **Subdomain compromise → session theft**: XSS na subdomain z cookie domain wildcard.
- **Browser extension theft**: malicious extension reads cookies bypass HttpOnly.
- **Token sidejacking**: stolen JWT replayed from different IP - czy aplikacja wykrywa?

### Common pitfalls

- **HttpOnly ignored "for legacy"**: jakaś legacy reason - klucz jest w localStorage gdzie XSS = pwn.
- **Session bound to IP**: breaks mobile users na NAT/zmianach Wi-Fi → typowo nie aplikowane.

### Świeżynki z research

- **OWASP JWT CS**: https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
- **HackTricks Session Hijacking**: https://book.hacktricks.xyz/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Cookie Editor | Cookie attributes audit |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/09-Testing_for_Session_Hijacking
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.2.2 | Session ID never disclosed in URL/error/log. |
| V3.4.1 | Cookie attributes Secure, HttpOnly, SameSite. |
| V3.7.1 | Active session monitoring. |
