# WSTG-CLNT-04 — Testing for Client-side URL Redirect

## Cele

- Identify injection points that handle URLs or paths
- Assess the locations that the system could redirect to

## KOMENDY

### Open redirect testing

```bash
curl -v "https://TARGET/redirect?url=https://evil.com" 2>&1 | grep "Location:"
curl -v "https://TARGET/login?next=https://evil.com" 2>&1 | grep "Location:"
curl -v "https://TARGET/goto?url=//evil.com" 2>&1 | grep "Location:"
curl -v "https://TARGET/redirect?url=https://evil.com%23.TARGET" 2>&1 | grep "Location:"
curl -v "https://TARGET/redirect?url=https://TARGET@evil.com" 2>&1 | grep "Location:"
curl -v "https://TARGET/redirect?url=javascript:alert(1)" 2>&1 | grep "Location:"

```

### Parametry typowe dla redirectow

```bash
# url=, redirect=, next=, return=, returnUrl=, goto=, destination=, redir=, out=, view=, to=

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Open Redirect

```bash
ffuf -u "https://TARGET/redirect?url=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Open Redirect/Intruder/Open-Redirect-payloads.txt" -mc 301,302 -o output_ffuf_openredir.json

ffuf -u "https://TARGET/redirect?url=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Open Redirect/Intruder/open_redirect_wordlist.txt" -mc 301,302 -o output_ffuf_openredir2.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj parametry URL w requestach (url=, redirect=, next=)
2. Testuj przekierowanie na zewnetrzna domene
3. Testuj bypass: //evil.com, /\evil.com, /%09/evil.com
4. Sprawdz client-side redirect w JavaScript (location.href, location.assign)
5. Testuj data: i javascript: URI schemes


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Unvalidated_Redirects_and_Forwards_Cheat_Sheet.md

- Unikaj uzywania user input w URL-ach przekierowan
- Uzywaj allowlist dozwolonych URL-ow/domen do przekierowania
- Waliduj URL server-side — nie polegaj na kontrolach klienckich
- Nie uzywaj parametrow URL do definiowania celu przekierowania (np. ?redirect=)

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
