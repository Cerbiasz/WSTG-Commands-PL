# WSTG-ATHN-08 — Testing for Weak Security Question Answer

## Cele

- Determine the complexity and how straight-forward the questions are
- Assess possible user answers and brute force capabilities

## KOMENDY

### Sprawdzenie jakie pytania sa uzywane

```bash
curl -s "https://TARGET/forgot-password" | grep -i "security question\|secret question\|question"
curl -s "https://TARGET/register" | grep -i "security question\|secret question"

```

### Testowanie brute force odpowiedzi

```bash
ffuf -u "https://TARGET/forgot-password" -X POST -d "username=admin&answer=FUZZ" -w Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt -mc 200,302 -o output_ffuf_security_q.json

```

### Testowanie slabych pytan

```bash
# Czy pytania sa zbyt proste? (ulubiony kolor, miasto urodzenia)
# Czy odpowiedzi sa publicznie dostepne? (social media)

```

## KOMENDY Z WORDLISTAMI

### SecLists common passwords (jako potencjalne odpowiedzi)

```bash
# Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt
# Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/common-passwords-win.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz jakie pytania bezpieczenstwa sa dostepne
2. Ocen czy pytania sa zbyt proste lub odpowiedzi publiczne
3. Testuj brute force odpowiedzi z Burp Intruder
4. Sprawdz czy jest lockout po blednych odpowiedziach
5. Testuj czy mozna zmienic pytanie na prostsze

