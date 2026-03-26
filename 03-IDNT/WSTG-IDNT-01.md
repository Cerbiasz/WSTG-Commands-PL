# WSTG-IDNT-01 — Test Role Definitions

## Cele

- Zidentyfikowac i udokumentowac role uzytkownikow w aplikacji
- Sprawdzic mozliwosc przelaczania sie miedzy rolami
- Ocenic granularnosc uprawnien przypisanych do rol

## KOMENDY

### Pobranie strony logowania i analiza dostepnych rol

```bash
curl -s -v -b cookies.txt -c cookies.txt "https://TARGET/login" 2>&1 | grep -iE "role|admin|user|moderator|manager"

```

### Logowanie jako uzytkownik o niskich uprawnieniach

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"testuser","password":"testpass"}' -c cookies_user.txt -v

```

### Logowanie jako administrator

```bash
curl -s -X POST "https://TARGET/api/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"adminpass"}' -c cookies_admin.txt -v

```

### Proba dostepu do panelu admina z tokenem zwyklego uzytkownika

```bash
curl -s -b cookies_user.txt "https://TARGET/admin/dashboard" -v

```

### Proba zmiany roli w parametrze zapytania

```bash
curl -s -X POST "https://TARGET/api/profile" -H "Content-Type: application/json" -H "Authorization: Bearer USER_TOKEN" -d '{"role":"admin"}' -v

```

### Proba zmiany roli przez cookie

```bash
curl -s -b "role=admin; session=USER_SESSION_ID" "https://TARGET/admin/dashboard" -v

```

### Proba zmiany roli w uktytym polu formularza

```bash
curl -s -X POST "https://TARGET/api/update-profile" -H "Authorization: Bearer USER_TOKEN" -d "username=testuser&role=administrator&email=test@test.com" -v

```

### Proba eskalacji uprawnien przez manipulacje JWT

```bash
# Dekodowanie JWT tokena
echo "USER_JWT_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null

```

### Sprawdzenie roznych endpointow z tokenami roznych rol

```bash
for endpoint in /admin /admin/users /api/admin/settings /manager /moderator/panel; do echo "--- $endpoint ---"; curl -s -o /dev/null -w "%{http_code}" -b cookies_user.txt "https://TARGET$endpoint"; echo; done

```

### Testowanie RBAC - proba wywolania akcji admina jako user

```bash
curl -s -X DELETE "https://TARGET/api/users/1" -H "Authorization: Bearer USER_TOKEN" -v
curl -s -X PUT "https://TARGET/api/users/1" -H "Authorization: Bearer USER_TOKEN" -H "Content-Type: application/json" -d '{"role":"admin"}' -v

```

## KOMENDY Z WORDLISTAMI

# Brak wordlist - test logiczny oparty na analizie rol i uprawnien

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie na konto z kazda dostepna rola i zmapuj dostepne funkcje
2. W Burp Suite Repeater zmien tokeny/cookie sesji miedzy rolami i sprawdz odpowiedzi
3. Uzyj Burp Intruder do testowania roznych wartosci parametru "role" (admin, user, moderator, manager, superadmin)
4. Sprawdz czy aplikacja ujawnia role w odpowiedziach API (np. GET /api/me)
5. W DevTools (F12) sprawdz localStorage/sessionStorage pod katem przechowywanych informacji o rolach
6. Sprawdz czy zmiana roli po stronie klienta (np. w JavaScript) wplywa na logike aplikacji
7. Przetestuj kazdy endpoint z tokenami roznych rol i porownaj odpowiedzi HTTP
8. Zainstaluj rozszerzenie Autorize w Burp Suite do automatycznego testowania autoryzacji miedzy rolami


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Access_Control_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Definicja rol i uprawnien

- **Role**: grupuja uprawnienia (admin, user, moderator, manager, readonly)
- **Uprawnienia**: granularne akcje (create_user, delete_order, view_report)
- Unikaj **role explosion** — zbyt wiele rol = trudne do zarzadzania
- Preferuj **ABAC/ReBAC** nad RBAC dla fine-grained permissions

### Wymuszanie autoryzacji

- **Server-side ONLY** — NIGDY nie polegaj na client-side (JavaScript, hidden fields, localStorage)
- **Deny by default** — dostep tylko jesli jawnie przyznany
- **Centralny middleware** — unikaj rozproszonych checkow w kodzie (latwe do pominiecia)
- **Kazdego request** waliduj — nie zakladaj ze sesja = autoryzacja

### Separacja uprawnien

- Oddzielne panele admin od user interface (inna subdomena/port)
- Funkcje administracyjne w oddzielnym module/kontrolerze
- Osobny middleware autoryzacji dla admin endpointow

### Testowanie zdefiniowanych rol

- Zmapuj WSZYSTKIE role w systemie i ich oczekiwane uprawnienia
- Zaloguj sie jako kazda rola → testuj dostep do endpointow innych rol
- Testuj **horizontal** (user A → zasoby user B) i **vertical** (user → admin) escalation
- Manipuluj parametry: `role=admin`, `isAdmin=true`, JWT claims
- Uzyj Burp Autorize/AuthMatrix do automatycznego porownywania

### Logging i audit

- Loguj WSZYSTKIE proby dostepu i naruszenia autoryzacji
- Loguj zmiany uprawnien (kto, kiedy, co zmieniono)
- Alertuj na powtarzajace sie proby eskalacji
- Regularny audit rol i uprawnien — usun nieuzywane konta i nadmiarowe uprawnienia

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AuthMatrix | Testowanie autoryzacji w macierzy uzytkownik/rola vs endpoint | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |
| Autorize | Automatyczne wykrywanie bledow autoryzacji | [GitHub](https://github.com/Quitten/Autorize) |
| Auth Analyzer | Analiza bledow autoryzacji przez porownywanie sesji | [GitHub](https://github.com/simioni87/auth_analyzer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.1.1 | Authorization Documentation | Verify that authorization documentation defines rules for restricting function-level and data-specific access based on consumer permissions and resource attributes. |
| V8.2.1 | General Authorization Design | Verify that the application ensures that function-level access is restricted to consumers with explicit permissions. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.1.2 | Authorization Documentation | Verify that authorization documentation defines rules for field-level access restrictions (both read and write) based on consumer permissions and resource attributes. Note that these rules might depend on other attribute values of the relevant data object, such as state or status. |
