# WSTG-SESS-04 — Testing for Exposed Session Variables

## Cele

- Sprawdzenie czy tokeny sesji sa przesylane szyfrowanym kanalem
- Sprawdzenie czy tokeny sesji wyciekaja przez URL, Referer, cache
- Ocena czy tokeny sa przesylane przez GET czy POST

## KOMENDY

### Sprawdzenie czy session ID jest w URL

```bash
curl -v -L TARGET/login -d "user=test&pass=test" 2>&1 | grep -iE "location|set-cookie"
# Jezeli session ID pojawia sie w URL (np. ?PHPSESSID=xxx) - to podatnosc

```

### Sprawdzenie naglowka Referer - wyciek sesji

```bash
curl -v -H "Referer: TARGET/page?SESSIONID=abc123" TARGET/external-link 2>&1

```

### Sprawdzenie czy aplikacja uzywa HTTPS dla tokenow

```bash
curl -v http://TARGET/ 2>&1 | grep -i "set-cookie"
# Jezeli cookie ustawiane przez HTTP (bez Secure flag) - podatnosc

```

### Sprawdzenie cache headers

```bash
curl -s -I TARGET/dashboard | grep -iE "cache-control|pragma|expires"
# Strony z sesja powinny miec: Cache-Control: no-store, no-cache

```

### Sprawdzenie czy token jest w ukrytych polach formularza

```bash
curl -s TARGET/form-page | grep -i "hidden" | grep -i "session"

```

### Sprawdzenie czy token jest w logach serwera (URL)

```bash
curl -v "TARGET/page?token=SESSION_TOKEN_HERE" 2>&1

```

### Sprawdzenie przesylania tokenu GET vs POST

```bash
curl -v "TARGET/action?sessionid=TOKEN" 2>&1
curl -v -d "sessionid=TOKEN" TARGET/action 2>&1

```

### Sprawdzenie Cross-Origin Resource Sharing wycieku sesji

```bash
curl -s -I -H "Origin: https://evil.com" TARGET/api/data | grep -iE "access-control|set-cookie"

```

### Sprawdzenie czy ETag moze byc uzywany do trackowania sesji

```bash
curl -s -I TARGET/page | grep -i "etag"

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na analizie transportu i ekspozycji tokenow sesji.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Proxy sprawdz czy session ID pojawia sie w URL requestow
2. Sprawdz naglowek Referer - czy wyciekaja tokeny do stron zewnetrznych
3. DevTools -> Network -> sprawdz czy tokeny sa przesylane przez HTTPS
4. Sprawdz naglowki Cache-Control na stronach wymagajacych sesji
5. Sprawdz czy tokeny sa widoczne w historii przegladarki (bo byly w URL)
6. W Burp sprawdz czy tokeny sa w parametrach GET zamiast POST
7. Sprawdz logi serwera pod katem zapisanych tokenow sesji


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Session ID NIE w URL

- **NIGDY** nie umieszczaj session ID w URL parametrach — wycieka przez:
  - **Referer header**: klikniecie linku zewnetrznego wysyla URL z tokenem w Referer
  - **Logi serwera**: URL z tokenem zapisywany w access logach, proxy logach, CDN logach
  - **Historia przegladarki**: URL z tokenem dostepny lokalnie
  - **Zakladki**: uzytkownik moze przypadkowo udostepnic URL z tokenem
  - **Udostepnienie URL**: kopiowanie linku z session ID

### Transport tokenow sesji

- Session ID TYLKO w cookies z flagami `Secure`, `HttpOnly`, `SameSite`
- Dane wrazliwe wysylaj przez **POST** — nie GET (GET trafia do logow, historii, cache)
- Alternatywa: `Authorization: Bearer` header dla API — nie wycieknie przez Referer

### Ochrona przed wyciekiem przez Referer

- Ustaw `Referrer-Policy: no-referrer` lub `same-origin` — ogranicza wysylanie Referer header
- Uzywaj `rel="noreferrer"` na linkach zewnetrznych
- W meta tagu: `<meta name="referrer" content="no-referrer">`

### Cache i przechowywanie

- Strony z danymi sesji: `Cache-Control: no-store, no-cache, must-revalidate`
- `Pragma: no-cache` i `Expires: 0` dla kompatybilnosci wstecznej
- Zapobiegaj cachowaniu przez proxy — token w odpowiedzi cachowalnej to wyciek

### Minimalizacja danych w sesji

- Nie przechowuj wrazliwych danych w zmiennych sesji bez potrzeby
- Szyfruj dane sesji przechowywane po stronie serwera
- Sesja powinna zawierac MINIMUM informacji — identyfikator uzytkownika, role, timestamp

### CORS a wyciek sesji

- Sprawdz `Access-Control-Allow-Origin` — nie ustawiaj na `*` z `Allow-Credentials: true`
- Wildcard origin + credentials = kazda strona moze odczytac odpowiedzi z cookies sesji
- Ogranicz CORS do zaufanych domen

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Sensitive Discoverer | Wykrywanie wrazliwych danych w odpowiedziach HTTP | [GitHub](https://github.com/CYS4srl/SensitiveDiscoverer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.2.1 | General Data Protection | Verify that sensitive data is only sent to the server in the HTTP message body or header fields, and that the URL and query string do not contain sensitive information, such as an API key or session token. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.3.3 | Client-side Data Protection | Verify that data stored in browser storage (such as localStorage, sessionStorage, IndexedDB, or cookies) does not contain sensitive data, with the exception of session tokens. |
