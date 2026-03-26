# WSTG-IDNT-03 — Test Account Provisioning Process

## Cele

- Zweryfikowac ktore konta moga tworzyc (provisionowac) inne konta
- Sprawdzic czy proces tworzenia kont jest prawidlowo zabezpieczony
- Ocenic czy istnieja luki w procesie provisioningu

## KOMENDY

### Sprawdzenie endpointu tworzenia uzytkownikow jako admin

```bash
curl -s -X POST "https://TARGET/api/admin/users" -H "Authorization: Bearer ADMIN_TOKEN" -H "Content-Type: application/json" -d '{"username":"newuser","password":"Test@1234","email":"new@test.com","role":"user"}' -v

```

### Proba tworzenia uzytkownika jako zwykly user

```bash
curl -s -X POST "https://TARGET/api/admin/users" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"username":"newuser2","password":"Test@1234","email":"new2@test.com","role":"user"}' -v

```

### Proba tworzenia konta admina jako zwykly user

```bash
curl -s -X POST "https://TARGET/api/admin/users" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"username":"newadmin","password":"Test@1234","email":"newadmin@test.com","role":"admin"}' -v

```

### Proba tworzenia konta bez autoryzacji

```bash
curl -s -X POST "https://TARGET/api/admin/users" -H "Content-Type: application/json" -d '{"username":"noauth","password":"Test@1234","email":"noauth@test.com","role":"user"}' -v

```

### Sprawdzenie listy uzytkownikow (admin endpoint)

```bash
curl -s "https://TARGET/api/admin/users" -H "Authorization: Bearer ADMIN_TOKEN" -v
curl -s "https://TARGET/api/admin/users" -H "Authorization: Bearer USER_TOKEN" -v
curl -s "https://TARGET/api/admin/users" -v

```

### Proba modyfikacji istniejacego konta

```bash
curl -s -X PUT "https://TARGET/api/admin/users/1" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"role":"admin"}' -v

```

### Proba usuwania konta jako zwykly user

```bash
curl -s -X DELETE "https://TARGET/api/admin/users/2" -H "Authorization: Bearer USER_TOKEN" -v

```

### Proba dezaktywacji konta

```bash
curl -s -X PATCH "https://TARGET/api/admin/users/2" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"active":false}' -v

```

### Sprawdzenie endpointow invite/provision

```bash
curl -s -X POST "https://TARGET/api/invite" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"email":"invited@test.com","role":"admin"}' -v

```

### Testowanie bulk provisioning

```bash
curl -s -X POST "https://TARGET/api/admin/users/bulk" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '[{"username":"bulk1","role":"admin"},{"username":"bulk2","role":"admin"}]' -v

```

### Sprawdzenie de-provisioning (usuwanie kont)

```bash
curl -s -X DELETE "https://TARGET/api/admin/users/TARGET_USER_ID" -H "Authorization: Bearer ADMIN_TOKEN" -v

```

### Sprawdzenie czy usuniety uzytkownik nadal ma dostep

```bash
curl -s "https://TARGET/api/profile" -H "Authorization: Bearer DELETED_USER_TOKEN" -v

```

## KOMENDY Z WORDLISTAMI

# Brak wordlist - test logiczny oparty na analizie procesu provisioningu kont

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie jako administrator i przejdz przez proces tworzenia nowego uzytkownika
2. Zarejestruj caly przeplyw w Burp Suite i przeanalizuj endpointy
3. W Burp Repeater powtorz requesty tworzenia kont z tokenami roznych rol
4. Sprawdz czy mozna eskalowac role przy tworzeniu konta (np. dodanie role=admin)
5. Przetestuj czy konta moga byc tworzone przez API bez przejscia przez GUI
6. Sprawdz proces zapraszania uzytkownikow i analizuj tokeny zaproszeniowe
7. Przetestuj czy po dezaktywacji konta sesje sa uniewazniane
8. Sprawdz logi audytowe pod katem sciezki tworzenia kont


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Provisioning kont — kontrola dostepu

- **Tylko autoryzowane role** moga tworzyc/modyfikowac/usuwac konta
- Sprawdzaj uprawnienia na **kazdym endpoincie** provisioningu (BOLA/IDOR)
- Waliduj role przypisywane nowym kontom — nie pozwalaj na self-escalation
- Testuj: tworzenie konta admin przez zwyklego usera, tworzenie bez autoryzacji

### De-provisioning — usuwanie kont

- Usuniety/dezaktywowany uzytkownik musi natychmiast **utracic** wszystkie sesje i tokeny
- Sprawdz czy token usuniętego uzytkownika nadal dziala (dangling sessions)
- Odwolaj refresh tokens, invalidate JWT (denylist), usun sesje server-side
- Audit trail: loguj kto, kiedy i jakie konto stworzyl/usunal/zmodyfikowal

### Invite/zaproszenia

- Tokeny zaproszeniowe: CSPRNG, jednorazowe, krotki TTL (24-72h)
- Nie pozwalaj na reuse tokenu zaproszenia po aktywacji
- Ogranicz scope zaproszenia — nie pozwalaj zapraszajacemu nadac wyzszych uprawnien niz posiada
- Sprawdz czy token zaproszenia moze byc brute-forced

### Bulk provisioning

- Ogranicz rozmiar batch requestow (max. 100 uzytkownikow na raz)
- Waliduj kazdy rekord indywidualnie — nie pozwalaj na injection w CSV/JSON batch
- Rate limiting na endpoincie bulk provisioning

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.4.1 | Authentication Factor Lifecycle and Recovery | Verify that system generated initial passwords or activation codes are securely randomly generated, follow the existing password policy, and expire after a short period of time or after they are initially used. These initial secrets must not be permitted to become the long term password. |
| V6.3.2 | General Authentication Security | Verify that default user accounts (e.g., "root", "admin", or "sa") are not present in the application or are disabled. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.2.3 | Backend Communication Configuration | Verify that if a credential has to be used for service authentication, the credential being used by the consumer is not a default credential (e.g., root/root or admin/admin). |
