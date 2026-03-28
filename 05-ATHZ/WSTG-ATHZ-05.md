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

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V10.4.1 | OAuth Authorization Server | Verify that the authorization server validates redirect URIs based on a client-specific allowlist of pre-registered URIs using exact string comparison. |
| V10.4.2 | OAuth Authorization Server | Verify that, if the authorization server returns the authorization code in the authorization response, it can be used only once for a token request. For the second valid request with an authorization code that has already been used to issue an access token, the authorization server must reject a token request and revoke any issued tokens related to the authorization code. |
| V10.4.3 | OAuth Authorization Server | Verify that the authorization code is short-lived. The maximum lifetime can be up to 10 minutes for L1 and L2 applications and up to 1 minute for L3 applications. |
| V10.4.4 | OAuth Authorization Server | Verify that for a given client, the authorization server only allows the usage of grants that this client needs to use. Note that the grants 'token' (Implicit flow) and 'password' (Resource Owner Password Credentials flow) must no longer be used. |
| V10.4.5 | OAuth Authorization Server | Verify that the authorization server mitigates refresh token replay attacks for public clients, preferably using sender-constrained refresh tokens, i.e., Demonstrating Proof of Possession (DPoP) or Certificate-Bound Access Tokens using mutual TLS (mTLS). For L1 and L2 applications, refresh token rotation may be used. If refresh token rotation is used, the authorization server must invalidate the refresh token after usage, and revoke all refresh tokens for that authorization if an already used and invalidated refresh token is provided. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V10.1.1 | Generic OAuth and OIDC Security | Verify that tokens are only sent to components that strictly need them. For example, when using a backend-for-frontend pattern for browser-based JavaScript applications, access and refresh tokens shall only be accessible for the backend. |
| V10.1.2 | Generic OAuth and OIDC Security | Verify that the client only accepts values from the authorization server (such as the authorization code or ID Token) if these values result from an authorization flow that was initiated by the same user agent session and transaction. This requires that client-generated secrets, such as the proof key for code exchange (PKCE) 'code_verifier', 'state' or OIDC 'nonce', are not guessable, are specific to the transaction, and are securely bound to both the client and the user agent session in which the transaction was started. |
| V10.2.1 | OAuth Client | Verify that, if the code flow is used, the OAuth client has protection against browser-based request forgery attacks, commonly known as cross-site request forgery (CSRF), which trigger token requests, either by using proof key for code exchange (PKCE) functionality or checking the 'state' parameter that was sent in the authorization request. |
| V10.2.2 | OAuth Client | Verify that, if the OAuth client can interact with more than one authorization server, it has a defense against mix-up attacks. For example, it could require that the authorization server return the 'iss' parameter value and validate it in the authorization response and the token response. |
| V10.3.1 | OAuth Resource Server | Verify that the resource server only accepts access tokens that are intended for use with that service (audience). The audience may be included in a structured access token (such as the 'aud' claim in JWT), or it can be checked using the token introspection endpoint. |
| V10.3.2 | OAuth Resource Server | Verify that the resource server enforces authorization decisions based on claims from the access token that define delegated authorization. If claims such as 'sub', 'scope', and 'authorization_details' are present, they must be part of the decision. |
| V10.3.3 | OAuth Resource Server | Verify that if an access control decision requires identifying a unique user from an access token (JWT or related token introspection response), the resource server identifies the user from claims that cannot be reassigned to other users. Typically, it means using a combination of 'iss' and 'sub' claims. |
| V10.4.6 | OAuth Authorization Server | Verify that, if the code grant is used, the authorization server mitigates authorization code interception attacks by requiring proof key for code exchange (PKCE). For authorization requests, the authorization server must require a valid 'code_challenge' value and must not accept a 'code_challenge_method' value of 'plain'. For a token request, it must require validation of the 'code_verifier' parameter. |
| V10.5.1 | OIDC Client | Verify that the client (as the relying party) mitigates ID Token replay attacks. For example, by ensuring that the 'nonce' claim in the ID Token matches the 'nonce' value sent in the authentication request to the OpenID Provider (in OAuth2 refereed to as the authorization request sent to the authorization server). |
| V10.5.2 | OIDC Client | Verify that the client uniquely identifies the user from ID Token claims, usually the 'sub' claim, which cannot be reassigned to other users (for the scope of an identity provider). |
| V10.5.4 | OIDC Client | Verify that the client validates that the ID Token is intended to be used for that client (audience) by checking that the 'aud' claim from the token is equal to the 'client_id' value for the client. |
| V10.7.1 | Consent Management | Verify that the authorization server ensures that the user consents to each authorization request. If the identity of the client cannot be assured, the authorization server must always explicitly prompt the user for consent. |
| V10.7.2 | Consent Management | Verify that when the authorization server prompts for user consent, it presents sufficient and clear information about what is being consented to. When applicable, this should include the nature of the requested authorizations (typically based on scope, resource server, Rich Authorization Requests (RAR) authorization details), the identity of the authorized application, and the lifetime of these authorizations. |
| V10.7.3 | Consent Management | Verify that the user can review, modify, and revoke consents which the user has granted through the authorization server. |


---

## HackTricks Tips

### Redirect URI Attacks

- **Brak walidacji**: `redirect_uri=https://attacker.com/`
- **Regex bypass**: `match.com.evil.com`, `evil.com#match.com`, `match.com@evil.com`
- **Directory traversal**: `/oauth/../anything` jeśli sprawdzany tylko prefix
- **XSS na allowed domain**: code leaks via script execution
- **Wildcard subdomains**: subdomain takeover → valid callback

### State Parameter

- **Brak `state`** → cały login jest CSRF-owalny
- **`state` nie walidowany** w response → tamper i replay
- **Fixation**: podaj własny `state` w crafted auth URL

### Token/Code Issues

- **Code reuse**: replay code dwukrotnie; race condition z Turbo Intruder
- **Code not bound to client**: redeem App A's code na App B's token endpoint
- **Everlasting codes**: test redemption po 5-10 minutach
- **`access_token` w URL** → browser history, Referer, analytics logs

### SAML

- **Signature Removal**: Burp SAML Raider → "Remove Signatures" → forward
- **Certificate Faking**: "Save and Self-Sign" → re-sign z self-signed cert
- **XML Signature Wrapping (XSW #1-#8)**: forged assertion w różnych pozycjach struktury; SAML Raider automatyzuje
- **CVE-2024-45409 (ruby-saml/GitLab)**: patch NameID, assertion IDs, references — `python3 CVE-2024-45409.py -r response -n admin@x.com`
- **XXE w SAML**: SAMLResponse = deflate-compressed Base64 XML → inject `<!DOCTYPE>` z external entity
- **XSLT injection**: transforms wykonywane PRZED weryfikacją podpisu
- **Token Recipient Confusion**: replay SAMLResponse z SP-Legit na SP-Target jeśli oba ufają temu samemu IdP

### Inne

- **`prompt=none`**: suppress consent jeśli user zalogowany
- **Mutable claims**: `sub` vs `email` confusion — IdP pozwala zmienić email → ATO via "Login with Google"
- **Dynamic Client Registration SSRF**: inject attacker URLs w `logo_uri`, `jwks_uri`
