# WSTG-INPV-03 — Testing for HTTP Verb Tampering

## Cele

- Test HTTP verb tampering and access control bypass

## KOMENDY

### Testowanie roznych metod HTTP

```bash
curl -X GET "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X POST "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X PUT "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X DELETE "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X PATCH "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X OPTIONS "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X HEAD "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X TRACE "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X CONNECT "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"

```

### Niestandardowe metody

```bash
curl -X JEFF "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"
curl -X FOO "https://TARGET/admin" -o /dev/null -w "%{http_code}\n"

```

### Nmap HTTP methods

```bash
nmap --script http-methods -p 80,443 TARGET -oN output_nmap_methods.txt

```

### Method override headers

```bash
curl -X POST "https://TARGET/admin" -H "X-HTTP-Method-Override: PUT" -o /dev/null -w "%{http_code}\n"
curl -X POST "https://TARGET/admin" -H "X-Method-Override: DELETE" -o /dev/null -w "%{http_code}\n"
curl -X POST "https://TARGET/admin" -H "X-HTTP-Method: PATCH" -o /dev/null -w "%{http_code}\n"

```

## KOMENDY Z WORDLISTAMI

### SecLists HTTP request methods

```bash
ffuf -u "https://TARGET/admin" -w Desktop/WSTG/SecLists-master/Fuzzing/http-request-methods.txt -X FUZZ -mc all -o output_ffuf_methods.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp Repeater do testowania kazdej metody HTTP na chronionych endpointach
2. Porownaj odpowiedzi dla roznych metod (200 vs 403 vs 405)
3. Sprawdz czy zmiana metody omija autentykacje lub autoryzacje
4. Testuj method override headers w polaczeniu z POST
5. Sprawdz TRACE method pod katem XST (Cross-Site Tracing)

