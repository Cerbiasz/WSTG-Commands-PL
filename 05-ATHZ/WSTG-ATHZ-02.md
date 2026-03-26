# WSTG-ATHZ-02 — Testing for Bypassing Authorization Schema

## Cele

- Assess if unauthenticated, horizontal, or vertical access is possible

## KOMENDY

### Test dostepu bez autentykacji

```bash
curl -s "https://TARGET/admin/dashboard" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/api/users" -o /dev/null -w "%{http_code}\n"

```

### Horizontal privilege escalation

```bash
# Zaloguj sie jako user A, sprobuj dostep do zasobow user B
curl -s "https://TARGET/api/user/2/profile" -H "Cookie: session=USER_A_SESSION"
curl -s "https://TARGET/api/orders/OTHER_USER_ORDER_ID" -H "Cookie: session=USER_A_SESSION"

```

### Vertical privilege escalation

```bash
# Zaloguj sie jako zwykly user, sprobuj dostep do endpointow admina
curl -s "https://TARGET/admin/users" -H "Cookie: session=NORMAL_USER_SESSION"

```

### Forced browsing

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -H "Cookie: session=NORMAL_USER_SESSION" -mc 200 -o output_ffuf_forced.json

```

### Method-based bypass

```bash
curl -X POST "https://TARGET/admin" -H "Cookie: session=NORMAL_USER_SESSION" -o /dev/null -w "%{http_code}\n"

```

### Header-based bypass

```bash
curl -s "https://TARGET/admin" -H "X-Original-URL: /admin" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/admin" -H "X-Forwarded-For: 127.0.0.1" -o /dev/null -w "%{http_code}\n"

```

## KOMENDY Z WORDLISTAMI

### SecLists common paths

```bash
# Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt
# Desktop/WSTG/SecLists-master/Discovery/Web-Content/raft-large-directories.txt

```

### Bug-Bounty-Wordlists 403 bypass

```bash
ffuf -u "https://TARGET/admin" -H "FUZZ: 127.0.0.1" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_header_payloads.txt -mc 200 -o output_ffuf_403bypass_headers.json

ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_url_payloads.txt -mc 200 -o output_ffuf_403bypass_url.json

```

### SecLists 403 bypass

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/403/403_url_payloads.txt -mc 200 -o output_ffuf_seclists_403.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp Autorize extension do automatycznego testowania autoryzacji
2. Zaloguj sie jako rozni uzytkownicy i porownaj dostep do endpointow
3. Testuj IDOR na ID w URL i body requestow
4. Sprawdz forced browsing do chronionych zasobow
5. Testuj HTTP method switching (GET vs POST vs PUT)
6. Testuj header-based bypass (X-Original-URL, X-Forwarded-For)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authorization_Cheat_Sheet.md, Access_Control_Cheat_Sheet.md

### Fundamentalne zasady autoryzacji

- **Deny by Default**: jesli brak jawnej reguly — ODMOW dostepu; kazde uprawnienie musi byc jawnie przyznane
- **Least Privilege**: przydzielaj MINIMUM uprawnien potrzebnych do wykonania zadania — horyzontalnie i wertykalnie
- **Waliduj przy KAZDYM uzyciu**: sprawdzaj uprawnienia na KAZDY request, niezaleznie od zrodla (AJAX, server-side, API)
  - Uzyj globalnych filtrow/middleware: Java Filters, Django Middleware, .NET Core Filters, Laravel Middleware

### Model kontroli dostepu

- Preferuj **ABAC** (Attribute-Based) lub **ReBAC** (Relationship-Based) nad **RBAC** (Role-Based)
  - RBAC: proste ale podatne na "role explosion", slabo obsluguje fine-grained permissions
  - ABAC: uwzglednia wiele atrybutow (rola, czas, lokalizacja, urzadzenie) — lepsza obrona least privilege
  - ReBAC: kontrola dostepu na podstawie relacji miedzy uzytkownikiem a zasobem (np. "autor moze edytowac swoj post")

### Obrona przed bypass autoryzacji

- NIE polegaj na client-side access control — atakujacy moze ominac JavaScript/CSS ukrywajace elementy
- Sprawdzaj autoryzacje **SERVER-SIDE**, na gateway lub w serverless function
- Unikaj eksponowania identyfikatorow (ID) uzytkownikowi — jesli to mozliwe, pobieraj dane na podstawie sesji/JWT
- Jesli ID sa eksponowane — uzywaj **UUID/hash** zamiast sekwencyjnych numerow
- Sprawdzaj uprawnienia do **KONKRETNEGO obiektu**, nie tylko do typu obiektu

### Obsluga bledow autoryzacji

- Centralizuj logike obslugi bledow autoryzacji — unikaj nieoczekiwanych stanow aplikacji
- Nie ujawniaj wrazliwych informacji w komunikatach o bledzie (sciezki, logi, debug output)
- Loguj WSZYSTKIE naruszenia autoryzacji jako zdarzenia wysokiego priorytetu

### Testowanie autoryzacji

- Testuj dostep **horyzontalny**: uzytkownik A probuuje dostep do zasobow uzytkownika B
- Testuj dostep **wertykalny**: zwykly user probuje dostep do zasobow admina
- Testuj forced browsing do chronionych endpointow
- Testuj method switching (GET zamiast POST, PUT zamiast DELETE)
- Testuj header-based bypass: `X-Original-URL`, `X-Forwarded-For: 127.0.0.1`

### Logging i monitoring

- Loguj wszystkie proby dostepu i naruszenia autoryzacji
- Uzywaj synchronizowanych zegarow i stref czasowych
- Rozważ SIEM do centralnego monitorowania logow dostepu

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Autorize | Automatyczne wykrywanie bledow autoryzacji | [GitHub](https://github.com/Quitten/Autorize) |
| AuthMatrix | Macierz testow autoryzacji uzytkownik/rola vs endpoint | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |
| AutoRepeater | Automatyczne powtarzanie requestow z roznymi sesjami | [GitHub](https://github.com/nccgroup/AutoRepeater) |
| Auth Analyzer | Porownywanie odpowiedzi miedzy sesjami | [GitHub](https://github.com/simioni87/auth_analyzer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.2.1 | General Authorization Design | Verify that the application ensures that function-level access is restricted to consumers with explicit permissions. |
| V8.2.2 | General Authorization Design | Verify that the application ensures that data-specific access is restricted to consumers with explicit permissions to specific data items to mitigate insecure direct object reference (IDOR) and broken object level authorization (BOLA). |
| V8.3.1 | Operation Level Authorization | Verify that the application enforces authorization rules at a trusted service layer and doesn't rely on controls that an untrusted consumer could manipulate, such as client-side JavaScript. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.2.3 | General Authorization Design | Verify that the application ensures that field-level access is restricted to consumers with explicit permissions to specific fields to mitigate broken object property level authorization (BOPLA). |
