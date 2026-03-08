# WSTG-CLNT-07 — Testing Cross Origin Resource Sharing (CORS)

## Cele

- Identify endpoints that implement CORS
- Ensure that the CORS configuration is secure or harmless

## KOMENDY

### Test CORS configuration

```bash
curl -sI "https://TARGET/api/data" -H "Origin: https://evil.com" | grep -i "access-control"
curl -sI "https://TARGET/api/data" -H "Origin: null" | grep -i "access-control"
curl -sI "https://TARGET/api/data" -H "Origin: https://TARGET.evil.com" | grep -i "access-control"
curl -sI "https://TARGET/api/data" -H "Origin: https://evilTARGET.com" | grep -i "access-control"

```

### Sprawdzenie niebezpiecznych konfiguracji

```bash
# Access-Control-Allow-Origin: * (z credentials)
# Access-Control-Allow-Origin: <reflected origin>
# Access-Control-Allow-Credentials: true

```

### Preflight request

```bash
curl -sI "https://TARGET/api/data" -X OPTIONS -H "Origin: https://evil.com" -H "Access-Control-Request-Method: PUT" | grep -i "access-control"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings CORS

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/CORS Misconfiguration/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Wyslij request z Origin: https://evil.com i sprawdz ACAO header
2. Testuj rozne warianty origin (null, subdomain, suffix)
3. Sprawdz czy ACAC: true jest ustawione z wildcard origin
4. Stworz PoC HTML z fetch() do testowania exfiltracji danych
5. Sprawdz czy pre-flight requests sa poprawnie obslugiwane


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Additional CORS Checks | Testowanie blednych konfiguracji CORS | [GitHub](https://github.com/ybieri/Additional_CORS_Checks) |
