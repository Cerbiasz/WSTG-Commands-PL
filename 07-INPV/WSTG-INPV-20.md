# WSTG-INPV-20 — Testing for Mass Assignment

## Cele

- Identify requests that modify objects
- Assess if it is possible to modify fields never intended to be modified from outside

## KOMENDY

### Dodawanie ukrytych parametrow do requestow

```bash
curl -X POST "https://TARGET/api/user" -H "Content-Type: application/json" -d '{"name":"test","role":"admin"}'
curl -X POST "https://TARGET/api/user" -H "Content-Type: application/json" -d '{"name":"test","isAdmin":true}'
curl -X PUT "https://TARGET/api/user/1" -H "Content-Type: application/json" -d '{"name":"test","verified":true,"role":"admin"}'

```

### Arjun - odkrywanie ukrytych parametrow

```bash
arjun -u "https://TARGET/api/user" -m POST

```

### Param Miner (Burp extension)

```bash
# Testuj automatyczne wykrywanie ukrytych parametrow

```

## KOMENDY Z WORDLISTAMI

### SecLists parameter names

```bash
# Do Arjun lub Burp Param Miner:
# Desktop/WSTG/SecLists-master/Discovery/Web-Content/burp-parameter-names.txt

```

### Bug-Bounty-Wordlists hidden parameters

```bash
ffuf -u "https://TARGET/api/user" -X POST -H "Content-Type: application/json" -d '{"name":"test","FUZZ":"true"}' -w Desktop/WSTG/Bug-Bounty-Wordlists-main/parameter_names.txt -mc all -o output_ffuf_mass.json

```

### PayloadsAllTheThings Mass Assignment

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Mass Assignment/README.md

```

### PayloadsAllTheThings Hidden Parameters

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Hidden Parameters/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj endpointy modyfikujace obiekty (POST, PUT, PATCH)
2. Sprawdz dokumentacje API pod katem wszystkich pol obiektu
3. Dodaj pola: role, isAdmin, verified, active, balance, credits
4. Porownaj odpowiedz z dodanymi polami vs bez
5. Testuj na endpointach rejestracji i aktualizacji profilu


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Mass_Assignment_Cheat_Sheet.md

### Czym jest Mass Assignment

- Framework automatycznie mapuje parametry request na pola obiektu/modelu
- Atakujacy dodaje pola ktore NIE powinny byc modyfikowane: `role`, `isAdmin`, `price`, `balance`, `verified`
- Przyklady: Rails (ActiveRecord), Spring (ModelAttribute), Django (ModelForm), Node (Mongoose)

### Obrona — Allowlist pol

- **Jawnie okresl ktore pola moga byc modyfikowane** — allowlist zamiast denylist
- **DTO / View Models**: oddzielny obiekt do odbioru danych od uzytkownika, NIE entity bazodanowe
- NIGDY nie binduj user input **bezposrednio** do modelu bazy danych

### Framework-specific obrona

- **Ruby on Rails**: `params.require(:user).permit(:name, :email)` — strong parameters
- **Spring (Java)**: `@JsonIgnore` na polach wrażliwych, `@ModelAttribute` z allowlistą
- **Django**: `Meta.fields = ['name', 'email']` w ModelForm — jawna lista pól
- **ASP.NET**: `[Bind(Include = "Name,Email")]` lub `[BindNever]` na polach wrażliwych
- **Node/Express + Mongoose**: `schema.set('strict', true)` + jawne pola w kontrolerze
- **Laravel**: `$fillable` (allowlist) lub `$guarded` (denylist) w modelu Eloquent

### Typowe pola do testowania

- `role`, `isAdmin`, `admin`, `userType`, `privilege` — eskalacja uprawnien
- `price`, `balance`, `credits`, `amount`, `discount` — manipulacja finansowa
- `verified`, `active`, `approved`, `emailVerified` — obejscie weryfikacji
- `password`, `passwordHash`, `secret` — nadpisanie credentials
- `id`, `userId`, `ownerId` — zmiana wlasciciela obiektu (IDOR)

### Testowanie

- Porownaj odpowiedz API z dozwolonymi polami vs z dodanymi nieoczekiwanymi polami
- Testuj endpointy: rejestracja, aktualizacja profilu, tworzenie zamowienia, zmiana ustawien
- Uzyj Param Miner (Burp) lub arjun do discovery ukrytych parametrow

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Agartha | Generowanie dynamicznych payloadow i testowanie injection/auth | [GitHub](https://github.com/volkandindar/agartha) |
