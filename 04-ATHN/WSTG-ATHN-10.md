# WSTG-ATHN-10 — Testing for Weaker Authentication in Alternative Channel

## Cele

- Identify alternative authentication channels
- Assess the security measures used and if any bypasses exists

## KOMENDY

### Identyfikacja alternatywnych kanalow

```bash
# Mobile API
curl -s "https://TARGET/api/v1/login" -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"test"}' -H "User-Agent: MobileApp/1.0"

```

### Stare wersje API

```bash
curl -s "https://TARGET/api/v1/login" -X POST -d "username=admin&password=test"
curl -s "https://TARGET/api/v2/login" -X POST -d "username=admin&password=test"

```

### Rozne endpointy logowania

```bash
curl -s "https://TARGET/login"
curl -s "https://TARGET/admin/login"
curl -s "https://TARGET/api/auth"
curl -s "https://TARGET/oauth/login"

```

### Sprawdzenie roznic w zabezpieczeniach

```bash
# Czy API mobilne wymaga MFA? Czy ma rate limiting?

```

## KOMENDY Z WORDLISTAMI

### SecLists API paths

```bash
ffuf -u "https://TARGET/FUZZ/login" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/api/api-endpoints.txt -mc 200,301,302,401 -o output_ffuf_api_auth.json

```

### Bug-Bounty-Wordlists API

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api.txt -mc 200,301,302 -o output_ffuf_bbw_api.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj wszystkie kanaly autentykacji (web, mobile, API, SSO)
2. Porownaj zabezpieczenia miedzy kanalami
3. Sprawdz czy alternatywne kanaly pomijaja MFA
4. Testuj rate limiting na kazdym kanale osobno
5. Sprawdz czy stare wersje API sa nadal dostepne


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Multifactor_Authentication_Cheat_Sheet.md

- Zapewnij rowny poziom bezpieczenstwa we wszystkich kanalach (web, mobile, API)
- Nie pozwalaj na obejscie MFA przez przejscie na slabszy kanal uwierzytelnienia
- Sprawdz czy API endpointy wymagaja takiego samego poziomu uwierzytelnienia co interfejs webowy

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
