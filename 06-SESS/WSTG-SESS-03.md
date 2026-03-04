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

