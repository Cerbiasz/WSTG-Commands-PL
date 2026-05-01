# WSTG-CLNT-12 — Testing Browser Storage

## Cel

Audyt browser-side storage (localStorage, sessionStorage, IndexedDB, cookies bez HttpOnly) — co aplikacja przechowuje. Sensitive data (tokens, PII) w localStorage = XSS = pełen takeover. JWT w localStorage to klasyczny anti-pattern.

> **Test manual**: storage audit przez DevTools > Application > Storage. Nuclei nie ma direct testu.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **DevTools storage walk**: per page (login, dashboard, settings) → DevTools > Application > Storage → przejrzyj wszystkie kategorie.
2. **Search for secrets**: grep dla `token`, `auth`, `password`, `email`, `apikey`, `csrf`, `session`.
3. **Logout test**: po logout, czy storage jest cleared? Pozostały data = potential leak.
4. **XSS impact test**: jeśli token w localStorage, XSS daje pełny dostęp do tokena (niezależnie od HttpOnly cookies).
5. **Encryption check**: czy dane w storage są encrypted (rzadko ale niektóre apps tak robią)?

### Co MUSI być sprawdzone (10 punktów)

- [ ] localStorage content per page
- [ ] sessionStorage content per page
- [ ] IndexedDB databases
- [ ] Cookies (zwłaszcza bez HttpOnly)
- [ ] JWT tokens w storage
- [ ] PII (email, name, address) w storage
- [ ] API keys w storage
- [ ] CSRF tokens lokalizacja (cookie HttpOnly OK, localStorage NIE)
- [ ] Storage cleared at logout
- [ ] Storage encryption (rare)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md, Session_Management_Cheat_Sheet.md

### Ryzyka przechowywania danych w przeglądarce

- **localStorage**: dostępne dla KAŻDEGO JavaScript na tej samej domenie — XSS = pełen dostęp
- **sessionStorage**: jak localStorage ale per tab — wciąż dostępne przez XSS
- **IndexedDB/WebSQL**: większa pojemność, te same ryzyka
- **Cookies bez HttpOnly**: dostępne przez `document.cookie` — XSS może je wykraść

### Co NIE powinno być w client-side storage

- **Tokeny sesji / JWT** — używaj HttpOnly cookies zamiast localStorage
- **Hasła** — NIGDY nie przechowuj haseł po stronie klienta
- **PII** (dane osobowe): imię, email, adres, PESEL, numer karty
- **Klucze API** — nie umieszczaj w JavaScript / storage — używaj backend proxy
- **CSRF tokeny** — powinny być w HttpOnly cookies lub ukrytych polach formularza

### Obrona

- **HttpOnly cookies** dla tokenów sesji — niedostępne dla JavaScript
- **Minimalizuj dane** w storage — przechowuj MINIMUM potrzebnych informacji
- **Czyść storage przy wylogowaniu**: `localStorage.clear()`, `sessionStorage.clear()`
- **Waliduj dane** odczytane z storage — mogą być zmodyfikowane przez atakującego lub malware
- **Szyfruj wrażliwe dane** w storage jeśli MUSISZ je przechowywać (Web Crypto API)
- **Ustaw krótki TTL** na danych w storage — nie przechowuj danych bez daty wygaśnięcia

### Testowanie

- DevTools > Application > Storage: przejrzyj WSZYSTKIE dane w localStorage, sessionStorage, IndexedDB, cookies
- Szukaj: tokenów, haseł, kluczy API, PII, danych finansowych
- Sprawdź czy dane są czyszczone po wylogowaniu
- Sprawdź czy dane są szyfrowane

## Pentesterskie deep dive

### Mniej znane techniki

- **JWT in localStorage debate**: większość OWASP / OAuth experts rekomenduje HttpOnly cookies > localStorage. Argumenty for localStorage (CSRF immunity) są weak vs XSS impact.
- **IndexedDB vulnerabilities**: niektóre aplikacje używają IndexedDB jako persistent storage z encrypted user data — atakujący XSS extracts encrypted blobs.
- **Web SQL Database** (deprecated): legacy aplikacje mogą jeszcze używać — same vulnerability profile jak localStorage.
- **Cache API + Service Worker**: Service Worker z access do Cache API może persist sensitive responses → XSS pivots do persistent data leak.
- **Credential Management API**: nowe API browser pozwala na storage credentials — ale wymaga proper HTTPS + scope.

### Common pitfalls

- **localStorage.clear() not called at logout**: tokeny zostają, atakujący XSS na following user session steals stale data.
- **OAuth tokens w localStorage**: anti-pattern. Lepiej HttpOnly cookies + CSRF protection.
- **Encrypted localStorage with key in JS**: jeśli encryption key jest w JS bundle, atakujący znajduje key + decrypts = pointless encryption.

### Świeżynki z research

- **OWASP HTML5 Security**: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html
- **HackTricks Browser Storage**: https://book.hacktricks.xyz/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Storage Inspector | Per-request storage state capture | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/12-Testing_Browser_Storage
- OWASP HTML5 Security CS: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- HackTricks Pentesting Web: https://book.hacktricks.xyz/pentesting-web

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.2.2 | Sensitive Data (L1) | No sensitive data in browser localStorage/sessionStorage. |
| V8.2.3 | Sensitive Data (L2) | No tokens or session IDs in browser storage. |
| V3.4.1 | Cookie-based Session (L1) | HttpOnly flag on session cookies. |
