# WSTG-SESS-07 — Testing Session Timeout

## Cel

Audyt timeoutów sesji: idle timeout (15-30 min standard, 2-5 min high-risk), absolute timeout (4-8h max), re-auth dla sensitive ops, czy session valid forever (worst case).

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Idle timeout test**: zaloguj się, czekaj 30 min bez aktywności, próbuj request → czy session expired?
2. **Absolute timeout**: aktywne używanie 8h+ → czy session expires?
3. **Re-auth check**: change password / view sensitive data → czy wymaga re-input current password?
4. **Server vs client timeout**: backend musi enforce timeout (nie tylko frontend redirect).

### Co MUSI być sprawdzone (8 punktów)

- [ ] Idle timeout: 15-30 min (standard) lub 2-5 min (banking)
- [ ] Absolute timeout: 4-8h max
- [ ] Server-side enforcement (nie tylko client redirect)
- [ ] Sensitive operations wymagają re-auth
- [ ] Session valid forever = critical finding
- [ ] Auto-logout warning przed timeout
- [ ] Timeout consistent across channels (web/API/mobile)
- [ ] Session w iframe respects parent timeout

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Idle Timeout (brak aktywności)

- **15-30 minut** dla standardowych aplikacji
- **2-5 minut** dla aplikacji wysokiego ryzyka (bankowość, ochrona zdrowia)
- Po idle timeout: unieważnij sesję server-side + redirect na stronę logowania
- Mierz czas od OSTATNIEGO requestu użytkownika

### Absolute Timeout (całkowity czas sesji)

- **4-8 godzin** — sesja wygasa niezależnie od aktywności
- Zapobiega scenariuszowi: sesja aktywna bez końca przy ciągłym użyciu
- Wymusza ponowne uwierzytelnienie — ogranicza okno czasowe wykradzionego tokenu
- Krótszy absolute timeout = mniejsze ryzyko

### Re-autentykacja dla operacji wrażliwych

- **Zmiana hasła**: wymagaj podania bieżącego hasła
- **Płatności / przelewy**: re-auth lub MFA
- **Eksport danych**: re-auth
- **Zmiana ustawień bezpieczeństwa**: re-auth

### Implementacja

- **Server-side enforcement**: timeout MUSI być enforced server-side, nie tylko client-side redirect
- Per-user storage: `lastActivity` timestamp w session storage
- Check on every request: `if (now - lastActivity > idleTimeout) destroyAndRedirect()`

## Pentesterskie deep dive

### Mniej znane techniki

- **Timeout via heartbeat manipulation**: aplikacja używa AJAX heartbeat do extension - atakujący może keep-alive innym tabem.
- **Refresh token bez TTL**: access token expires ale refresh token valid forever.
- **Session timeout reset on every request including 304**: cached responses extend session.

### Common pitfalls

- **Frontend logout po timeout ale backend session aktywna**: redirect to login but `/api/users/me` w background tab nadal działa.
- **API endpoints bez timeout enforcement**: tylko web-side redirect.

### Świeżynki z research

- **OWASP Session Management CS**: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Repeater | Replay request after timeout |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/07-Testing_Session_Timeout
- OWASP Session Management CS: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.3.1 | Session has absolute and idle timeouts. |
| V3.3.2 | Re-authentication for sensitive operations. |
