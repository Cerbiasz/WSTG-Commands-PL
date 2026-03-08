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

- Waliduj role na kazdym uzyciu — nie zakladaj ze uzytkownik nie zmieni parametrow
- Separuj funkcje administracyjne od zwyklych uzytkownikow na poziomie kodu
- Loguj wszystkie zmiany uprawnien i proby eskalacji
- Testuj zmiane parametrow roli w requestach (role=admin, isAdmin=true)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Autorize | Automatyczne testowanie eskalacji uprawnien | [GitHub](https://github.com/Quitten/Autorize) |
| AuthMatrix | Macierz testow autoryzacji | [GitHub](https://github.com/SecurityInnovation/AuthMatrix) |
| Burp SessionAuth | Wykrywanie podatnosci eskalacji uprawnien | [GitHub](https://github.com/thomaspatzke/Burp-SessionAuthTool) |
