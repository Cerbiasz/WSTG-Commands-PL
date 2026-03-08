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

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md

- Nie przechowuj wrazliwych danych w localStorage/sessionStorage — dostepne dla JS (XSS)
- Waliduj dane odczytane z storage — moga byc zmodyfikowane przez atakujacego
- Czysc storage przy wylogowaniu
- Uzywaj HttpOnly cookies zamiast storage dla tokenow sesji

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
