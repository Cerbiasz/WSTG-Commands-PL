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

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### BOLA/IDOR — #1 podatnosc API (OWASP API Top 10)

- **Broken Object Level Authorization** — najczestszy typ podatnosci w API
- Atakujacy zmienia ID obiektu w URL/body aby uzyskac dostep do cudzych danych
- Dotyczy: GET (odczyt), PUT/PATCH (modyfikacja), DELETE (usuwanie)

### Gdzie szukac BOLA

| Endpoint | Atak |
|----------|------|
| `/api/users/{id}` | Zmien `id` na innego uzytkownika |
| `/api/orders/{id}` | Odczytaj zamowienia innego uzytkownika |
| `/api/users/{id}/documents` | Nested resources innego uzytkownika |
| `/api/invoices/{id}/download` | Pobierz fakture innego uzytkownika |
| Request body: `{"user_id": 123}` | Zmien user_id na cudze |

### Techniki testowania

- **Horizontal**: user A probuje CRUD na obiektach user B (ten sam poziom uprawnien)
- **Vertical**: user probuje CRUD na obiektach admina (rozny poziom uprawnien)
- **ID brute force**: sekwencyjne ID → iteruj 1,2,3... — znajdz cudze obiekty
- **UUID prediction**: jesli UUID v1 — zawiera timestamp i MAC, mozliwe do odgadniecia
- **Parameter pollution**: `?user_id=1&user_id=2` — ktory ID uzyje backend?
- **Method switching**: GET dziala z auth, ale PUT/DELETE pomija sprawdzenie?

### Obrona

- Sprawdzaj autoryzacje na **KAZDYM** endpoincie, **KAZDEJ** metodzie HTTP
- Uzyj **UUID v4** zamiast sekwencyjnych ID — ale to NIE jest obrona (defense-in-depth)
- Implementuj **ABAC** (Attribute-Based Access Control) lub **ReBAC** (Relationship-Based)
- Centralna warstwa autoryzacji — nie w kazdym kontrolerze osobno
- Loguj i alertuj na proby dostepu do cudzych obiektow

### REST API — ogolne bezpieczenstwo

- Waliduj `Content-Type` — odrzucaj nieoczekiwane typy
- Rate limituj wszystkie endpointy — szczegolnie auth i wyszukiwanie
- Waliduj parametry: typy, zakresy, dlugosci
- Zwracaj prawidlowe kody: 401 (brak auth), 403 (brak uprawnien), 404 (nie znaleziono)
- Wymuszaj HTTPS — nie akceptuj HTTP
- Implementuj CORS prawidlowo — nie uzywaj wildcard Origin z credentials

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Swurg | Parsowanie i testowanie API na podstawie Swagger/OpenAPI | [GitHub](https://github.com/AresS31/swurg) |
| SwaggerParser | Import definicji Swagger do Burp | [GitHub](https://github.com/AresS31/SwaggerParser-BurpExtension) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.2.2 | General Authorization Design | Verify that the application ensures that data-specific access is restricted to consumers with explicit permissions to specific data items to mitigate insecure direct object reference (IDOR) and broken object level authorization (BOLA). |
| V8.3.1 | Operation Level Authorization | Verify that the application enforces authorization rules at a trusted service layer and doesn't rely on controls that an untrusted consumer could manipulate, such as client-side JavaScript. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.2.3 | General Authorization Design | Verify that the application ensures that field-level access is restricted to consumers with explicit permissions to specific fields to mitigate broken object property level authorization (BOPLA). |
