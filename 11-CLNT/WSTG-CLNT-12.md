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

