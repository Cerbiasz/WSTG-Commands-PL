# WSTG-ATHN-05 — Testing for Vulnerable Remember Password

## Cele

- Zwalidowac zarzadzanie sesjami dla funkcji "zapamietaj mnie"
- Sprawdzic bezpieczenstwo tokena remember-me
- Ocenic czy token moze byc odgadniety lub ponownie uzyty

## KOMENDY

### Logowanie z opcja remember me i analiza cookies

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass","remember":true}' -c cookies_remember.txt -v 2>&1

```

### Logowanie bez remember me i porownanie cookies

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass","remember":false}' -c cookies_normal.txt -v 2>&1

```

### Porownanie cookies

```bash
diff cookies_remember.txt cookies_normal.txt

```

### Analiza tokena remember-me

```bash
cat cookies_remember.txt

```

### Dekodowanie Base64 tokena remember-me

```bash
echo "REMEMBER_ME_TOKEN_VALUE" | base64 -d

```

### Dekodowanie JWT tokena

```bash
echo "JWT_TOKEN_VALUE" | cut -d'.' -f1 | base64 -d 2>/dev/null; echo
echo "JWT_TOKEN_VALUE" | cut -d'.' -f2 | base64 -d 2>/dev/null; echo

```

### Sprawdzenie atrybutow cookie

```bash
curl -s -I "https://TARGET/" -b cookies_remember.txt 2>&1 | grep -i "Set-Cookie"

```

### Proba uzycia starego tokena po zmianie hasla

```bash
curl -s "https://TARGET/api/profile" -b cookies_remember.txt -v

```

### Proba uzycia tokena po wylogowaniu

```bash
curl -s "https://TARGET/api/logout" -b cookies_remember.txt -v
curl -s "https://TARGET/api/profile" -b cookies_remember.txt -v

```

### Test przewidywalnosci tokena - wielokrotne logowanie

```bash
for i in $(seq 1 5); do echo "--- Proba $i ---"; curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass","remember":true}' -v 2>&1 | grep -i "set-cookie"; done

```

### Sprawdzenie czasu wygasniecia cookie

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass","remember":true}' -v 2>&1 | grep -iE "expires|max-age"

```

### Proba manipulacji tokenem

```bash
curl -s "https://TARGET/api/profile" -b "remember_me=admin" -v
curl -s "https://TARGET/api/profile" -b "remember_me=1" -v
curl -s "https://TARGET/api/profile" -H "Cookie: remember_token=MODIFIED_TOKEN" -v

```

### Sprawdzenie flag bezpieczenstwa cookie

```bash
curl -s -v "https://TARGET/api/login" -X POST -d '{"username":"testuser","password":"testpass","remember":true}' -H "Content-Type: application/json" 2>&1 | grep -iE "httponly|secure|samesite"

```

## KOMENDY Z WORDLISTAMI

# Brak wordlist - test logiczny analizy tokena remember-me

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie z opcja "Zapamietaj mnie" i przeanalizuj ustawione cookies w DevTools
2. Sprawdz czy cookie remember-me ma flagi: Secure, HttpOnly, SameSite
3. W Burp Suite sprawdz wartosc tokena - czy jest losowy czy przewidywalny
4. Przetestuj wielokrotne logowanie i porownaj generowane tokeny
5. Sprawdz czy token zawiera dane uzytkownika (username, ID) w jawnej formie
6. Przetestuj czy zmiana hasla uniewaznaia token remember-me
7. Sprawdz czas wygasniecia cookie (czy nie jest zbyt dlugi)
8. Przetestuj czy token dziala po wylogowaniu z innej sesji


---

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
