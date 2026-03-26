# WSTG-SESS-03 — Testing for Session Fixation

## Cele

- Analiza mechanizmu uwierzytelniania i zarzadzania sesja
- Sprawdzenie czy aplikacja akceptuje narzucone tokeny sesji
- Weryfikacja czy session ID zmienia sie po uwierzytelnieniu

## KOMENDY

### Krok 1: Pobranie tokenu sesji PRZED zalogowaniem

```bash
curl -s -I -c pre_login_cookies.txt TARGET/login
cat pre_login_cookies.txt

```

### Krok 2: Zalogowanie z tym samym tokenem

```bash
curl -s -I -b pre_login_cookies.txt -c post_login_cookies.txt TARGET/login -d "user=test&pass=test"
cat post_login_cookies.txt

```

### Krok 3: Porownanie tokenow - powinny byc ROZNE

```bash
diff pre_login_cookies.txt post_login_cookies.txt

```

### Test narzucenia sesji - ustawienie wlasnego session ID

```bash
curl -v -b "PHPSESSID=ATTACKER_CONTROLLED_VALUE" TARGET/login -d "user=test&pass=test" 2>&1 | grep -i "set-cookie"

```

### Sprawdzenie czy serwer akceptuje nieznany session ID

```bash
curl -v -b "PHPSESSID=aaaaaaaaaaaaaaaaaaaaaaaaa" TARGET/dashboard 2>&1 | grep -i "set-cookie"

```

### Sprawdzenie session fixation przez URL

```bash
curl -v "TARGET/login?PHPSESSID=ATTACKER_SESSION" 2>&1 | grep -i "set-cookie"

```

### Sprawdzenie czy token zmienia sie po zmianie uprawnien

```bash
curl -s -I -c cookies1.txt TARGET/login -d "user=normaluser&pass=pass"
curl -s -I -b cookies1.txt -c cookies2.txt TARGET/admin/elevate
diff cookies1.txt cookies2.txt

```

### Sprawdzenie session fixation przez meta tag / JavaScript

```bash
# Testowanie czy aplikacja ustawia cookie na podstawie parametru GET
curl -v "TARGET/page?sessionid=FIXED_VALUE" 2>&1 | grep -i "set-cookie"

```

### Testowanie cross-subdomain session fixation

```bash
curl -v -b "SESSIONID=FIXED_VALUE; Domain=.example.com" TARGET/login -d "user=test&pass=test" 2>&1 | grep -i "set-cookie"

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na analizie zachowania mechanizmu sesji przed i po uwierzytelnieniu.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz aplikacje w przegladarce i zapisz session ID przed logowaniem
2. Zaloguj sie i sprawdz czy session ID sie zmienil
3. W Burp Proxy porownaj wartosci cookie w requestach przed i po logowaniu
4. Sprobuj recznie ustawic cookie sesji w przegladarce (DevTools -> Application -> Cookies)
5. Zaloguj sie i sprawdz czy serwer zaakceptowal narzucony token
6. Przetestuj czy mozna ustawic sesje przez parametr URL
7. Sprawdz czy po wylogowaniu i ponownym zalogowaniu token jest nowy


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Regeneracja Session ID — kluczowa obrona

- **Regeneruj session ID po KAZDYM zalogowaniu** — to PRIMARY defense przed session fixation
- **Uniewazni stary session ID** po regeneracji — zapobiega reuse starego tokenu
- Regeneruj tez po: zmianie uprawnien, zmianie hasla, przelogowaniu, step-up authentication
- Implementacja: `session_regenerate_id(true)` (PHP), `request.getSession().invalidate()` (Java), `req.session.regenerate()` (Express)

### Nie akceptuj session ID z URL

- Session ID powinien byc TYLKO w cookies — NIGDY w URL parametrach
- URL z session ID: moze byc zapisany w logach, referrer header, historia przegladarki, zakladki
- Wylacz `session.use_trans_sid` (PHP), nie uzywaj `;jsessionid=` w URL (Java)

### Walidacja session ID

- Serwer NIE powinien akceptowac nieznanego session ID — wymus wygenerowanie nowego
- PHP: `session.use_strict_mode = 1` — serwer odrzuca nieznane session ID
- Waliduj format session ID — odrzuc wartosci, ktore nie pasuja do oczekiwanego formatu

### Wiazanie sesji z klientem (defence in depth)

- Powiaz sesje z: IP adresem, User-Agent, fingerprint przegladarki
- UWAGA: IP moze sie zmieniac (NAT, mobilne sieci, VPN) — nie blokuj sesji wyłacznie na tej podstawie
- Traktuj jako dodatkowy sygnal — nie jako jedyna weryfikacje

### Cross-subdomain session fixation

- Jesli cookie ma `Domain=.example.com` — atakujacy na `evil.example.com` moze ustawic cookie
- Obrona: uzywaj `__Host-` prefix, nie ustawiaj Domain attribute, subdomain isolation
- Sprawdz czy subdomeny sa bezpieczne — subdomain takeover umozliwia session fixation

### Session fixation przez inne wektory

- **Meta tag/JavaScript**: `<meta http-equiv="Set-Cookie" content="SID=fixed">` — przestarzale ale testuj
- **Cross-site cooking**: atakujacy ustawia cookie z innej domeny (starsze przegladarki)
- **Header injection**: jesli atakujacy kontroluje headery — moze wstrzyknac Set-Cookie

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V7.2.4 | Fundamental Session Management Security | Verify that the application generates a new session token on user authentication, including re-authentication, and terminates the current session token. |
