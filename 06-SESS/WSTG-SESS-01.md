# WSTG-SESS-01 — Testing for Session Management Schema

## Cele

- Zebranie tokenow sesyjnych i analiza ich struktury
- Ocena losowosci tokenow (entropia)
- Modyfikacja niepodpisanych cookies i analiza odpowiedzi serwera

## KOMENDY

### Pobranie cookies z odpowiedzi serwera

```bash
curl -v -c cookies.txt -b cookies.txt -L TARGET 2>&1 | grep -i "set-cookie"

```

### Zebranie wielu tokenow sesyjnych do analizy

```bash
for i in $(seq 1 100); do curl -s -I TARGET | grep -i "set-cookie" >> session_tokens.txt; done

```

### Analiza dlugosci tokenow

```bash
for i in $(seq 1 50); do curl -s -I TARGET | grep -i "set-cookie" | awk -F'=' '{print $2}' | awk -F';' '{print $1}'; done | awk '{print length, $0}' | sort -n

```

### Sprawdzenie czy token zmienia sie przy kazdym uzyciu

```bash
curl -s -I -c - TARGET | grep -i "set-cookie"
curl -s -I -c - TARGET | grep -i "set-cookie"

```

### Dekodowanie tokenu base64

```bash
echo "TOKEN_VALUE" | base64 -d

```

### Sprawdzenie formatu tokenu (czy zawiera dane uzytkownika)

```bash
curl -s -c - TARGET/login -d "user=test&pass=test" | grep -i "set-cookie"

```

### Burp Sequencer - zbieranie tokenow do analizy entropii

```bash
# 1. Przechwyc request w Burp Proxy
# 2. Wyslij do Sequencer (PPM -> Send to Sequencer)
# 3. Zaznacz token w odpowiedzi
# 4. Start live capture (minimum 10000 tokenow)
# 5. Analizuj wyniki (effective entropy powinno byc > 64 bitow)

```

### Modyfikacja wartosci cookie i obserwacja odpowiedzi

```bash
curl -v -b "SESSIONID=AAAA" TARGET/dashboard
curl -v -b "SESSIONID=0000" TARGET/dashboard
curl -v -b "SESSIONID=test123" TARGET/dashboard

```

### Sprawdzenie przewidywalnosci tokenu (inkrementacja)

```bash
curl -s -I TARGET | grep -i "set-cookie" | awk -F'=' '{print $2}' | awk -F';' '{print $1}'
# Powtorz kilka razy i porownaj wartosci

```

### Testowanie pustego tokenu sesji

```bash
curl -v -b "SESSIONID=" TARGET/dashboard

```

### Testowanie tokenu z inna dlugoscia

```bash
curl -v -b "SESSIONID=$(python3 -c 'print("A"*500)')" TARGET/dashboard

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na analizie entropii i struktury tokenow zbieranych z aplikacji.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz DevTools (F12) -> Application -> Cookies - sprawdz wszystkie ustawione cookies
2. W Burp Proxy przejrzyj odpowiedzi z naglowkami Set-Cookie
3. Uzyj Burp Sequencer do automatycznej analizy entropii tokenow
4. Sprawdz czy tokeny zawieraja zakodowane dane uzytkownika (base64, hex)
5. Porownaj tokeny roznych uzytkownikow - czy widac wzorzec
6. Sprawdz czy token zmienia sie po zalogowaniu/wylogowaniu
7. Przetestuj modyfikacje poszczegolnych czesci tokenu w Burp Repeater


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Wlasciwosci Session ID

- **Entropia**: Session ID musi miec minimum **64 bitow entropii** — uzyj CSPRNG (Cryptographically Secure PRNG)
- **Dlugosc**: min 16 znakow hex (64 bitow entropii) — przy base64 odpowiednio mniej znakow
- **Zawartosc**: Session ID musi byc bezznaczeniowy (meaningless) — NIE moze zawierac danych uzytkownika, PII, ani logiki biznesowej
- **Nazwa**: zmien domyslna nazwe sesji frameworka (PHPSESSID, JSESSIONID, ASP.NET_SessionId) na generyczna np. `id` — utrudnia fingerprinting
- Jesli czesc ID jest stala/przewidywalna — efektywna entropia jest zmniejszona, wydluz ID

### Implementacja zarzadzania sesjami

- Uzywaj **wbudowanego zarzadzania sesjami frameworka** (J2EE, ASP.NET, PHP) — nie twórz wlasnego
- Preferuj **cookies** jako mechanizm wymiany Session ID — URL parameters ujawniaja ID w logach, Referer, historii przegladarki
- Jesli uzytkownik przesyla Session ID innym mechanizmem niz cookie (np. URL param) — **odrzuc go** (obrona przed session fixation)

### Cookie Attributes

- **Secure**: WYMAGANY — session cookie TYLKO przez HTTPS; bez tej flagi atakujacy moze wymusic HTTP i przechwycic cookie
- **HttpOnly**: WYMAGANY — blokuje dostep JavaScript (document.cookie) do cookie; chroni przed kradzeza sesji przez XSS
- **SameSite**: `Strict` lub `Lax` — zapobiega wysylaniu cookie w cross-site requests (ochrona przed CSRF)
- **Domain**: NIE ustawiaj (restrykcja do origin server) — zbyt permisywna wartosc (np. example.com) pozwala na ataki cross-subdomain
- **Path**: ustaw jak najbardziej restrykcyjnie — ograniczaj do sciezki aplikacji

### Session Lifecycle

- **Regeneruj Session ID** po kazdym zalogowaniu i zmianie uprawnien (privilege escalation)
- Regeneruj takze po przejsciu z HTTP na HTTPS — cookie musi byc ustawione PO przekierowaniu
- Ustaw **session timeout** — idle timeout (np. 15-30 min) i absolute timeout (np. 8-12h)
- **Logout**: uniewazni sesje po stronie serwera, usun cookie, wyczysc dane sesji
- Nie mieszaj HTTP i HTTPS na tej samej domenie — ujawnia session ID

### Transport Layer Security

- CALA sesja musi byc przez HTTPS — nie tylko logowanie
- Nie przechodzic z HTTPS na HTTP w trakcie sesji — ujawnia session ID w sieci
- Implementuj HSTS (HTTP Strict Transport Security) jako dodatkowa ochrone
- TLS NIE chroni przed: predykcja session ID, brute force, client-side tampering, session fixation

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AuthHeader Updater | Automatyczne aktualizowanie tokenow uwierzytelnienia | [GitHub](https://github.com/sampsonc/AuthHeaderUpdater) |
| Cookie Decrypter | Deszyfrowanie i dekodowanie roznych typow cookies | [GitHub](https://github.com/SolomonSklash/cookie-decrypter) |
