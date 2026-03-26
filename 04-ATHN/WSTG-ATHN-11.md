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

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.3.3 | General Authentication Security | Verify that either a multi-factor authentication mechanism or a combination of single-factor authentication mechanisms, must be used in order to access the application. For L3, one of the factors must be a hardware-based authentication mechanism which provides compromise and impersonation resistance against phishing attacks while verifying the intent to authenticate by requiring a user-initiated action (such as a button press on a FIDO hardware key or a mobile phone). Relaxing any of the considerations in this requirement requires a fully documented rationale and a comprehensive set of mitigating controls. |
| V6.5.1 | General Multi-factor authentication requirements | Verify that lookup secrets, out-of-band authentication requests or codes, and time-based one-time passwords (TOTPs) are only successfully usable once. |
| V6.5.2 | General Multi-factor authentication requirements | Verify that, when being stored in the application's backend, lookup secrets with less than 112 bits of entropy (19 random alphanumeric characters or 34 random digits) are hashed with an approved password storage hashing algorithm that incorporates a 32-bit random salt. A standard hash function can be used if the secret has 112 bits of entropy or more. |
| V6.5.3 | General Multi-factor authentication requirements | Verify that lookup secrets, out-of-band authentication code, and time-based one-time password seeds, are generated using a Cryptographically Secure Pseudorandom Number Generator (CSPRNG) to avoid predictable values. |
| V6.5.4 | General Multi-factor authentication requirements | Verify that lookup secrets and out-of-band authentication codes have a minimum of 20 bits of entropy (typically 4 random alphanumeric characters or 6 random digits is sufficient). |
| V6.5.5 | General Multi-factor authentication requirements | Verify that out-of-band authentication requests, codes, or tokens, as well as time-based one-time passwords (TOTPs) have a defined lifetime. Out of band requests must have a maximum lifetime of 10 minutes and for TOTP a maximum lifetime of 30 seconds. |
| V6.6.1 | Out-of-Band authentication mechanisms | Verify that authentication mechanisms using the Public Switched Telephone Network (PSTN) to deliver One-time Passwords (OTPs) via phone or SMS are offered only when the phone number has previously been validated, alternate stronger methods (such as Time based One-time Passwords) are also offered, and the service provides information on their security risks to users. For L3 applications, phone and SMS must not be available as options. |
| V6.6.2 | Out-of-Band authentication mechanisms | Verify that out-of-band authentication requests, codes, or tokens are bound to the original authentication request for which they were generated and are not usable for a previous or subsequent one. |
| V6.6.3 | Out-of-Band authentication mechanisms | Verify that a code based out-of-band authentication mechanism is protected against brute force attacks by using rate limiting. Consider also using a code with at least 64 bits of entropy. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.5.6 | General Multi-factor authentication requirements | Verify that any authentication factor (including physical devices) can be revoked in case of theft or other loss. |
| V6.5.7 | General Multi-factor authentication requirements | Verify that biometric authentication mechanisms are only used as secondary factors together with either something you have or something you know. |
| V6.5.8 | General Multi-factor authentication requirements | Verify that time-based one-time passwords (TOTPs) are checked based on a time source from a trusted service and not from an untrusted or client provided time. |
| V6.6.4 | Out-of-Band authentication mechanisms | Verify that, where push notifications are used for multi-factor authentication, rate limiting is used to prevent push bombing attacks. Number matching may also mitigate this risk. |
