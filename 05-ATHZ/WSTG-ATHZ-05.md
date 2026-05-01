# WSTG-ATHZ-05 — Testing for OAuth Weaknesses

## Cel

Audyt OAuth 2.0/OIDC: PKCE wymagany, exact-match redirect_uri (no wildcards/path traversal), state parameter validation, implicit grant deprecated, JWT validation poprawna (alg, signature, claims).

> **Test mostly manual**: wymaga interakcji z OAuth flow + Burp.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (7 kroków)

1. **Discovery**: GET `/.well-known/openid-configuration` (cross WSTG-INFO-03) - issuer, endpoints, supported flows.
2. **Flow type check**: czy implicit flow używany (deprecated)? Authorization Code z PKCE preferred.
3. **redirect_uri test**: bypass via:
   - `https://target.evil.com/callback` (subdomena atakera)
   - `https://target.com/callback/../evil` (path traversal)
   - `https://target.com@evil.com` (URL authority confusion)
   - Open redirector chain
4. **State parameter**: usuń state - czy aplikacja akceptuje (CSRF risk)?
5. **PKCE test**: jeśli flow public client, czy PKCE wymagany?
6. **Token validation**: JWT issuer/audience/expiration validated (cross WSTG-SESS-10)?
7. **Refresh token rotation**: czy refresh token rotated po użyciu?

### Co MUSI być sprawdzone (15 punktów)

- [ ] OpenID configuration accessible (`/.well-known/openid-configuration`)
- [ ] PKCE wymagany dla public clients
- [ ] Authorization Code flow (nie implicit)
- [ ] redirect_uri exact match (nie wildcard)
- [ ] redirect_uri path traversal blocked
- [ ] redirect_uri subdomain bypass blocked
- [ ] redirect_uri @ confusion blocked (`target.com@evil.com`)
- [ ] state parameter required
- [ ] state validated cross-site
- [ ] code single-use (jednorazowy)
- [ ] code short TTL (1-10 min)
- [ ] iss parameter validated (multi-AS apps)
- [ ] Refresh token rotation
- [ ] Scope validation (nie scope creep)
- [ ] JWT validation (alg, exp, aud, iss)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — OAuth2_Cheat_Sheet.md

### Fundamenty bezpieczeństwa OAuth 2.0

- **PKCE** (Proof Key for Code Exchange) jest **obowiązkowe** dla klientów publicznych i zalecane dla wszystkich
- **Implicit grant jest DEPRECATED** — używaj Authorization Code + PKCE zamiast tego
- **Resource Owner Password Credentials grant** — NIE używaj (ujawnia credentials klientowi)
- Wszystkie komunikacja OAuth musi być przez **TLS** — redirect_uri nie może używać `http://`
- Używaj parametru **state** (lub PKCE) do ochrony przed CSRF na OAuth flow
- Przy wielu Authorization Servers: używaj parametru **iss** do identyfikacji servera (ochrona przed mix-up)

### redirect_uri — ścisła walidacja

- Używaj **dokładnego dopasowania** (exact match) — nie wzorców, nie wildcardów
- NIE pozwalaj na open redirectors na URL-ach aplikacji — mogą być użyte do exfiltration kodu
- Ataki na redirect_uri:
  - `https://evil.com/callback` — całkowicie inny serwer
  - `https://target.evil.com/callback` — subdomena atakującego
  - `https://target.com/callback/../evil` — path traversal
  - `https://target.com/callback?next=evil.com` — open redirect chain
  - `https://target.com@evil.com` — URL authority confusion

### PKCE — implementacja

- Klient generuje `code_verifier` (random 43-128 znaków)
- Wysyła `code_challenge = SHA256(code_verifier)` w authorization request
- Wymienia code z code_verifier — server weryfikuje że SHA256(code_verifier) == code_challenge
- Chroni przed: code interception (kradzież authorization code w network/log)

### Token Validation — Authorization Server's responsibility

- Aplikacja kliencka musi WERYFIKOWAĆ tokeny:
  - **iss** (issuer): zgodność z expected AS
  - **aud** (audience): zgodność z client_id
  - **exp** (expiration): nie przeterminowany
  - **nbf** (not before): aktualnie ważny
  - **Signature**: validate against AS's public key (jwks_uri)

### OAuth bypass — typowe wektory

- **redirect_uri manipulation**: wykraść authorization code via attacker callback
- **Mix-up attack**: wieloma AS - atakujący confuses client which AS issued token
- **CSRF na OAuth flow**: brak `state` → atakujący może login victim do swojego konta
- **Refresh token theft**: jeśli refresh token bez rotation + bez TTL = persistent access
- **Scope creep**: refresh token requests new scopes broader than initial grant

## Pentesterskie deep dive

### Mniej znane techniki

- **Authorization Server Confusion (Mix-up)**: aplikacja allows multiple AS - atakujący tricks client to send code to wrong AS.
- **Open redirector chain**: legit `redirect_uri=https://target.com/redirect?next=evil.com` if target has open redirect.
- **PKCE downgrade**: jeśli AS akceptuje request bez PKCE (gdy public client) - atakujący steals code, exchanges bez PKCE.
- **JWT confusion via embedded jwk**: niektóre OAuth implementations honor `jwk` w JWT header → atakujący includes own key.
- **OAuth response_type confusion**: switch `response_type=code` to `response_type=code id_token` może bypass różne validations.

### Common pitfalls

- **redirect_uri whitelist via startsWith**: `target.com/callback` matches `target.com/callback.evil.com`.
- **state nie validated on callback**: atakujący CSRF login victim.
- **OAuth provider weak**: enterprise SSO przez weak provider.

### Świeżynki z research

- **PortSwigger OAuth Lab**: https://portswigger.net/web-security/oauth
- **Sam Curry OAuth research**: https://samcurry.net/
- **OAuth 2.1 draft**: https://oauth.net/2.1/
- **HackTricks OAuth**: https://book.hacktricks.xyz/pentesting-web/oauth-to-account-takeover

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| EsPReSSO | OAuth + SAML testing |
| JWT Editor | Token manipulation |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/05-Authorization_Testing/05-Testing_for_OAuth_Weaknesses
- OWASP OAuth2 CS: https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html
- OAuth 2.1 draft: https://oauth.net/2.1/
- PortSwigger OAuth: https://portswigger.net/web-security/oauth
- HackTricks OAuth: https://book.hacktricks.xyz/pentesting-web/oauth-to-account-takeover

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V51.2.1 | OAuth use authorization code flow with PKCE. |
| V51.2.2 | redirect_uri exact match, no wildcards. |
| V51.4.1 | OAuth state parameter required. |
