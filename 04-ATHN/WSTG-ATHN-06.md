# WSTG-ATHN-06 — Testing for Browser Cache Weaknesses

## Cele

- Sprawdzic czy wrazliwe dane sa przechowywane w cache przegladarki
- Zweryfikowac naglowki kontrolujace cache
- Ocenic ryzyko nieautoryzowanego dostepu do danych z cache

## KOMENDY

### Sprawdzenie naglowkow cache na stronie logowania

```bash
curl -s -I "https://TARGET/login" | grep -iE "cache-control|pragma|expires|etag|last-modified"

```

### Sprawdzenie naglowkow cache na chronionych stronach

```bash
curl -s -I "https://TARGET/api/profile" -H "Authorization: Bearer TOKEN" | grep -iE "cache-control|pragma|expires|etag|last-modified"

curl -s -I "https://TARGET/dashboard" -b "session=SESSION_ID" | grep -iE "cache-control|pragma|expires|etag|last-modified"

curl -s -I "https://TARGET/api/account" -H "Authorization: Bearer TOKEN" | grep -iE "cache-control|pragma|expires|etag|last-modified"

```

### Sprawdzenie pelnych naglowkow odpowiedzi

```bash
curl -s -I "https://TARGET/login"
curl -s -I "https://TARGET/api/profile" -H "Authorization: Bearer TOKEN"

```

### Sprawdzenie strony logowania pod katem autocomplete

```bash
curl -s "https://TARGET/login" | grep -iE "autocomplete"

```

### Sprawdzenie formularzy pod katem autocomplete

```bash
curl -s "https://TARGET/login" | grep -iE "input.*password|input.*user|autocomplete"

```

### Sprawdzenie czy odpowiedzi API maja prawidlowe naglowki cache

```bash
curl -s -I "https://TARGET/api/users" -H "Authorization: Bearer TOKEN" | grep -iE "cache-control|pragma|expires"
curl -s -I "https://TARGET/api/transactions" -H "Authorization: Bearer TOKEN" | grep -iE "cache-control|pragma|expires"

```

### Sprawdzenie naglowkow po wylogowaniu

```bash
curl -s -I "https://TARGET/logout" -b "session=SESSION_ID" | grep -iE "cache-control|pragma|expires|clear-site-data"

```

### Sprawdzenie czy uzyto Clear-Site-Data

```bash
curl -s -I "https://TARGET/logout" -b "session=SESSION_ID" | grep -i "Clear-Site-Data"

```

### Test back button po wylogowaniu (symulacja)

```bash
curl -s -I "https://TARGET/dashboard" -H "If-None-Match: ETAG_VALUE" -b "session=EXPIRED_SESSION"

```

### Sprawdzenie roznych endpointow z wrazliwymi danymi

```bash
for endpoint in /api/profile /api/account /api/billing /api/settings /api/users /dashboard /account; do echo "--- $endpoint ---"; curl -s -I "https://TARGET$endpoint" -H "Authorization: Bearer TOKEN" 2>/dev/null | grep -iE "cache-control|pragma|expires"; echo; done

```

## KOMENDY Z WORDLISTAMI

# Brak wordlist - test konfiguracji naglowkow cache

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie do aplikacji i przejdz na strony z wrazliwymi danymi
2. Wyloguj sie i kliknij przycisk "Wstecz" w przegladarce - sprawdz czy dane sa widoczne z cache
3. W DevTools (Network tab) sprawdz naglowki Cache-Control na kazdej odpowiedzi
4. Sprawdz czy formularze logowania maja autocomplete="off" na polach hasla
5. W DevTools (Application tab) sprawdz Cache Storage i Session/Local Storage
6. Sprawdz czy naglowek Cache-Control zawiera: no-store, no-cache, must-revalidate, private
7. Sprawdz czy naglowek Pragma: no-cache jest ustawiony
8. Przetestuj czy po wylogowaniu dane sa usuwane z pamieci przegladarki (Clear-Site-Data)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Naglowki Cache-Control — prawidlowa konfiguracja

- Strony z wrazliwymi danymi MUSZA miec: `Cache-Control: no-store, no-cache, must-revalidate, private`
- Dodaj `Pragma: no-cache` dla kompatybilnosci z HTTP/1.0
- Ustaw `Expires: 0` lub date w przeszlosci
- **no-store** jest KLUCZOWY — `no-cache` sam w sobie NIE zapobiega zapisowi na dysku
- Nie polegaj na `private` jako jedynej ochronie — chroni przed cache proxy, ale nie przegladarki

### Autocomplete — formularze z wrazliwymi danymi

- Pola hasla: `autocomplete="new-password"` lub `autocomplete="current-password"`
- Formularze logowania: `autocomplete="off"` na calym formularzu LUB na poszczegolnych polach
- Pola kart kredytowych, SSN, dane medyczne: `autocomplete="off"`
- Uwaga: nowoczesne przegladarki moga **ignorowac** `autocomplete="off"` na polach hasla
- Dla kart: uzywaj `autocomplete="cc-number"` z `autocomplete="off"` zaleznie od kontekstu

### Clear-Site-Data — czyszczenie po wylogowaniu

- Naglowek `Clear-Site-Data` pozwala usunac dane z przegladarki po wylogowaniu:
  - `"cache"` — czysc cache HTTP
  - `"cookies"` — usun cookies
  - `"storage"` — usun localStorage, sessionStorage, IndexedDB
  - `"*"` — usun wszystko
- Przyklad: `Clear-Site-Data: "cache", "cookies", "storage"`
- Uzyj przy wylogowaniu i przy zmianie hasla

### ETag i Last-Modified — ryzyko

- **ETag** moze byc uzywany do trackingu uzytkownikow (supercookie)
- Odpowiedzi z wrazliwymi danymi NIE powinny miec ETag ani Last-Modified
- Jesli uzyjesz `no-store`, przegladarka nie powinna uzywac warunkowych requestow

### Back button / historia przegladarki

- `Cache-Control: no-store` zapobiega ladowaniu stron z cache po kliknieciu "Wstecz"
- Bez `no-store` uzytkownik moze zobaczyc dane po wylogowaniu
- Testuj: zaloguj → przejdz na strone z danymi → wyloguj → kliknij "Wstecz"
- Dodatkowa ochrona: JavaScript redirect na stronach chronionych po wykryciu braku sesji

### Co testowac

- Sprawdz naglowki cache na KAZDEJ stronie z wrazliwymi danymi (nie tylko login)
- Sprawdz czy API endpoints zwracaja prawidlowe naglowki cache
- Testuj back button po wylogowaniu — czy dane sa widoczne?
- Sprawdz czy pliki do pobrania (PDF, CSV z danymi) maja prawidlowe naglowki
- Zweryfikuj autocomplete na formularzach z wrazliwymi danymi
- Sprawdz czy uzywany jest Clear-Site-Data przy wylogowaniu

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.3.1 | Client-side Data Protection | Verify that authenticated data is cleared from client storage, such as the browser DOM, after the client or session is terminated. The 'Clear-Site-Data' HTTP response header field may be able to help with this but the client-side should also be able to clear up if the server connection is not available when the session is terminated. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.3.2 | Client-side Data Protection | Verify that the application sets sufficient anti-caching HTTP response header fields (i.e., Cache-Control: no-store) so that sensitive data is not cached in browsers. |
| V14.3.3 | Client-side Data Protection | Verify that data stored in browser storage (such as localStorage, sessionStorage, IndexedDB, or cookies) does not contain sensitive data, with the exception of session tokens. |
