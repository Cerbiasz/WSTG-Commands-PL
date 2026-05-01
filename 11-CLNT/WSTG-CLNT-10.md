# WSTG-CLNT-10 — Testing WebSockets

## Cel

Weryfikacja WebSocket security: użycie WSS (TLS), origin validation w handshake (CSWSH defense), input validation per message, rate limiting, authentication na każdej wiadomości.

> **Test mostly manual**: WebSocket wymaga Burp WebSockets History review + custom messages. Nuclei nie wykrywa WS w HTTP fuzzing.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **WS endpoint discovery**: Burp WebSockets History + grep w JS bundle: `new WebSocket(`.
2. **WSS vs WS**: czy aplikacja używa wss:// (encrypted) — ws:// = plaintext.
3. **Origin validation test**: spróbować connection z attacker page do `wss://target.com/socket` — czy backend waliduje Origin header w handshake?
4. **Auth per message**: każda wiadomość WS musi być authenticated — nie tylko handshake.
5. **Input validation**: testować injection (XSS, SQLi, command) przez WS messages.
6. **Rate limiting**: send burst messages — czy backend limituje?

### Co MUSI być sprawdzone (10 punktów)

- [ ] WSS (encrypted) vs WS (plain)
- [ ] Origin validation w handshake (CSWSH defense)
- [ ] Auth token w handshake / first message
- [ ] Auth verification per message (nie tylko handshake)
- [ ] Input validation (XSS/SQLi/cmd injection w messages)
- [ ] Output encoding (czy wiadomości z WS są escape przed renderowaniem w DOM?)
- [ ] Rate limiting per connection / per user
- [ ] Connection timeout (max session time)
- [ ] Message size limits
- [ ] Heartbeat/ping-pong dla detect dead connections

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — WebSocket_Security_Cheat_Sheet.md

### Cross-Site WebSocket Hijacking (CSWSH)

- Analogiczny do CSRF ale dla WebSocket — atakujący inicjuje WS connection z przeglądarki ofiary
- WebSocket handshake jest HTTP request — przeglądarka automatycznie dołącza cookies
- Jeśli serwer nie waliduje **Origin header** — atakujący może nawiązać połączenie z dowolnej strony
- **Obrona**: waliduj Origin header w handshake — odrzuć jeśli nie pochodzi z zaufanej domeny

### Transport Security

- **WSS (WebSocket Secure)** zamiast WS — szyfrowany kanał (TLS)
- WS bez szyfrowania = dane w plaintext — atakujący MitM może odczytać/modyfikować wiadomości
- Ustaw cookies sesji z flagami: `Secure`, `HttpOnly`, `SameSite`

### Autentykacja i autoryzacja

- **Uwierzytelniaj** połączenia WebSocket **NIEZALEŻNIE** od HTTP session
- Przekaż token w pierwszej wiadomości WS lub w query string handshake (mniej bezpieczne — logi)
- Sprawdzaj uprawnienia na KAŻDEJ wiadomości — nie tylko przy handshake
- Implementuj session timeout na WS — połączenie nie powinno żyć wiecznie

### Input Validation na wiadomościach

- **Waliduj WSZYSTKIE wiadomości** po stronie serwera — WS to dwukierunkowy kanał
- Testuj injection: XSS, SQLi, command injection — w wiadomościach WS
- Sprawdź czy dane z WS są **sanityzowane przed renderowaniem** w DOM (XSS via WS)
- Waliduj format: JSON schema validation, typ danych, długość

### Rate Limiting i DoS

- Implementuj **rate limiting na wiadomości** — zapobiegaj flooding
- Ogranicz rozmiar wiadomości — zapobiegaj memory exhaustion
- Ustaw max jednoczesnych połączeń per użytkownik/IP
- Implementuj heartbeat/ping-pong — wykrywaj i zamykaj martwe połączenia

### Logging

- Loguj handshake (Origin, IP, UA, timestamp)
- Loguj anomalie: duża ilość wiadomości, nieprawidłowe formaty, próby injection

## Pentesterskie deep dive

### Mniej znane techniki

- **CSWSH chain → privilege escalation**: gdy WS pozwala na admin commands i Origin nie sprawdzany — atakujący w XSS na innej domenie wykonuje admin actions.
- **Session prediction in WS auth**: jeśli session ID przesyłany w query string handshake → loguje się w access logs/proxy logs.
- **Subprotocol negotiation**: `Sec-WebSocket-Protocol` może akceptować różne subprotocols z różnymi handlers — różne entry points.
- **WebSocket smuggling**: HTTP/1 → HTTP/2 conversion może zaprezentować WS handshake jako regular HTTP, bypass-ujący WS-specific defenses (PortSwigger research).
- **Browser extension hijacking via WS**: malicious extension może hookować WebSocket constructor — out-of-scope ale relevant.

### Common pitfalls

- **Origin nie sprawdzany "for legacy clients"**: legacy mobile app nie wysyła Origin → backend akceptuje wszystkie → CSWSH possible.
- **JSON parse w handler bez validation**: `JSON.parse(event.data)` z ws message + then innerHTML render = XSS via WS.

### Świeżynki z research

- **PortSwigger WebSocket lab**: https://portswigger.net/web-security/websockets
- **HackTricks WebSocket**: https://book.hacktricks.xyz/pentesting-web/websocket-attacks
- **Christian Mehlmauer WebSocket research**: https://firefart.at/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| WebSocket Smart Fuzzer | WS fuzzing | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/10-Testing_WebSockets
- OWASP WebSocket CS: https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html
- PortSwigger WebSocket: https://portswigger.net/web-security/websockets
- HackTricks WebSocket: https://book.hacktricks.xyz/pentesting-web/websocket-attacks
- RFC 6455 (WebSocket): https://datatracker.ietf.org/doc/html/rfc6455

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.5.1 | WebSocket (L1) | WSS (TLS) used. |
| V13.5.2 | WebSocket (L1) | Origin validated in handshake. |
| V13.5.3 | WebSocket (L2) | Authentication per message. |
