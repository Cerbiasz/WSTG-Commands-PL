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

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
