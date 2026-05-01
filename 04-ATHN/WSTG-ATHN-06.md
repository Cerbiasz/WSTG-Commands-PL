# WSTG-ATHN-06 — Testing for Browser Cache Weaknesses

## Cel

Sprawdzenie że wrażliwe responses (login, password reset, account settings) mają `Cache-Control: no-store` i nie są cache'owane przez przeglądarkę. Cached sensitive data w shared environment (kawiarnia internet) = leak.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-athn-06-browser-cache.yaml
```

Wykrywa sensitive endpoints (login, account, password) bez `Cache-Control: no-store` i `Pragma: no-cache`.

### Cross-reference

```bash
# Pełen security headers audit
nuclei -l burp-export.xml -im burp -t templates/wstg-conf-14-security-headers.yaml
```

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| Sensitive page bez Cache-Control: no-store | ✓ |
| Login/account/password paths | ✓ |
| autocomplete attribute na formularzach | manual |
| Clear-Site-Data po logout | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Per sensitive endpoint**: GET /login, /account, /password/reset → sprawdzić Cache-Control header.
2. **Browser cache test**: po wylogowaniu, naciśnij Back button → czy widać cached page z user data?
3. **Disk cache test**: `chrome://view-http-cache` (legacy) lub DevTools Network tab `Disable cache=off`.
4. **autocomplete check**: na password fields, czy `autocomplete="new-password"` ustawione?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Cache-Control: no-store na login/account/password pages
- [ ] Pragma: no-cache (HTTP/1.0 backward compat)
- [ ] Expires: 0 lub past date
- [ ] autocomplete="off" lub autocomplete="new-password" na password fields
- [ ] Back button test po logout
- [ ] Cache-Control: private nie wystarcza (cache na disk allowed)
- [ ] Clear-Site-Data: cookies, cache po logout
- [ ] Sensitive data NIE w localStorage/sessionStorage (cross WSTG-CLNT-12)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Nagłówki Cache-Control — prawidłowa konfiguracja

- Strony z wrażliwymi danymi MUSZĄ mieć: `Cache-Control: no-store, no-cache, must-revalidate, private`
- Dodaj `Pragma: no-cache` dla kompatybilności z HTTP/1.0
- Ustaw `Expires: 0` lub date w przeszłości
- **no-store** jest KLUCZOWY — `no-cache` sam w sobie NIE zapobiega zapisowi na dysku
- Nie polegaj na `private` jako jedynej ochronie — chroni przed cache proxy, ale nie przeglądarki

### Autocomplete — formularze z wrażliwymi danymi

- Pola hasła: `autocomplete="new-password"` lub `autocomplete="current-password"`
- Formularze logowania: `autocomplete="off"` na całym formularzu LUB na poszczególnych polach
- Pola kart kredytowych, SSN, dane medyczne: `autocomplete="off"`
- Uwaga: nowoczesne przeglądarki mogą **ignorować** `autocomplete="off"` na polach hasła
- Dla kart: używaj `autocomplete="cc-number"` z `autocomplete="off"` zależnie od kontekstu

### Clear-Site-Data — czyszczenie po wylogowaniu

- Nagłówek `Clear-Site-Data` pozwala usunąć dane z przeglądarki po wylogowaniu:
  - `"cache"` — czyść cache HTTP
  - `"cookies"` — usuń cookies
  - `"storage"` — usuń localStorage, sessionStorage, IndexedDB
  - `"executionContexts"` — przeładuj wszystkie strony
- Ustaw na endpoincie wylogowania: `Clear-Site-Data: "cache", "cookies", "storage"`

### Browser Cache — co pamięta przeglądarka

- HTTP cache (na dysku/RAM) — Cache-Control kontroluje
- Form autocomplete — passwordy zapisane w password manager
- Browser history — URL z parametrami sensitive (token w URL = bad)
- Back button cache (bfcache) — szybki back/forward bez network request

## Pentesterskie deep dive

### Mniej znane techniki

- **Back-Forward Cache (bfcache)**: nawet z proper Cache-Control, niektóre browsers cache pages w bfcache. CSP `no-store` w combination z page content może opt out.
- **Service Worker cache**: SW może cache responses bypass-ujący HTTP Cache-Control. Audyt registered SWs.
- **Modern autocomplete bypass**: Chrome ignoruje `autocomplete="off"` na password fields - "Autofill in production code might not be acceptable" but ignored anyway.
- **Sensitive data in URL**: `?token=...`, `?reset_code=...` - URL trafia do browser history nawet bez cache.

### Common pitfalls

- **Cache-Control: private myślony jako wystarczający**: chroni tylko przed shared proxy cache, NIE przed disk cache.
- **Logout doesn't trigger Clear-Site-Data**: simple session destruction bez clear of client-side state.

### Świeżynki z research

- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- **MDN Clear-Site-Data**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Software Version Reporter | Detect insecure cache configs |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/06-Testing_for_Browser_Cache_Weaknesses
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- MDN Clear-Site-Data: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V14.4.7 | Application sets sufficient anti-caching headers for sensitive data. |
| V8.2.1 | Cache control headers on sensitive responses. |
