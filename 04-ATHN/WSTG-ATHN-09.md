# WSTG-ATHN-09 — Testing for Weak Password Change or Reset Functionalities

## Cele

- Determine whether the password change and reset functionality allows accounts to be compromised

## KOMENDY

### Test reset hasla

```bash
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com"

```

### Sprawdzenie tokenu reset

```bash
# Czy token jest przewidywalny? Czy wygasa? Czy jest jednorazowy?
curl -s "https://TARGET/reset-password?token=TOKEN_VALUE"

```

### Test zmiany hasla bez starego hasla

```bash
curl -X POST "https://TARGET/change-password" -H "Cookie: session=TOKEN" -d "new_password=newpass&confirm_password=newpass"

```

### CSRF na zmiane hasla

```bash
curl -X POST "https://TARGET/change-password" -H "Cookie: session=TOKEN" -d "old_password=old&new_password=new&confirm_password=new"
# Sprawdz czy jest CSRF token

```

### Test predictability tokenu

```bash
# Wygeneruj wiele tokenow i porownaj wzorce
for i in $(seq 1 5); do curl -s -X POST "https://TARGET/forgot-password" -d "email=test${i}@test.com" -v 2>&1 | grep "token\|Location"; done

```

### Host header poisoning na reset

```bash
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com" -H "Host: evil.com"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test logiczny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz caly flow resetu hasla (request -> email -> token -> zmiana)
2. Testuj czy token wygasa po uzyciu
3. Testuj czy token wygasa po czasie
4. Sprawdz czy mozna zmienic haslo innego uzytkownika
5. Testuj Host header injection na endpoint resetu
6. Sprawdz czy stare haslo jest wymagane przy zmianie
7. Testuj CSRF na formularzu zmiany hasla
8. Sprawdz politykę nowego hasła (dlugosc, zlozonosc)

