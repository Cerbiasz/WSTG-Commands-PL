# WSTG-INPV-16 — Testing for HTTP Request Smuggling

## Cele

- Identify request boundary inconsistencies between frontend and backend
- Detect classic CL/TE desynchronization vulnerabilities

## KOMENDY

### smuggler.py

```bash
python3 smuggler.py -u "https://TARGET/"

```

### Reczne testowanie CL.TE

```bash
printf 'POST / HTTP/1.1\r\nHost: TARGET\r\nContent-Length: 6\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\nG' | ncat TARGET 443 --ssl

```

### Reczne testowanie TE.CL

```bash
printf 'POST / HTTP/1.1\r\nHost: TARGET\r\nContent-Length: 3\r\nTransfer-Encoding: chunked\r\n\r\n1\r\nG\r\n0\r\n\r\n' | ncat TARGET 443 --ssl

```

### Testowanie TE.TE (obfuskacja)

```bash
# Transfer-Encoding: chunked
# Transfer-Encoding: xchunked
# Transfer-Encoding : chunked
# Transfer-Encoding: chunked\r\nTransfer-Encoding: x

```

### h2c smuggling

```bash
curl --http2 -X PRI "https://TARGET/" -H "Upgrade: h2c"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Request Smuggling

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Request Smuggling/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp HTTP Request Smuggler extension
2. Testuj CL.TE, TE.CL i TE.TE warianty
3. Monitoruj odpowiedzi pod katem desynchronizacji
4. Testuj HTTP/2 downgrade attacks
5. Sprawdz czy mozna zatruć cache przez smuggling
6. Uzyj Burp Turbo Intruder do zaawansowanych testow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTTP_Strict_Transport_Security_Cheat_Sheet.md, REST_Security_Cheat_Sheet.md

### HTTP Request Smuggling — mechanizm

- Exploituje **roznice w parsowaniu** dlugosci requestu miedzy frontend (proxy/LB) a backend
- Frontend i backend nie zgadzaja sie gdzie konczy sie jeden request a zaczyna nastepny
- Skutek: atakujacy **przemyca** czesc swojego requestu do requestu innego uzytkownika

### Typy atakow

| Typ | Frontend czyta | Backend czyta | Opis |
|-----|---------------|---------------|------|
| CL.TE | Content-Length | Transfer-Encoding | Frontend ufa CL, backend przetwarza chunked |
| TE.CL | Transfer-Encoding | Content-Length | Frontend przetwarza chunked, backend ufa CL |
| TE.TE | Transfer-Encoding (wariant 1) | Transfer-Encoding (wariant 2) | Obfuskacja jednego z TE headers |

### Konsekwencje

- **Bypass zabezpieczen**: ominięcie WAF, kontroli dostepu na froncie
- **Cache poisoning**: zatrute response cachowane dla innych uzytkownikow
- **Credential hijacking**: przechwycenie requestu innego uzytkownika (cookies, auth headers)
- **Request routing**: przekierowanie requestu do innego backendu
- **Web cache deception**: serwer cachuje wrazliwe dane innego uzytkownika

### Obfuskacja Transfer-Encoding (TE.TE bypass)

- `Transfer-Encoding: xchunked`
- `Transfer-Encoding : chunked` (spacja przed dwukropkiem)
- `Transfer-Encoding: chunked` + `Transfer-Encoding: x`
- `Transfer-Encoding: chunked\r\n\t` (tab po CRLF)
- `X: x\r\nTransfer-Encoding: chunked` (line folding)

### Obrona

- Uzyj **HTTP/2** end-to-end — eliminuje desynchronizacje (ale sprawdz H2C smuggling)
- Nie mieszaj Content-Length i Transfer-Encoding — odrzucaj takie requesty
- Normalizuj naglowki na frontend proxy — usun niejednoznaczne TE headers
- Ustaw frontend i backend na **takie same reguły parsowania**
- Monitoruj anomalie: rozne dlugosci response, nieoczekiwane 400/500 odpowiedzi

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Collaborator Everywhere | Wstrzykiwanie naglowkow do odkrywania backendow przez pingbacki | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.2.1 | HTTP Message Structure Validation | Verify that all application components (including load balancers, firewalls, and application servers) determine boundaries of incoming HTTP messages using the appropriate mechanism for the HTTP version to prevent HTTP request smuggling. In HTTP/1.x, if a Transfer-Encoding header field is present, the Content-Length header must be ignored per RFC 2616. When using HTTP/2 or HTTP/3, if a Content-Length header field is present, the receiver must ensure that it is consistent with the length of the DATA frames. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.2.2 | HTTP Message Structure Validation | Verify that when generating HTTP messages, the Content-Length header field does not conflict with the length of the content as determined by the framing of the HTTP protocol, in order to prevent request smuggling attacks. |
| V4.2.3 | HTTP Message Structure Validation | Verify that the application does not send nor accept HTTP/2 or HTTP/3 messages with connection-specific header fields such as Transfer-Encoding to prevent response splitting and header injection attacks. |
| V4.2.5 | HTTP Message Structure Validation | Verify that, if the application (backend or frontend) builds and sends requests, it uses validation, sanitization, or other mechanisms to avoid creating URIs (such as for API calls) or HTTP request header fields (such as Authorization or Cookie), which are too long to be accepted by the receiving component. This could cause a denial of service, such as when sending an overly long request (e.g., a long cookie header field), which results in the server always responding with an error status. |
