# WSTG-BUSL-01 — Test Business Logic Data Validation

## Cele

- Zidentyfikowac punkty wstrzykniecia danych
- Zwalidowac kontrole po stronie backendu

## KOMENDY

### Testowanie negatywnych wartosci

```bash
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": -1, "price": 100}'
curl -v -X POST TARGET/api/transfer -H "Content-Type: application/json" -d '{"amount": -1000}'

```

### Testowanie ekstremalnych wartosci

```bash
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": 99999999}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": 0}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"price": 0.001}'

```

### Testowanie type confusion

```bash
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": "abc"}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": true}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": null}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": []}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": {}}'

```

### Testowanie integer overflow

```bash
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": 2147483647}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": 2147483648}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"quantity": 9999999999999999}'

```

### Testowanie float precision

```bash
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"price": 0.1 + 0.2}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"price": 1e308}'
curl -v -X POST TARGET/api/order -H "Content-Type: application/json" -d '{"price": -1e308}'

```

### Testowanie specjalnych znakow w polach tekstowych

```bash
curl -v -X POST TARGET/api/user -H "Content-Type: application/json" -d '{"name": "<script>alert(1)</script>"}'
curl -v -X POST TARGET/api/user -H "Content-Type: application/json" -d '{"name": "admin'\''--"}'
curl -v -X POST TARGET/api/user -H "Content-Type: application/json" -d '{"email": "test@test@test.com"}'

```

### Testowanie dodatkowych nieoczekiwanych pol

```bash
curl -v -X POST TARGET/api/register -H "Content-Type: application/json" -d '{"user": "test", "pass": "test", "role": "admin"}'
curl -v -X POST TARGET/api/register -H "Content-Type: application/json" -d '{"user": "test", "pass": "test", "isAdmin": true}'

```

### Burp Intruder - automatyczne fuzzowanie wartosci

```bash
# 1. Przechwytuj request z parametrami
# 2. Wyslij do Intruder
# 3. Ustaw pozycje na wartosci parametrow
# 4. Uzyj listy big-list-of-naughty-strings.txt

```

## KOMENDY Z WORDLISTAMI

### Fuzzowanie parametrow z naughty strings (SecLists)

```bash
ffuf -u TARGET/api/search -X POST -H "Content-Type: application/json" -d '{"query": "FUZZ"}' -w Desktop/WSTG/SecLists-master/Fuzzing/big-list-of-naughty-strings.txt -mc all -fc 200 -c

```

### Fuzzowanie z debug param names (fuzzdb business-logic)

```bash
ffuf -u "TARGET/page?FUZZ=true" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/CommonDebugParamNames.txt -mc all -c

```

### Fuzzowanie z debug param names JSON (fuzzdb)

```bash
ffuf -u "TARGET/api/debug" -X POST -H "Content-Type: application/json" -d '{"FUZZ": true}' -w Desktop/WSTG/fuzzdb-master/attack/business-logic/DebugParams.Json.fuzz.txt -mc all -c

```

### Fuzzowanie z common method names (fuzzdb)

```bash
ffuf -u "TARGET/api/FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/CommonMethodNames.txt -mc all -c

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Suite -> Repeater: modyfikuj wartosci parametrow (negatywne, zerowe, ogromne)
2. Testuj walidacje po stronie serwera usuwajac walidacje JavaScript (DevTools)
3. Sprawdz czy backend akceptuje dane ktore frontend odrzuca
4. Testuj granice wartosci: min-1, min, max, max+1
5. Sprawdz czy mozna przeslac puste wymagane pola
6. Testuj podwojne parametry: ?id=1&id=2 (HTTP Parameter Pollution)
7. Sprawdz czy filtrowanie/sanityzacja dziala na backendzie a nie tylko na frontendzie

