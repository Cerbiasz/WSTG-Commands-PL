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

> Źródło: OWASP CheatSheetSeries — Multifactor_Authentication_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Spojnosc zabezpieczen miedzy kanalami

- **WSZYSTKIE kanaly** (web, mobile app, API, SSO, legacy) MUSZA miec rowny poziom bezpieczenstwa
- Atakujacy uzyje NAJSLABSZEGO kanalu — np. stare API bez MFA, mobile app bez rate limiting
- Sprawdz czy stare wersje API (`/api/v1/`) nadal sa dostepne i czy maja te same zabezpieczenia

### Typowe obejscia przez alternatywne kanaly

- API endpoint bez MFA (web wymaga MFA, ale API nie)
- Mobile API z prostszym uwierzytelnieniem (np. PIN zamiast hasla + MFA)
- SSO/OAuth bypass — redirect na slabszy provider
- Legacy endpoints nadal aktywne po migracji
- Rate limiting na web ale nie na API

### Multi-Factor Authentication — hierarchia sily

- **WebAuthn/FIDO2** (najsilniejsze): hardware key, biometrics — phishing-resistant
- **TOTP** (silne): Google Authenticator, Authy — time-based OTP
- **Push notification** (dobre): approve/deny na telefonie
- **SMS OTP** (slabsze): podatne na SIM swap, SS7 attacks — ale lepsze niz nic
- **Email OTP** (najslabsze z MFA): jezeli email jest skompromitowany — MFA tez

### Testowanie sposobnosci kanalow

- Zaloguj sie przez kazdy kanal i porownaj wymagania
- Sprawdz czy MFA jest wymagane na WSZYSTKICH kanalach
- Sprawdz rate limiting na kazdym kanale osobno
- Sprawdz czy sesja z jednego kanalu jest wazna w innym
- Testuj logout — czy wylogowanie w jednym kanale wplywa na inne

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
