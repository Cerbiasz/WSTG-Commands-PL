# WSTG-ATHZ-04 — Testing for Insecure Direct Object References (IDOR)

## Cele

- Identify points where object references may occur
- Assess the access control measures and if they're vulnerable to IDOR

## KOMENDY

### IDOR na numerycznych ID

```bash
curl -s "https://TARGET/api/user/1" -H "Cookie: session=USER2_SESSION"
curl -s "https://TARGET/api/user/2" -H "Cookie: session=USER2_SESSION"
curl -s "https://TARGET/api/order/1001" -H "Cookie: session=USER_SESSION"
curl -s "https://TARGET/api/document/1" -H "Cookie: session=USER_SESSION"

```

### Brute force ID

```bash
for i in $(seq 1 100); do echo "$i: $(curl -s -o /dev/null -w '%{http_code}' 'https://TARGET/api/user/'$i -H 'Cookie: session=USER_SESSION')"; done

```

### IDOR na UUID/hash

```bash
# Sprawdz czy UUID sa przewidywalne lub sekwencyjne

```

### IDOR w roznych miejscach

```bash
# URL path: /api/user/{id}
# Query param: /api/user?id={id}
# Body: POST {"user_id": "{id}"}
# Header: X-User-ID: {id}

```

### IDOR na plikach

```bash
curl -s "https://TARGET/download?file=report_1.pdf" -H "Cookie: session=USER_SESSION"
curl -s "https://TARGET/download?file=report_2.pdf" -H "Cookie: session=USER_SESSION"

```

## KOMENDY Z WORDLISTAMI

### SecLists ID sequences

```bash
ffuf -u "https://TARGET/api/user/FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/4-digits-0000-9999.txt -H "Cookie: session=USER_SESSION" -mc 200 -o output_ffuf_idor.json

```

### PayloadsAllTheThings IDOR

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Insecure Direct Object References/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj wszystkie referencje do obiektow (ID, UUID, filename)
2. Zaloguj sie jako user A i sprobuj dostep do obiektow user B
3. Testuj sekwencyjne ID w Burp Intruder
4. Sprawdz rozne metody HTTP (GET, PUT, DELETE) na cudzych obiektach
5. Uzyj Burp Autorize do automatycznego testowania
6. Testuj IDOR w operacjach CRUD (Create, Read, Update, Delete)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.md, Authorization_Cheat_Sheet.md

### Czym jest IDOR

- IDOR (CWE-639) = Authorization Bypass Through User-Controlled Key
- Atakujacy modyfikuje identyfikator obiektu (ID w URL, query param, body) aby uzyskac dostep do cudzych zasobow
- Skutki: odczyt/modyfikacja/usuniecie cudzych danych, horizontal/vertical privilege escalation

### Mitygacje IDOR

- **Unikaj eksponowania ID** uzytkownikowi — pobieraj dane na podstawie sesji/JWT (np. `/api/my-profile` zamiast `/api/user/123`)
- **Indirect references**: uzywaj mapowania per-sesja (np. OWASP ESAPI AccessReferenceMap) — wewnetrzny ID nie jest widoczny
- **Per-object access control**: sprawdzaj przy KAZDYM uzyciu czy uzytkownik ma prawo do KONKRETNEGO obiektu
  - Nie wystarczy sprawdzic ze uzytkownik jest zalogowany — musisz zweryfikowac ze obiekt nalezy do niego
- **UUID/hash zamiast sekwencyjnych ID**: utrudnia zgadywanie, ale to NIE jest wystarczajaca obrona sama w sobie
  - Security through obscurity — randomizacja ID musi byc UZUPELNIONA access control checks

### Typowe wektory IDOR

- URL path: `/api/user/123/orders` → zmien 123 na 456
- Query parameters: `?invoice_id=1001` → `?invoice_id=1002`
- POST body: `{"account_id": "901"}` → `{"account_id": "523"}`
- Nazwy plikow: `/uploads/report_userA.pdf` → `/uploads/report_userB.pdf`
- Hidden form fields: ukryte pole z user ID — latwe do modyfikacji

### Testowanie IDOR

- Testuj CRUD (Create, Read, Update, Delete) na cudzych obiektach
- Testuj rozne metody HTTP na tym samym endpoincie (GET, PUT, DELETE)
- Porownuj odpowiedzi miedzy roznymi uzytkownikami w Burp Autorize
- Uzyj sekwencyjnych ID w Burp Intruder do masowego testowania
- Sprawdz GraphQL/API endpoints — czesto brakuje im granularnej autoryzacji

### Dodatkowe zabezpieczenia

- Loguj KAZDY dostep do obiektow i naruszenia autoryzacji
- Implementuj rate limiting na endpointach z ID — utrudnia enumeration
- Waliduj format i typ ID (np. UUID v4 regex) — dodatkowa warstwa obrony

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Autorize | Automatyczne testowanie IDOR przez porownywanie sesji | [GitHub](https://github.com/Quitten/Autorize) |
| AutoRepeater | Powtarzanie requestow z podmienionymi sesjami/ID | [GitHub](https://github.com/nccgroup/AutoRepeater) |
| Auth Analyzer | Analiza roznic w odpowiedziach miedzy uzytkownikami | [GitHub](https://github.com/simioni87/auth_analyzer) |

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


---

## HackTricks Tips

- **Sprawdź wszystkie ID**: path (`/api/user/1234`), query (`?id=42`), body (`{"user_id":321}`), headers (`X-Client-ID`)
- **ffuf enumeration**: `ffuf -u http://target/download.php?id=FUZZ -H "Cookie: ..." -w <(seq 0 6000) -fr 'File Not Found'`
- **Combinatorial IDOR**: `ffuf -u 'http://target/chat?users[0]=NUM1&users[1]=NUM2' -w <(seq 1 62):NUM1 -w <(seq 1 62):NUM2`
- **Encoding ≠ security**: hex/base64 predictable IDs (np. `C-285-100` → ASCII hex) to nadal enumerowalne
- **UUID v1 Sandwich Attack**: trigger reset dla attacker1, victim, attacker2 → token victim jest między dwoma znanymi UUID. Tool: `sandwich`
