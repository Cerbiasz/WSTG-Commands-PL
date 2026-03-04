# WSTG-ATHZ-02 — Testing for Bypassing Authorization Schema

## Cele

- Assess if unauthenticated, horizontal, or vertical access is possible

## KOMENDY

### Test dostepu bez autentykacji

```bash
curl -s "https://TARGET/admin/dashboard" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/api/users" -o /dev/null -w "%{http_code}\n"

```

### Horizontal privilege escalation

```bash
# Zaloguj sie jako user A, sprobuj dostep do zasobow user B
curl -s "https://TARGET/api/user/2/profile" -H "Cookie: session=USER_A_SESSION"
curl -s "https://TARGET/api/orders/OTHER_USER_ORDER_ID" -H "Cookie: session=USER_A_SESSION"

```

### Vertical privilege escalation

```bash
# Zaloguj sie jako zwykly user, sprobuj dostep do endpointow admina
curl -s "https://TARGET/admin/users" -H "Cookie: session=NORMAL_USER_SESSION"

```

### Forced browsing

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -H "Cookie: session=NORMAL_USER_SESSION" -mc 200 -o output_ffuf_forced.json

```

### Method-based bypass

```bash
curl -X POST "https://TARGET/admin" -H "Cookie: session=NORMAL_USER_SESSION" -o /dev/null -w "%{http_code}\n"

```

### Header-based bypass

```bash
curl -s "https://TARGET/admin" -H "X-Original-URL: /admin" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/admin" -H "X-Forwarded-For: 127.0.0.1" -o /dev/null -w "%{http_code}\n"

```

## KOMENDY Z WORDLISTAMI

### SecLists common paths

```bash
# Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt
# Desktop/WSTG/SecLists-master/Discovery/Web-Content/raft-large-directories.txt

```

### Bug-Bounty-Wordlists 403 bypass

```bash
ffuf -u "https://TARGET/admin" -H "FUZZ: 127.0.0.1" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_header_payloads.txt -mc 200 -o output_ffuf_403bypass_headers.json

ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_url_payloads.txt -mc 200 -o output_ffuf_403bypass_url.json

```

### SecLists 403 bypass

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/403/403_url_payloads.txt -mc 200 -o output_ffuf_seclists_403.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp Autorize extension do automatycznego testowania autoryzacji
2. Zaloguj sie jako rozni uzytkownicy i porownaj dostep do endpointow
3. Testuj IDOR na ID w URL i body requestow
4. Sprawdz forced browsing do chronionych zasobow
5. Testuj HTTP method switching (GET vs POST vs PUT)
6. Testuj header-based bypass (X-Original-URL, X-Forwarded-For)

