# WSTG-ATHN-04 — Testing for Bypassing Authentication Schema

## Cele

- Upewnic sie ze uwierzytelnianie jest stosowane na wszystkich zasobach
- Przetestowac forced browsing do chronionych zasobow
- Sprawdzic mozliwosc obejscia mechanizmu uwierzytelniania

## KOMENDY

### Bezposredni dostep do chronionych endpointow bez autoryzacji

```bash
curl -s -v "https://TARGET/admin/dashboard"
curl -s -v "https://TARGET/api/admin/users"
curl -s -v "https://TARGET/api/profile"
curl -s -v "https://TARGET/api/settings"
curl -s -v "https://TARGET/internal/config"

```

### Proba z pustym tokenem autoryzacji

```bash
curl -s "https://TARGET/api/profile" -H "Authorization: " -v
curl -s "https://TARGET/api/profile" -H "Authorization: Bearer " -v
curl -s "https://TARGET/api/profile" -H "Authorization: Bearer null" -v
curl -s "https://TARGET/api/profile" -H "Authorization: Bearer undefined" -v

```

### Proba z zmodyfikowanym tokenem

```bash
curl -s "https://TARGET/api/profile" -H "Authorization: Bearer INVALID_TOKEN_HERE" -v

```

### Proba z inną metoda HTTP

```bash
curl -s -X GET "https://TARGET/admin/dashboard" -v
curl -s -X POST "https://TARGET/admin/dashboard" -v
curl -s -X PUT "https://TARGET/admin/dashboard" -v
curl -s -X DELETE "https://TARGET/admin/dashboard" -v
curl -s -X PATCH "https://TARGET/admin/dashboard" -v
curl -s -X OPTIONS "https://TARGET/admin/dashboard" -v
curl -s -X HEAD "https://TARGET/admin/dashboard" -v
curl -s -X TRACE "https://TARGET/admin/dashboard" -v

```

### Path traversal bypass uwierzytelniania

```bash
curl -s -v "https://TARGET/..;/admin/dashboard"
curl -s -v "https://TARGET/admin/../admin/dashboard"
curl -s -v "https://TARGET/%2e%2e/admin/dashboard"
curl -s -v "https://TARGET/./admin/dashboard"
curl -s -v "https://TARGET/admin;/dashboard"
curl -s -v "https://TARGET/ADMIN/DASHBOARD"

```

### Proba obejscia przez manipulacje parametrow

```bash
curl -s "https://TARGET/api/profile?admin=true" -v
curl -s "https://TARGET/api/profile?authenticated=true" -v
curl -s "https://TARGET/api/profile?debug=true" -v

```

### Proba obejscia przez naglowki

```bash
curl -s "https://TARGET/admin/dashboard" -H "X-Custom-IP-Authorization: 127.0.0.1" -v
curl -s "https://TARGET/admin/dashboard" -H "X-Forwarded-For: 127.0.0.1" -v
curl -s "https://TARGET/admin/dashboard" -H "X-Original-URL: /admin/dashboard" -v
curl -s "https://TARGET/admin/dashboard" -H "X-Rewrite-URL: /admin/dashboard" -v
curl -s "https://TARGET/admin/dashboard" -H "Referer: https://TARGET/admin/" -v

```

### Test dostep do API bez sesji

```bash
curl -s "https://TARGET/api/v1/users" -v
curl -s "https://TARGET/api/v1/orders" -v
curl -s "https://TARGET/api/v1/config" -v

```

## KOMENDY Z WORDLISTAMI

### ffuf forced browsing - odkrywanie chronionych zasobow

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404

```

### ffuf z DirBuster medium lista

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-medium.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404 -t 50

```

### ffuf z DirBuster small lista

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/DirBuster-2007_directory-list-2.3-small.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404 -t 50

```

### ffuf admin/internal paths

```bash
ffuf -w Desktop/WSTG/Bug-Bounty-Wordlists-main/admin.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404

```

### ffuf szukanie API endpointow bez autoryzacji

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/api/api-endpoints.txt:PATH -u "https://TARGET/api/PATH" -mc all -fc 404

```

### ffuf API seen in wild

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/api/api-seen-in-wild.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404

