# WSTG-CLNT-12 — Testing Browser Storage

## Cele

- Determine whether the site is storing sensitive data in client-side storage

## KOMENDY

### Sprawdzenie browser storage z DevTools

```bash
# F12 > Application > Storage (localStorage, sessionStorage, IndexedDB, Cookies)

```

### Automatyczne sprawdzenie via JS console

```bash
# localStorage: Object.keys(localStorage).forEach(k => console.log(k, localStorage[k]))
# sessionStorage: Object.keys(sessionStorage).forEach(k => console.log(k, sessionStorage[k]))

```

### Szukanie wrazliwych danych

```bash
# Tokeny, hasla, PII, klucze API, dane platnosci

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test manualny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz DevTools > Application > Storage
2. Sprawdz localStorage pod katem tokenow, hasel, PII
3. Sprawdz sessionStorage pod katem wrazliwych danych
4. Sprawdz IndexedDB i WebSQL
5. Sprawdz cookies pod katem wrazliwych danych bez flagi Secure/HttpOnly
6. Sprawdz czy dane sa szyfrowane w storage


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md, Session_Management_Cheat_Sheet.md

### Ryzyka przechowywania danych w przegladarce

- **localStorage**: dostepne dla KAZDEGO JavaScript na tej samej domenie — XSS = pelen dostep
- **sessionStorage**: jak localStorage ale per tab — wciaz dostepne przez XSS
- **IndexedDB/WebSQL**: wieksza pojemnosc, te same ryzyka
- **Cookies bez HttpOnly**: dostepne przez `document.cookie` — XSS moze je wykrasc

### Co NIE powinno byc w client-side storage

- **Tokeny sesji / JWT** — uzywaj HttpOnly cookies zamiast localStorage
- **Hasla** — NIGDY nie przechowuj hasel po stronie klienta
- **PII** (dane osobowe): imie, email, adres, PESEL, numer karty
- **Klucze API** — nie umieszczaj w JavaScript / storage — uzywaj backend proxy
- **CSRF tokeny** — powinny byc w HttpOnly cookies lub ukrytych polach formularza

### Obrona

- **HttpOnly cookies** dla tokenow sesji — niedostepne dla JavaScript
- **Minimalizuj dane** w storage — przechowuj MINIMUM potrzebnych informacji
- **Czysc storage przy wylogowaniu**: `localStorage.clear()`, `sessionStorage.clear()`
- **Waliduj dane** odczytane z storage — moga byc zmodyfikowane przez atakujacego lub malware
- **Szyfruj wrazliwe dane** w storage jesli MUSISZ je przechowywac (Web Crypto API)
- **Ustaw krotki TTL** na danych w storage — nie przechowuj danych bez daty wygasniecia

### Testowanie

- DevTools > Application > Storage: przejrzyj WSZYSTKIE dane w localStorage, sessionStorage, IndexedDB, cookies
- Szukaj: tokenow, hasel, kluczy API, PII, danych finansowych
- Sprawdz czy dane sa czyszczone po wylogowaniu
- Sprawdz czy dane sa szyfrowane

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
