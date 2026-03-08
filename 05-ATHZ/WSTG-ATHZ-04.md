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

> Źródło: OWASP CheatSheetSeries — Insecure_Direct_Object_Reference_Prevention_Cheat_Sheet.md

- Uzywaj niebezposrednich referencji (UUID/hash) zamiast sekwencyjnych ID
- Waliduj wlasnosc obiektu po stronie serwera przy kazdym dostepie
- Implementuj per-object access control — sprawdzaj czy uzytkownik ma prawo do konkretnego zasobu
- Nie polegaj na ukryciu URL-a lub parametru jako mechanizmie ochrony

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Autorize | Automatyczne testowanie IDOR przez porownywanie sesji | [GitHub](https://github.com/Quitten/Autorize) |
| AutoRepeater | Powtarzanie requestow z podmienionymi sesjami/ID | [GitHub](https://github.com/nccgroup/AutoRepeater) |
| Auth Analyzer | Analiza roznic w odpowiedziach miedzy uzytkownikami | [GitHub](https://github.com/simioni87/auth_analyzer) |
