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

### Open Redirect — ryzyka

- **Phishing**: atakujacy wysyla link `trusted.com/redirect?url=evil.com` — ofiara ufa domenie
- **OAuth token theft**: redirect_uri → atakujacy kradnie authorization code
- **SSO bypass**: redirect po logowaniu do strony atakujacego
- **Chaining**: open redirect + SSRF, open redirect + XSS

### Obrona — hierarchia

1. **Unikaj user input w URL przekierowan** — najlepsza obrona
2. **Mapping IDs**: zamiast `?url=https://...` uzywaj `?id=1` → mapuj do dozwolonych URL
3. **Allowlist domen**: jawna lista dozwolonych domen do przekierowania
4. **Walidacja URL server-side**: sprawdz scheme (tylko https), host (tylko zaufane domeny)

### Typowe bypass techniki (testowanie)

- `//evil.com` — protocol-relative URL, przegladarka uzupelnia protokol
- `/\evil.com` — backslash jako separator
- `/%09/evil.com` — tab character bypass
- `https://trusted.com@evil.com` — userinfo w URL (user=trusted.com, host=evil.com)
- `https://evil.com#trusted.com` — fragment jako dezorientacja
- `data:text/html,<script>` — data URI scheme
- `javascript:alert(1)` — JavaScript pseudo-protocol

### Client-Side Redirect (DOM-based)

- JavaScript: `location.href = userInput`, `location.assign()`, `location.replace()`
- Waliduj URL PRZED przypisaniem do location — sprawdz czy zaczyna sie od `/` (relative) lub zaufanej domeny
- NIGDY nie przypisuj user input bezposrednio do `location.*`

### Walidacja URL — bezpieczna implementacja

- Parsuj URL (np. `new URL(input)`) — sprawdz `.hostname` przeciw allowlist
- Odrzuc: `javascript:`, `data:`, `vbscript:` schemes
- Sprawdz ze URL jest absolute i zaczyna sie od `https://`
- Uzywaj server-side walidacji — client-side mozna ominac

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.7.2 | Other Browser Security Considerations | Verify that the application will only automatically redirect the user to a different hostname or domain (which is not controlled by the application) where the destination appears on an allowlist. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.7.3 | Other Browser Security Considerations | Verify that the application shows a notification when the user is being redirected to a URL outside of the application's control, with an option to cancel the navigation. |
