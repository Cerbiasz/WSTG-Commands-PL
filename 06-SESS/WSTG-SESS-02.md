# WSTG-SESS-02 — Testing for Cookies Attributes

## Cele

- Sprawdzenie poprawnej konfiguracji atrybutow bezpieczenstwa cookies
- Weryfikacja flag: Secure, HttpOnly, SameSite, Path, Domain, Expires

## KOMENDY

### Sprawdzenie wszystkich atrybutow cookies w odpowiedzi

```bash
curl -s -I TARGET | grep -i "set-cookie"

```

### Szczegolowa analiza atrybutow cookies

```bash
curl -s -I TARGET/login -d "user=test&pass=test" 2>&1 | grep -i "set-cookie"

```

### Sprawdzenie flagi Secure

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -i "secure"

```

### Sprawdzenie flagi HttpOnly

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -i "httponly"

```

### Sprawdzenie flagi SameSite

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -i "samesite"

```

### Sprawdzenie atrybutu Path

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -i "path"

```

### Sprawdzenie atrybutu Domain

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -i "domain"

```

### Sprawdzenie atrybutu Expires/Max-Age

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -iE "expires|max-age"

```

### Pelna analiza cookies z logowaniem

```bash
curl -v -c cookies.txt TARGET/login -d "user=test&pass=test" 2>&1 | grep -i "set-cookie"

```

### Sprawdzenie czy sesyjne cookie nie jest persistentne

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -iE "expires|max-age"
# Cookie sesyjne NIE powinno miec atrybutu Expires/Max-Age

```

### Sprawdzenie cookie przez HTTP (bez SSL) - test flagi Secure

```bash
curl -s -I http://TARGET | grep -i "set-cookie"

```

### Testowanie cookie prefixow (__Secure- i __Host-)

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -E "__Secure-|__Host-"

```

### Nmap skrypt do sprawdzenia cookies

```bash
nmap -p 443 --script http-cookie-flags TARGET

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na inspekcji atrybutow cookies w odpowiedziach HTTP.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz DevTools (F12) -> Application -> Cookies - sprawdz atrybuty kazdego cookie
2. Sprawdz czy cookie sesyjne ma flage Secure (tylko HTTPS)
3. Sprawdz czy cookie sesyjne ma flage HttpOnly (niedostepne z JS)
4. Sprawdz atrybut SameSite (powinien byc Strict lub Lax)
5. Sprawdz czy Path jest ograniczony do wymaganego katalogu
6. Sprawdz czy Domain nie jest zbyt szeroki (np. .example.com zamiast app.example.com)
7. Sprawdz czy cookie sesyjne nie ma atrybutu Expires (powinno wygasac z sesja przegladarki)
8. W konsoli przegladarki wykonaj document.cookie - cookie z HttpOnly nie powinno byc widoczne


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md, Cookie_Theft_Mitigation_Cheat_Sheet.md

- Ustaw flage `Secure` — cookie wysylane tylko przez HTTPS
- Ustaw flage `HttpOnly` — cookie niedostepne dla JavaScript (ochrona przed XSS)
- Ustaw `SameSite=Strict` lub `Lax` — ochrona przed CSRF
- Ogranicz `Path` i `Domain` do minimum wymaganego zakresu
- Ustaw krotki czas wygasniecia — unikaj sesji trwalych bez potrzeby

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| burp-samesite-reporter | Raportowanie flag SameSite w cookies | [GitHub](https://github.com/ldionmarcil/burp-samesite-reporter) |
| Headers Analyzer | Analiza naglowkow bezpieczenstwa HTTP | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |
