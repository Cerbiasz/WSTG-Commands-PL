# WSTG-SESS-06 — Testing for Logout Functionality

## Cel

Audyt wylogowania: czy server-side session destroy, czy stary token JWT/session nadal działa po logout, czy refresh tokens revokowane, czy Clear-Site-Data wykorzystywane.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Login → capture session token**.
2. **Logout** przez UI.
3. **Replay starego token**: czy działa? (powinno NIE).
4. **JWT specific**: czy backend ma blacklist po logout?
5. **Concurrent sessions logout**: czy "logout everywhere" działa?

### Co MUSI być sprawdzone (8 punktów)

- [ ] Server-side session destroyed
- [ ] Cookie cleared (Set-Cookie z expired date)
- [ ] Refresh tokens revoked
- [ ] JWT blacklist (jeśli aplikacja używa JWT)
- [ ] Remember-me tokens revoked
- [ ] Browser storage cleared (Clear-Site-Data header)
- [ ] Logout endpoint odporny na CSRF (brak GET logout)
- [ ] "Logout everywhere" funkcja dostępna

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Wymagania prawidłowego wylogowania

- **Unieważnienie sesji SERVER-SIDE** — usuń sesje z pamięci/bazy serwera, NIE tylko cookie klienta
- **Usuń cookie klienta** — Set-Cookie z `expires=Thu, 01 Jan 1970` i pustą wartością
- **Unieważnij WSZYSTKIE powiązane tokeny**: access token, refresh token, CSRF token, remember-me token
- Wylogowanie musi być operacją **server-side** — samo usunięcie cookie NIE wystarcza (atakujący może mieć kopię)

### JWT i logout

- JWT są **stateless** — serwer domyślnie nie może ich unieważnić
- Implementuj **blacklist/revocation list** na serwerze — sprawdzaj przy każdym request
- Alternatywa: krótki czas życia JWT (np. 5-15 min) + refresh token z możliwością rewokacji
- Bez blackilisty: wykradzione JWT działa do momentu wygaśnięcia — poważna podatność

### Przycisk wylogowania

- Wylogowanie powinno być **POST** request — chroni przed CSRF (atakujący nie może wymusić wylogowania)
- GET logout pozwala na CSRF: `<img src="https://target.com/logout">` na evil.com → user wylogowany
- Po wylogowaniu: redirect na strona neutralna (np. login, landing) — NIE zalogowane stany

### Clear-Site-Data — czyszczenie po wylogowaniu

- Nagłówek `Clear-Site-Data` pozwala usunąć dane z przeglądarki:
  - `"cache"`, `"cookies"`, `"storage"`, `"executionContexts"`
- Ustaw na endpoincie wylogowania: `Clear-Site-Data: "cache", "cookies", "storage"`

### Concurrent sessions logout

- Pozwól użytkownikowi **wylogować wszystkie sesje** ("Sign out of all devices")
- Implementuj endpoint do unieważnienia WSZYSTKICH sesji użytkownika
- Po zmianie hasła automatycznie wyloguj wszystkie inne sesje

## Pentesterskie deep dive

### Mniej znane techniki

- **JWT logout brak**: aplikacja "wylogowuje" przez frontend (delete localStorage) ale token wciąż valid backend-side.
- **Logout via GET CSRF**: atakujący wymusza logout przez `<img src="/logout">` - DoS dla user.
- **OAuth logout incomplete**: logout w aplikacji ale OAuth provider session aktywna → user re-login auto.
- **bfcache (Back-Forward Cache)**: nawet po logout, click Back może showują cached page z user data.

### Common pitfalls

- **Logout endpoint redirects to /**: jeśli sesja jeszcze valid, redirect pokazuje user logged in.
- **Refresh token nie revoked**: access token expires ale refresh token valid 30 dni post-logout.

### Świeżynki z research

- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
- **MDN Clear-Site-Data**: https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Clear-Site-Data

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Repeater | Replay session token after logout |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/06-Testing_for_Logout_Functionality
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.3.1 | Logout invalidates session immediately. |
| V3.3.2 | Re-authentication after privilege change. |
