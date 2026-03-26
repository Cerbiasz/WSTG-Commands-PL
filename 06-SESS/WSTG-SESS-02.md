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

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Secure flag

- Cookie wysylane TYLKO przez HTTPS — przegladarka nigdy nie wysle go przez HTTP
- **KRYTYCZNE** nawet jesli serwer nie slucha na porcie 80 — atakujacy MitM moze sproofowac HTTP serwer
- Cookie bez Secure flag moze byc przechwycone w otwartej sieci Wi-Fi

### HttpOnly flag

- Cookie niedostepne dla JavaScript (`document.cookie` nie zwroci go)
- **Ochrona przed XSS** — nawet jesli atakujacy wstrzyknie JS, nie moze wykrasc session cookie
- UWAGA: NIE chroni przed CSRF, session fixation ani innymi atakami

### SameSite attribute

- `SameSite=Strict` — cookie NIE wysylane w cross-site requests (najsilniejsza ochrona CSRF)
  - Moze powodowac problemy UX (np. link z emaila nie zaloguje uzytkownika)
- `SameSite=Lax` — cookie wysylane tylko w top-level navigations (GET) — dobry kompromis
- `SameSite=None; Secure` — cookie wysylane w cross-site (wymagane do third-party cookies)
- Domyslna wartosc w nowoczesnych przegladarkach: `Lax` (jesli nie ustawiono)

### Domain attribute

- **Nie ustawiaj Domain** jesli cookie ma byc dostepne tylko z dokladnej domeny
- `Domain=.example.com` — cookie dostepne ze WSZYSTKICH subdomen (ryzyko: subdomain takeover)
- Im wezszy zakres Domain — tym bezpieczniej

### Path attribute

- Ogranicz Path do minimum wymaganego zakresu (np. `/app/` zamiast `/`)
- UWAGA: Path NIE jest mechanizmem bezpieczenstwa — JavaScript z innej sciezki moze odczytac cookie
- Traktuj jako dodatkowa warstwe, nie primary defense

### Expires / Max-Age

- Cookie sesyjne: **NIE ustawiaj** Expires/Max-Age — cookie wygasa z zamknieciem przegladarki
- Persistent cookies: ustaw najkrotszy mozliwy czas wygasniecia
- Dlugie sesje (Remember Me) = wieksze ryzyko — wymagaj re-autentykacji dla krytycznych akcji

### Cookie Prefixes

- `__Secure-` prefix: cookie MUSI miec flage `Secure` — przegladarka odrzuci je bez Secure
- `__Host-` prefix: cookie MUSI miec `Secure`, `Path=/`, i NIE moze miec `Domain` — najsilniejsza izolacja
- `__Host-` zapobiega subdomain fixation i ogranicza scope do dokladnej domeny

### Dodatkowe praktyki

- Ustaw WSZYSTKIE atrybuty bezpieczenstwa jednoczesnie — brak jednego moze zniweczyc ochrone
- Testuj w roznych przegladarkach — implementacja SameSite moze sie roznic
- Monitoruj Set-Cookie headery w odpowiedziach — reverse proxy/CDN moze je modyfikowac

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| burp-samesite-reporter | Raportowanie flag SameSite w cookies | [GitHub](https://github.com/ldionmarcil/burp-samesite-reporter) |
| Headers Analyzer | Analiza naglowkow bezpieczenstwa HTTP | [BApp Store](https://portswigger.net/bappstore/8b4fe2571ec54983b6d6c21fbfe17cb2) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.3.1 | Cookie Setup | Verify that cookies have the 'Secure' attribute set, and if the '\__Host-' prefix is not used for the cookie name, the '__Secure-' prefix must be used for the cookie name. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.3.2 | Cookie Setup | Verify that each cookie's 'SameSite' attribute value is set according to the purpose of the cookie, to limit exposure to user interface redress attacks and browser-based request forgery attacks, commonly known as cross-site request forgery (CSRF). |
| V3.3.3 | Cookie Setup | Verify that cookies have the '__Host-' prefix for the cookie name unless they are explicitly designed to be shared with other hosts. |
| V3.3.4 | Cookie Setup | Verify that if the value of a cookie is not meant to be accessible to client-side scripts (such as a session token), the cookie must have the 'HttpOnly' attribute set and the same value (e. g. session token) must only be transferred to the client via the 'Set-Cookie' header field. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.3.5 | Cookie Setup | Verify that when the application writes a cookie, the cookie name and value length combined are not over 4096 bytes. Overly large cookies will not be stored by the browser and therefore not sent with requests, preventing the user from using application functionality which relies on that cookie. |
