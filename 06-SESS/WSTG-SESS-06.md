# WSTG-SESS-06 — Testing for Logout Functionality

## Cele

- Ocena interfejsu wylogowania (dostepnosc na kazdej stronie)
- Analiza czy sesja jest prawidlowo uniewazniania po wylogowaniu
- Sprawdzenie timeout sesji po wylogowaniu

## KOMENDY

### Krok 1: Zaloguj sie i zapisz cookie sesji

```bash
curl -s -c session_cookies.txt -L TARGET/login -d "user=test&pass=test"
cat session_cookies.txt

```

### Krok 2: Potwierdz ze sesja dziala

```bash
curl -s -b session_cookies.txt TARGET/dashboard | head -20

```

### Krok 3: Wyloguj sie

```bash
curl -s -b session_cookies.txt -c logout_cookies.txt TARGET/logout
# lub
curl -s -b session_cookies.txt -X POST TARGET/logout

```

### Krok 4: Sprobuj uzyc starej sesji po wylogowaniu

```bash
curl -s -b session_cookies.txt TARGET/dashboard | head -20
# Powinien byc redirect do logowania lub blad 401/403

```

### Test przycisku wstecz po wylogowaniu

```bash
# Po wylogowaniu uzyj przegladarki -> Back button
# Sprawdz czy strona z cache jest wyswietlana

```

### Sprawdzenie czy cookie jest usuwane po wylogowaniu

```bash
curl -v -b session_cookies.txt TARGET/logout 2>&1 | grep -i "set-cookie"
# Powinno byc: Set-Cookie: SESSIONID=; expires=Thu, 01 Jan 1970

```

### Sprawdzenie czy wylogowanie dziala po stronie serwera

```bash
curl -s -b session_cookies.txt TARGET/dashboard -o /dev/null -w "%{http_code}"
# Po wylogowaniu powinien byc 302 lub 401

```

### Test wielu kart/okien - wylogowanie w jednym powinno wplynac na inne

```bash
# Otworz dwie karty z ta sama sesja
# Wyloguj sie w jednej
# Sprawdz druga - czy sesja nadal dziala

```

### Sprawdzenie czy token JWT jest uniewazniony (blacklist/revoke)

```bash
curl -s -H "Authorization: Bearer OLD_JWT_TOKEN" TARGET/api/dashboard

```

### Test wylogowania przez rozne metody (GET vs POST)

```bash
curl -v TARGET/logout 2>&1
curl -v -X POST TARGET/logout 2>&1

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na weryfikacji zachowania sesji po wylogowaniu.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie i skopiuj cookie sesji z DevTools
2. Kliknij wyloguj
3. Wklej skopiowane cookie z powrotem do DevTools -> Application -> Cookies
4. Odswierz strone - czy sesja nadal dziala? (nie powinna)
5. Sprawdz przycisk wstecz przegladarki po wylogowaniu
6. Sprawdz czy cache przegladarki nie wyswietla chronionych stron
7. W Burp Repeater wyslij request z tokenem sesji sprzed wylogowania
8. Sprawdz czy opcja wylogowania jest dostepna na kazdej stronie


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

- Uniwaznij sesje po stronie serwera przy wylogowaniu — nie tylko usuwaj cookie
- Wyczysc wszystkie cookies sesyjne po stronie klienta
- Uniwaznij wszystkie powiazane tokeny (access, refresh, JWT)
- Sprawdz czy przycisk wylogowania jest latwo dostepny i widoczny

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
