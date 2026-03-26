# WSTG Commands PL

Komendy i narzedzia do testow penetracyjnych aplikacji webowych oparte na metodologii OWASP Web Security Testing Guide (WSTG) v4.2.

Kazdy plik `.md` zawiera gotowe komendy, payloady, rozszerzenia Burp Suite oraz wskazowki ASVS 5.0 pogrupowane wedlug poziomow (L1/L2/L3).

## Struktura

| Folder | Kategoria | Opis |
|---|---|---|
| `01-INFO` | Information Gathering | Rekonesans, fingerprinting, mapowanie |
| `02-CONF` | Configuration | Konfiguracja serwera, naglowki, TLS |
| `03-IDNT` | Identity Management | Role, rejestracja, enumeracja kont |
| `04-ATHN` | Authentication | Uwierzytelnianie, hasla, MFA |
| `05-ATHZ` | Authorization | Autoryzacja, IDOR, OAuth |
| `06-SESS` | Session Management | Sesje, ciasteczka, JWT, CSRF |
| `07-INPV` | Input Validation | Injection (SQL, XSS, XXE, SSTI, SSRF...) |
| `08-ERRH` | Error Handling | Obsluga bledow, stack traces |
| `09-CRYP` | Cryptography | TLS, szyfrowanie, padding oracle |
| `10-BUSL` | Business Logic | Logika biznesowa, upload, platnosci |
| `11-CLNT` | Client-side | DOM XSS, clickjacking, CORS, WebSocket |
| `12-APIT` | API Testing | REST, GraphQL, BOLA |
| `Payloads/` | Payloady | Gotowe listy payloadow do testow |

## Dodatkowe pliki

- `Others.md` — dodatkowe naglowki bezpieczenstwa i konfiguracja transportu
- `ASVS_WEB_APP.csv` — pelna baza wymagan OWASP ASVS 5.0

## TODO

- [ ] Dodanie payloadow do pozostalych modulow
- [ ] Przetlumaczenie celow (sekcja "Cele" w kazdym pliku .md) na jezyk polski
