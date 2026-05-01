# WSTG-SESS-04 — Testing for Exposed Session Variables

## Cel

Wykrycie czy session ID/tokens są wystawione w niebezpiecznych miejscach: URL parameters, Referer header, browser history, logi serwera/proxy/CDN, cache, browser autocomplete.

## Automatyzacja Nuclei

```bash
# Cross-ref: WSTG-SESS-09 wykrywa session w URL
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-09-session-hijacking.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **URL audit**: Burp HTTP history → grep dla session/token w URL.
2. **Referer leak**: aplikacja na HTTPS, link do HTTP/external → Referer header może wyciec session.
3. **Logs review** (jeśli dostępne): server access logs zawierające URL z tokenem.
4. **Cache check**: response z session-related data ma `Cache-Control: no-store`?
5. **Browser autocomplete**: pola token/password mają autocomplete=off?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Session ID nigdy w URL parameters
- [ ] Session ID nigdy w URL path (jsessionid)
- [ ] HTTPS pages nie linkują do HTTP (Referer leak)
- [ ] Cache-Control: no-store na sensitive responses
- [ ] Logs nie zawierają session IDs (server, proxy, CDN)
- [ ] Authorization Bearer tokens w header (nie URL)
- [ ] Forms z password mają autocomplete=new-password
- [ ] Password change flow nie expose token w URL

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Session ID NIE w URL

- **NIGDY** nie umieszczaj session ID w URL parametrach — wycieka przez:
  - **Referer header**: kliknięcie linku zewnętrznego wysyła URL z tokenem w Referer
  - **Logi serwera**: URL z tokenem zapisywany w access logach, proxy logach, CDN logach
  - **Historia przeglądarki**: URL z tokenem dostępny lokalnie
  - **Zakładki**: użytkownik może przypadkowo udostępnić URL z tokenem
  - **Udostępnienie URL**: kopiowanie linku z session ID

### Transport tokenów sesji

- Session ID TYLKO w cookies z flagami `Secure`, `HttpOnly`, `SameSite`
- Dane wrażliwe wysyłaj przez **POST** — nie GET (GET trafia do logów, historii, cache)
- Alternatywa: `Authorization: Bearer` header dla API — nie wycieknie przez Referer

### Ochrona przed wyciekiem przez Referer

- `Referrer-Policy: strict-origin-when-cross-origin` — wysyła tylko origin (bez path) cross-origin
- `Referrer-Policy: no-referrer` — nigdy nie wysyłaj Referer (najsilniejsze ale break some flows)
- Atrybut `rel="noreferrer"` na linkach do external

### Logging — nie loguj sesji

- Nie loguj URL parameters w server access logs jeśli zawierają sensitive data
- Strip cookies przed logowaniem
- Nie loguj Authorization header

## Pentesterskie deep dive

### Mniej znane techniki

- **Referer leak via 3rd party JS**: aplikacja includes Google Analytics → URL z tokenem w analytics request.
- **CDN cache logs**: token w URL cached w CDN with X-Cache: HIT logs.
- **Browser bfcache**: cached page w bfcache nawet po logout = session valid for 30 sec back navigation.

### Common pitfalls

- **OAuth code w URL after redirect**: OAuth authorization code is intentional ale powinno być short-lived + one-time use.
- **`?token=...` link from email**: legitimate use case ale token must be one-time + short TTL.

### Świeżynki z research

- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Logger++ | URL/header logging analysis |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/04-Testing_for_Exposed_Session_Variables
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.2.2 | Session ID never disclosed in URL/error/log. |
| V14.4.7 | Anti-caching headers on sensitive data. |