```

### ffuf z common-api-endpoints

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common-api-endpoints-mazen160.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404

```

### ffuf szukanie juicy paths

```bash
ffuf -w Desktop/WSTG/Bug-Bounty-Wordlists-main/juicy-paths.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404

```

### ffuf z big.txt

```bash
ffuf -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/big.txt:PATH -u "https://TARGET/PATH" -mc all -fc 404 -t 50

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zmapuj wszystkie chronione endpointy aplikacji po zalogowaniu
2. Wyloguj sie i sprobuj bezposrednio wejsc na kazdy chroniony URL
3. W Burp Repeater usun naglowek Authorization/Cookie i wyslij ponownie requesty
4. Przetestuj rozne metody HTTP (GET/POST/PUT/DELETE/OPTIONS) na chronionych zasobach
5. Uzyj rozszerzenia Autorize w Burp Suite do automatycznego testowania
6. Sprawdz czy statyczne pliki (JS, CSS, images) w chronionych katalogach sa dostepne
7. Przetestuj manipulacje sciezka (/..;/ , /%2e%2e/ , /admin;/)
8. Sprawdz czy wylogowanie rzeczywiscie uniewaznaia sesje


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Walidacja uwierzytelnienia po stronie serwera

- **Kazdy request** musi byc walidowany server-side — nie polegaj na client-side checks
- Uzyj globalnych filtrow/middleware: Java Filters, Django Middleware, Express middleware, .NET Filters
- **Deny by default** — jesli brak jawnej reguly, ODMOW dostepu

### Obejscie uwierzytelnienia — wektory

- **Forced browsing**: bezposredni dostep do chronionych URL bez logowania
- **Path manipulation**: `/admin/../admin`, `/admin;/`, `/%2e%2e/admin`, `/ADMIN/` (case sensitivity)
- **HTTP method switching**: GET zamiast POST, OPTIONS, PUT na chronionych endpointach
- **Header injection**: `X-Forwarded-For: 127.0.0.1`, `X-Original-URL`, `X-Custom-IP-Authorization`
- **Parameter manipulation**: `?admin=true`, `?authenticated=true`, `?debug=true`
- **API version bypass**: stara wersja API (`/api/v1/`) moze nie miec autentykacji

### Re-autentykacja dla wrazliwych operacji

- **Zmiana hasla**: wymagaj podania AKTUALNEGO hasla
- **Platnosci / przelewy**: wymagaj hasla lub MFA
- **Zmiana emaila / telefonu**: wymagaj hasla — atakujacy moze przejac konto
- **Eksport danych**: wymagaj potwierdzenia tozsamosci
- **Operacje administracyjne**: wymagaj step-up authentication

### Nie polegaj na client-side

- Ukryte pola formularza, cookies, localStorage — NIE sa mechanizmami kontroli dostepu
- JavaScript ukrywajacy elementy UI — atakujacy moze ominac przez DevTools
- Stan autentykacji MUSI byc weryfikowany SERVER-SIDE na kazdym request

### Testowanie

- Zmapuj WSZYSTKIE endpointy po zalogowaniu
- Usun Cookie/Authorization header i sprawdz dostep do kazdego endpointu
- Sprawdz dostep z roznych rol (user vs admin)
- Testuj rozne metody HTTP na tym samym endpoincie

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Autorize | Automatyczne testowanie bledow autoryzacji i uwierzytelnienia | [GitHub](https://github.com/Quitten/Autorize) |
| AuthMatrix | Macierz testow autoryzacji uzytkownik vs endpoint | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |
| Auth Analyzer | Porownywanie odpowiedzi miedzy sesjami roznych uzytkownikow | [GitHub](https://github.com/simioni87/auth_analyzer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V8.3.1 | Operation Level Authorization | Verify that the application enforces authorization rules at a trusted service layer and doesn't rely on controls that an untrusted consumer could manipulate, such as client-side JavaScript. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.3.4 | General Authentication Security | Verify that, if the application includes multiple authentication pathways, there are no undocumented pathways and that security controls and authentication strength are enforced consistently. |
| V6.1.3 | Authentication Documentation | Verify that, if the application includes multiple authentication pathways, these are all documented together with the security controls and authentication strength which must be consistently enforced across them. |
