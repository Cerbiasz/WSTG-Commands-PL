# WSTG-SESS-03 — Testing for Session Fixation

## Cel

Wykrycie czy aplikacja regeneruje Session ID po login. Bez regeneracji: atakujący sets victim's session ID PRZED login (e.g., link `?sid=ATTACKER_SID`) → po login atakujący ma authenticated session.

> **Test mostly manual**: 2-step process (set session, then login).

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Get pre-auth session ID**: GET / → Set-Cookie session=X.
2. **Login z sessionem X**: POST /login z cookie session=X.
3. **Compare post-login session ID**: czy session=X (NO regeneration = vulnerable) czy session=Y (regeneracja = OK)?
4. **Test URL session injection**: `?sessionid=ATTACKER` → czy aplikacja akceptuje?

### Co MUSI być sprawdzone (6 punktów)

- [ ] Session ID regenerated post-login
- [ ] Old session ID invalidated po regeneracji
- [ ] Session ID regenerated po privilege change
- [ ] URL-based session injection blocked
- [ ] Cross-domain cookie injection blocked
- [ ] Session regeneration po password change

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Regeneracja Session ID — kluczowa obrona

- **Regeneruj session ID po KAŻDYM zalogowaniu** — to PRIMARY defense przed session fixation
- **Unieważnij stary session ID** po regeneracji — zapobiega reuse starego tokenu
- Regeneruj też po: zmianie uprawnień, zmianie hasła, przelogowaniu, step-up authentication
- Implementacja: `session_regenerate_id(true)` (PHP), `request.getSession().invalidate()` (Java), `req.session.regenerate()` (Express)

### Nie akceptuj session ID z URL

- Session ID powinien być TYLKO w cookies — NIGDY w URL parametrach
- URL z session ID: może być zapisany w logach, referrer header, historia przeglądarki, zakładki
- Wyłącz `session.use_trans_sid` (PHP), nie używaj `;jsessionid=` w URL (Java)

### Walidacja session ID

- Serwer NIE powinien akceptować nieznanego session ID — wymuś wygenerowanie nowego
- Dla każdego nowego cookie session ID, sprawdź czy serwer go wygenerował (server-side state)
- Jeśli atakujący wstawi własny session ID w cookie → odrzuć i wygeneruj nowy

## Pentesterskie deep dive

### Mniej znane techniki

- **Session fixation via subdomain cookie**: cookie z `Domain=.target.com` set by `evil.target.com` (subdomain takeover) → main app.
- **JSESSIONID URL rewrite legacy**: niektóre Tomcat versions dalej używają URL-based session.
- **OAuth state parameter as session fixation**: jeśli OAuth state nie jest random per request, atakujący może preset.

### Common pitfalls

- **session.regenerate() called ale stary session valid**: niektóre frameworki nie destroy old session.

### Świeżynki z research

- **PortSwigger Session labs**: https://portswigger.net/web-security
- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Cookie Editor | Cookie inspection |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/03-Testing_for_Session_Fixation
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.2.1 | Session token regenerated upon login. |
| V3.2.2 | Session ID never accepted from URL. |
