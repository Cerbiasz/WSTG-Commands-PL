# WSTG-ATHZ-03 — Testing for Privilege Escalation

## Cele

- Identify injection points related to privilege manipulation
- Fuzz or otherwise attempt to bypass security measures

## KOMENDY

### Modyfikacja roli w request

```bash
curl -X POST "https://TARGET/api/user/profile" -H "Cookie: session=USER_SESSION" -H "Content-Type: application/json" -d '{"role":"admin"}'
curl -X POST "https://TARGET/api/user/profile" -H "Cookie: session=USER_SESSION" -d "isAdmin=true"
curl -X POST "https://TARGET/api/user/profile" -H "Cookie: session=USER_SESSION" -d "usertype=1"

```

### Modyfikacja tokenu/cookie

```bash
# Sprawdz JWT claims (role, sub, admin)
# Sprawdz cookie values (base64 decode, modify, re-encode)

```

### Dostep do admin API

```bash
curl -s "https://TARGET/api/admin/users" -H "Cookie: session=USER_SESSION" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/api/admin/settings" -H "Cookie: session=USER_SESSION" -o /dev/null -w "%{http_code}\n"

```

### Parameter tampering

```bash
curl -X POST "https://TARGET/api/action" -H "Cookie: session=USER_SESSION" -d "user_id=ADMIN_ID&action=delete"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test logiczny

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Insecure Direct Object References/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj rozne poziomy uprawnien w aplikacji
2. Testuj modyfikacje parametrow roli (role, group, type, level)
3. Sprawdz JWT/cookie pod katem manipulacji uprawnien
4. Testuj dostep do endpointow wyzszego poziomu
5. Uzyj Burp Match/Replace do automatycznej podmiany parametrow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authorization_Cheat_Sheet.md, Access_Control_Cheat_Sheet.md

### Vertical Privilege Escalation — wektory ataku

- **Parametr roli w request**: `role=admin`, `isAdmin=true`, `userType=administrator`
- **Modyfikacja JWT claims**: zmiana `"role":"user"` na `"role":"admin"` w JWT payload
- **Forced browsing**: bezposredni dostep do `/admin/`, `/management/`, `/internal/`
- **HTTP method switching**: endpoint chroni GET ale nie POST/PUT/DELETE
- **API version bypass**: `/api/v1/admin` — starsza wersja API bez kontroli dostepu

### Obrona przed privilege escalation

- **Waliduj role SERVER-SIDE** na KAZDYM request — nie polegaj na client-side
- Sprawdzaj uprawnienia do **KONKRETNEJ AKCJI**, nie tylko typ uzytkownika
- **Deny by default** — jesli brak jawnej reguly, ODMOW dostepu
- Uzyj **centralnego middleware** do kontroli dostepu — nie rozpraszaj logiki autoryzacji
- **Separuj funkcje administracyjne** od zwyklych uzytkownikow na poziomie kodu i infrastruktury
  - Oddzielny panel admin na innej subdomenie/porcie
  - Osobna warstwa middleware dla admin endpointow

### Modele kontroli dostepu

- **RBAC** (Role-Based): proste ale podatne na "role explosion" — role per zasob
- **ABAC** (Attribute-Based): uwzglednia wiele atrybutow (rola, czas, IP, urzadzenie) — elastyczniejsze
- **ReBAC** (Relationship-Based): kontrola na podstawie relacji user↔zasob ("autor moze edytowac swoj post")

### Testowanie vertical privilege escalation

- Zaloguj sie jako zwykly user → probuj endpointy admina
- Dodaj parametry: `admin=true`, `role=admin`, `debug=1` do requestow
- Zmien role/claims w tokenach JWT lub cookies
- Testuj CRUD na admin zasobach z sesja zwyklego usera
- Porownaj odpowiedzi: te same dane vs 403/404 vs inne dane

### Logging i monitoring

- Loguj WSZYSTKIE proby dostepu do zasobow o wyzszym poziomie uprawnien
- Alertuj na powtarzajace sie proby eskalacji z jednego konta/IP
- Naruszenia autoryzacji = zdarzenia WYSOKIEGO priorytetu w SIEM

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Autorize | Automatyczne testowanie eskalacji uprawnien | [GitHub](https://github.com/Quitten/Autorize) |
| AuthMatrix | Macierz testow autoryzacji | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |
| Burp SessionAuth | Wykrywanie podatnosci eskalacji uprawnien | [GitHub](https://github.com/thomaspatzke/Burp-SessionAuthTool) |

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
| V8.4.1 | Other Authorization Considerations | Verify that multi-tenant applications use cross-tenant controls to ensure consumer operations will never affect tenants with which they do not have permissions to interact. |
