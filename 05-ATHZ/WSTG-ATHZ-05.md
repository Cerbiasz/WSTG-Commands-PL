# WSTG-ATHZ-05 — Testing for OAuth Weaknesses

## Cele

- Determine if OAuth2 implementation is vulnerable or using a deprecated or custom implementation

## KOMENDY

### Analiza OAuth flow

```bash
curl -v "https://TARGET/oauth/authorize?client_id=CLIENT_ID&redirect_uri=https://TARGET/callback&response_type=code&scope=openid" 2>&1

```

### Test redirect_uri manipulation

```bash
curl -v "https://TARGET/oauth/authorize?client_id=CLIENT_ID&redirect_uri=https://evil.com/callback&response_type=code" 2>&1
curl -v "https://TARGET/oauth/authorize?client_id=CLIENT_ID&redirect_uri=https://TARGET.evil.com/callback&response_type=code" 2>&1
curl -v "https://TARGET/oauth/authorize?client_id=CLIENT_ID&redirect_uri=https://TARGET/callback/../evil&response_type=code" 2>&1

```

### Test state parameter

```bash
# Sprawdz czy state jest obecny i walidowany
curl -v "https://TARGET/oauth/authorize?client_id=CLIENT_ID&redirect_uri=https://TARGET/callback&response_type=code" 2>&1 | grep "state"

```

### Test token leakage

```bash
# Sprawdz Referer header po przekierowaniu
# Sprawdz czy token jest w URL (fragment vs query)

```

### Test scope escalation

```bash
curl -v "https://TARGET/oauth/authorize?client_id=CLIENT_ID&redirect_uri=https://TARGET/callback&response_type=code&scope=admin" 2>&1

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings OAuth

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/OAuth Misconfiguration/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zmapuj caly OAuth flow w Burp (authorize -> callback -> token)
2. Testuj open redirect via redirect_uri
3. Sprawdz czy state parameter jest uzywany i walidowany (CSRF)
4. Testuj token reuse i token leakage (Referer, URL)
5. Sprawdz scope escalation
6. Testuj PKCE implementation (code_challenge)
7. Sprawdz czy implicit flow jest uzywany (mniej bezpieczny)
8. Testuj client_secret exposure w frontend code


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — OAuth2_Cheat_Sheet.md

### Fundamenty bezpieczenstwa OAuth 2.0

- **PKCE** (Proof Key for Code Exchange) jest **obowiazkowe** dla klientow publicznych i zalecane dla wszystkich
- **Implicit grant jest DEPRECATED** — uzywaj Authorization Code + PKCE zamiast tego
- **Resource Owner Password Credentials grant** — NIE uzywaj (ujawnia credentials klientowi)
- Wszystkie komunikacja OAuth musi byc przez **TLS** — redirect_uri nie moze uzywac `http://`
- Uzywaj parametru **state** (lub PKCE) do ochrony przed CSRF na OAuth flow
- Przy wielu Authorization Servers: uzywaj parametru **iss** do identyfikacji servera (ochrona przed mix-up)

### redirect_uri — scisla walidacja

- Uzywaj **dokladnego dopasowania** (exact match) — nie wzorcow, nie wildcardow
- NIE pozwalaj na open redirectors na URL-ach aplikacji — moga byc uzyte do exfiltration kodu
- Ataki na redirect_uri:
  - `https://evil.com/callback` — calkowicie inny serwer
  - `https://target.evil.com/callback` — subdomena atakujacego
  - `https://target.com/callback/../evil` — path traversal
  - `https://target.com/callback?next=evil.com` — open redirect chain
  - `https://target.com@evil.com` — URL authority confusion

### PKCE — implementacja

- Klient generuje losowy `code_verifier` (min. 43 znaki, CSPRNG)
- Hash `code_verifier` → `code_challenge` (SHA-256) wysylany w authorization request
- Authorization Server musi **wymuszac** PKCE — odrzucac requesty bez `code_challenge`
- Chroni przed **authorization code interception** — nawet jesli kod wycieknie, nie mozna go uzyc

### Tokeny — bezpieczenstwo

- **Access tokens**: krotkoterminowe (minuty-godziny), ograniczone scope i audience
- **Refresh tokens**: dluzsze, chronione rotacja (nowy refresh token przy kazdym uzyciu)
- **Audience restriction**: access token musi byc ograniczony do konkretnego Resource Server
- **Scope restriction**: przyznawaj **minimalne** uprawnienia — principle of least privilege
- Sender-constrained tokens (DPoP, mTLS) — wiaza token z klientem kryptograficznie

### DPoP (Demonstration of Proof of Possession)

- Klient generuje pare kluczy, podpisuje proof JWT z hashem tokenu
- Resource Server weryfikuje proof + token — atakujacy z tokenem nie moze go uzyc bez klucza
- Nie wymaga mTLS — dziala w przeglarkach i mobile apps
- Chroni przed **token replay** i **token theft**

### Przechowywanie tokenow

- **Backend (server-side)**: najlepszy — tokeny nigdy nie trafiaja do przegladarki
- **HttpOnly Secure cookie**: akceptowalne — chronione przed XSS
- **sessionStorage**: akceptowalne dla SPA — nie przezywa zamkniecia karty
- **localStorage**: **UNIKAJ** — dostepne z JavaScript, podatne na XSS
- **URL/query parameters**: **NIGDY** — logowane, Referer leakage, historia przegladarki

### Co testowac

- Czy implicit flow jest uzywany (token w URL fragment)?
- Czy PKCE jest wymagane?
- Czy state parameter jest present i walidowany?
- Czy redirect_uri jest scisle walidowane (exact match)?
- Czy token leakuje przez Referer, URL, logi?
- Czy scope escalation jest mozliwe?
- Czy client_secret jest widoczne w frontend code?
- Czy refresh token ma rotacje?
- Czy mozna reuse authorization code?

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| OAUTHScan | Skanowanie podatnosci w implementacjach OAuth | [GitHub](https://github.com/AresS31/OAUTHScan) |
| EsPReSSO | Testowanie bezpieczenstwa SSO (OAuth, SAML, OpenID) | [GitHub](https://github.com/RUB-NDS/BurpSSOExtension) |
