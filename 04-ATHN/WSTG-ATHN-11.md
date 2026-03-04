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

