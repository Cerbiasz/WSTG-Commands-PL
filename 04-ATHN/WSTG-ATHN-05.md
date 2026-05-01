# WSTG-ATHN-05 — Testing for Vulnerable Remember Password

## Cel

Audyt funkcji "Remember Me": czy token jest cryptographically random (CSPRNG), jednorazowy, hashowany w DB, ma rozsądny TTL (7-30 dni), invalidowany przy logout/zmianie hasła.

> **Test mostly manual**: wymaga interakcji z aplikacją.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Token analysis**: po zaznaczeniu "Remember Me", sprawdź cookie - czy looks random? Czy zawiera username/ID w plaintext (Base64-decode)?
2. **Token TTL**: sprawdź `Max-Age` lub `Expires` cookie - <= 30 dni?
3. **Cookie attributes**: Secure + HttpOnly + SameSite=Lax/Strict?
4. **Token rotation**: po użyciu, czy token się zmienia? (Rotation defense vs replay).
5. **Invalidation**: po logout, czy stary token nadal działa? Po zmianie hasła?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Token: minimum 128-bit entropy
- [ ] Token: nie zawiera username/ID w plaintext
- [ ] Cookie Secure flag
- [ ] Cookie HttpOnly flag
- [ ] Cookie SameSite=Lax/Strict
- [ ] TTL <= 30 days
- [ ] Token rotation per use
- [ ] Logout invalidates token
- [ ] Password change invalidates wszystkie tokens
- [ ] DB stores hashed token (nie raw)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Remember Me — bezpieczna implementacja

- Token remember-me musi być **kryptograficznie losowy** (CSPRNG) — minimum 128 bitów entropii
- Token NIE MOŻE zawierać danych użytkownika w jawnej formie (username, ID, email)
- Przechowuj token **zahaszowany** po stronie serwera (bcrypt/SHA-256) — jak hasło
- Każdy token musi być **jednorazowy** — po użyciu generuj nowy (token rotation)
- Ustaw rozsądny czas wygaśnięcia: 7-30 dni (NIE bezterminowo)

### Cookie remember-me — atrybuty bezpieczeństwa

- **Secure**: przesyłaj TYLKO przez HTTPS
- **HttpOnly**: niedostępny z JavaScript — chroni przed XSS
- **SameSite=Lax/Strict**: ochrona przed CSRF
- **Path=/**: ograniczony do niezbędnych ścieżek
- Użyj prefixu `__Secure-` lub `__Host-` dla dodatkowej ochrony
- Cookie remember-me powinno być **oddzielne** od session cookie

### Unieważnianie tokenów

- **Zmiana hasła**: unieważnij WSZYSTKIE tokeny remember-me dla użytkownika
- **Wylogowanie**: unieważnij token powiązany z bieżącą sesją
- **Wykrycie kompromitacji** (ujawniony login z innej geolokalizacji): unieważnij tokeny
- Pozwól użytkownikowi przejrzeć aktywne sesje i wylogować je manualnie

## Pentesterskie deep dive

### Mniej znane techniki

- **Remember-me token rotation race**: jeśli aplikacja rotuje token at use, race condition może użyć stary token przed invalidation.
- **Predictable token via weak PRNG**: niektóre legacy aplikacje używają Math.random() lub time-based - przewidywalne.
- **Token exfil via XSS na non-HttpOnly cookie**: jeśli flag missing, każdy XSS = stolen.
- **Cross-app cookie scope**: cookie z `Domain=.target.com` może być stolen przez kompromis subdomeny.

### Common pitfalls

- **Token contains user ID Base64**: dekodowanie ujawnia user ID → atakujący zna którego user impersonate.
- **No expiry**: token "Remember Me forever" = długoterminowy attack window.

### Świeżynki z research

- **PortSwigger Authentication labs**: https://portswigger.net/web-security/authentication
- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Cookie Editor | Token analysis |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/05-Testing_for_Vulnerable_Remember_Password
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.4.1 | Session token entropy ≥ 64 bits. |
| V3.5.2 | Remember me uses random token, not password derivative. |
| V3.5.3 | Tokens invalidated on logout/password change. |
