# WSTG-ATHN-11 — Testing Multi-Factor Authentication (MFA)

## Cele

- Identify the type of MFA used by the application
- Determine whether the MFA implementation is robust and secure
- Attempt to bypass the MFA

## KOMENDY

### Bypass MFA - pominiec krok

```bash
# Po logowaniu przejdz bezposrednio do chronionej strony
curl -s "https://TARGET/dashboard" -H "Cookie: session=SESSION_AFTER_PASSWORD_ONLY"

```

### Brute force OTP (4-6 cyfr)

```bash
ffuf -u "https://TARGET/verify-otp" -X POST -d "otp=FUZZ" -H "Cookie: session=TOKEN" -w Desktop/WSTG/SecLists-master/Fuzzing/4-digits-0000-9999.txt -mc 200,302 -o output_ffuf_otp4.json

ffuf -u "https://TARGET/verify-otp" -X POST -d "otp=FUZZ" -H "Cookie: session=TOKEN" -w Desktop/WSTG/SecLists-master/Fuzzing/6-digits-000000-999999.txt -mc 200,302 -rate 10 -o output_ffuf_otp6.json

```

### Test reuse OTP

```bash
# Uzyj tego samego kodu ponownie
curl -X POST "https://TARGET/verify-otp" -d "otp=VALID_OTP" -H "Cookie: session=TOKEN"

```

### Test wygasniecia OTP

```bash
# Poczekaj > czasu waznosci i uzyj kodu

```

### Response manipulation

```bash
# Sprawdz czy zmiana odpowiedzi z "false" na "true" pomija MFA

```

### Backup codes

```bash
curl -s "https://TARGET/settings/mfa/backup-codes" -H "Cookie: session=TOKEN"

```

## KOMENDY Z WORDLISTAMI

### SecLists 4/6 digit OTP

```bash
# Desktop/WSTG/SecLists-master/Fuzzing/4-digits-0000-9999.txt
# Desktop/WSTG/SecLists-master/Fuzzing/6-digits-000000-999999.txt
# Desktop/WSTG/SecLists-master/Fuzzing/3-digits-000-999.txt

```

### Bug-Bounty-Wordlists 6 digits

```bash
# Desktop/WSTG/Bug-Bounty-Wordlists-main/6-digits-000000-999999.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj typ MFA (TOTP, SMS, email, push, hardware key)
2. Testuj pominicie kroku MFA (bezposredni dostep do dashboardu)
3. Testuj brute force kodu OTP (sprawdz rate limiting)
4. Sprawdz czy kod mozna uzyc ponownie
5. Testuj response manipulation w Burp
6. Sprawdz backup/recovery codes
7. Testuj dezaktywacje MFA bez weryfikacji
8. Sprawdz czy MFA jest wymagane na wszystkich kanalach


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Multifactor_Authentication_Cheat_Sheet.md

### Hierarchia czynnikow MFA (od najsilniejszego)

| Czynnik | Typ | Phishing-resistant? | Uwagi |
|---------|-----|---------------------|-------|
| FIDO2/WebAuthn/Passkeys | Something You Have + Are/Know | **TAK** | Najlepsza opcja — kryptograficzne wiazanie z domena |
| Hardware OTP (YubiKey) | Something You Have | Nie (ale krotki czas zycia) | Drogie, ale bardzo bezpieczne |
| Software TOTP | Something You Have | Nie | Dobre — Google Authenticator, Authy |
| Push notification | Something You Have | Nie | Ryzyko "push fatigue" — atakujacy spamuje powiadomieniami |
| SMS/telefon | Something You Have | Nie | **SLABE** — SIM swap, SS7, przechwytywanie |
| Email | Something You Have/Know | Nie | **Najslabsze** — czesto to samo haslo |
| Pytania bezpieczenstwa | Something You Know | Nie | **NIST odradza** — nie stanowi MFA z haslem |

### Kiedy wymagac MFA

- **Logowanie** — glowny punkt wymagania MFA
- **Zmiana hasla** lub adresu email
- **Wylaczanie MFA** — wymaga re-autentykacji istniejacym czynnikiem
- **Operacje wrażliwe**: transakcje finansowe, eksport danych, zmiana uprawnien
- **Eskalacja sesji**: przejscie z user → admin
- **Wszystkie kanaly**: webowe UI, API, mobile app — kazdy musi wymagac MFA

### OTP — bezpieczna implementacja

- Generuj OTP uzywajac **CSPRNG** (kryptograficznie bezpieczny generator)
- Czas zycia OTP: **krotki TTL** (np. 5-10 minut)
- OTP musi byc **jednorazowy** — po uzyciu natychmiast uniewaznij
- **Limit prob**: max 3-5 blednych prob, potem nowy OTP lub lockout
- Hashuj OTP w bazie — nie przechowuj w plaintext
- Przy "Wyslij ponownie": generuj **nowy** OTP i nadpisz stary
- Preferuj **8-cyfrowe** kody zamiast 6-cyfrowych (1M vs 100M mozliwosci)
- NIE loguj wartosci OTP

### Reset/odzyskiwanie MFA

- Zapewnij **kody zapasowe** (recovery codes) — jednorazowe, generowane przy setup
- Wymagaj **wielu typow MFA** (TOTP + SMS) — mniejsze ryzyko utraty wszystkich
- Proces resetu musi byc **rownie bezpieczny** jak MFA — nie moze byc slabszym ogniwem
- Weryfikacja tozsamosci przy resecie: email link + pytania + weryfikacja manualna
- Notyfikuj uzytkownika o zmianach MFA przez out-of-band kanal (email, push)
- Zmiana czynnikow MFA = **operacja wysokiego ryzyka** — wymagaj re-autentykacji istniejacym czynnikiem

### Typowe ataki na MFA — co testowac

- **Pominicie kroku**: po hasle przejdz bezposrednio do chronionej strony (skip OTP)
- **Brute force OTP**: 4-cyfrowy = 10000 prob, 6-cyfrowy = 1M — sprawdz rate limiting
- **Reuse OTP**: uzyj tego samego kodu ponownie
- **Response manipulation**: zmien odpowiedz serwera z "false" na "true" w Burp
- **Race condition**: wyslij wiele requestow z roznym OTP jednoczesnie
- **Fallback bypass**: czy mozna przejsc na slabszy czynnik (SMS zamiast TOTP)?
- **Push fatigue**: wielokrotne wysylanie push → uzytkownik akceptuje przez zmeczenie
- **SIM swap**: czy SMS OTP jest jedynym czynnikiem?
- **Backup codes**: czy sa odpowiednio chronione? Czy mozna je wylistowac?

### Risk-Based Authentication (adaptacyjne MFA)

- Nie wymagaj MFA za kazdym razem — uwzglednij kontekst: IP, lokalizacja, urzadzenie
- Nowe urzadzenie/lokalizacja → wymagaj MFA
- Znane urzadzenie + znana lokalizacja → moze pominac MFA
- Sygnaly ryzyka: Tor, VPN, nowy kraj, godziny nocne, znane skompromitowane credentials
- Uwaga: sygnaly ryzyka moga byc spoofowane — nie polegaj na nich jako jedynej obronie

### Passkeys/FIDO2 — najlepsza opcja

- Kryptograficzne wiazanie z domena — **phishing-resistant**
- Nie wymagaja zapamietywania kodu — biometria lub PIN na urzadzeniu
- Klucz prywatny nigdy nie opuszcza urzadzenia
- Mozna synchronizowac miedzy urzadzeniami (iCloud Keychain, Google Password Manager)

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
