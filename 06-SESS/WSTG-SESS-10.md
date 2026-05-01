# WSTG-SESS-10 — Testing JSON Web Tokens (JWT)

## Cel

Audyt JWT: alg=none bypass, weak HS256 secret (crackable), key confusion (RS256 → HS256), JWT w URL/Referer leak, sensitive data w payload, missing signature validation.

## Automatyzacja Nuclei

```bash
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-10-jwt.yaml
```

Wykrywa: alg=none patterns, JWT w URL/href/src, JWT w response, JWT + JWKS endpoint exposed.

### Active testing (manual)

```bash
# Burp JWT Editor - manipulate alg, signature, claims
# https://github.com/PortSwigger/jwt-editor

# hashcat HS256 crack
hashcat -m 16500 -a 0 jwt.txt resources/seclists/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt

# jwt_tool
python3 jwt_tool.py <JWT> -X k -pl wordlist.txt
```

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| alg=none detection | ✓ |
| JWT w URL | ✓ |
| JWT w Authorization header (response) | ✓ |
| JWKS endpoint exposed | ✓ |
| HS256 secret crack | manual (hashcat) |
| Key confusion attack | manual (Burp JWT Editor) |
| kid path injection | manual |
| JWT replay | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (8 kroków)

1. **JWT identification**: cookies, headers, body. Decode (jwt.io).
2. **alg analysis**: jeśli HS256 z guessable secret, hashcat crack.
3. **alg=none test**: Burp JWT Editor → set alg to none → check if accepted.
4. **Key confusion test**: jeśli RS256, sprawdzić czy backend akceptuje HS256 z public key as secret.
5. **kid manipulation**: jeśli `kid` claim, sprawdzić path traversal (`../../../../dev/null`).
6. **Expiration check**: czy `exp` enforced? Replay expired token?
7. **Replay test**: użyj JWT z innej sesji - czy działa?
8. **Sensitive data audit**: payload zawiera password/PII?

### Co MUSI być sprawdzone (12 punktów)

- [ ] alg=none rejected
- [ ] HS256 secret strength (crack test)
- [ ] RS256 vs HS256 confusion blocked
- [ ] kid path traversal blocked
- [ ] exp claim enforced
- [ ] iat/nbf claims validated
- [ ] aud (audience) validated
- [ ] iss (issuer) validated
- [ ] Token NIE w URL
- [ ] Payload nie zawiera password/PII
- [ ] JWKS endpoint authz (czy public OK?)
- [ ] Refresh token rotation

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — JSON_Web_Token_for_Java_Cheat_Sheet.md

### Atak "alg:none" — brak podpisu

- Atakujący zmienia `"alg":"HS256"` na `"alg":"none"` — niektóre biblioteki akceptują token BEZ podpisu
- **Obrona**: JAWNIE wymagaj oczekiwanego algorytmu przy walidacji — `JWT.require(Algorithm.HMAC256(key))`
- Używaj biblioteki, która NIE jest podatna na ten atak (sprawdź CVE)

### Atak Key Confusion (RS256 → HS256)

- JWT podpisany RS256 (asymetryczny) — atakujący zmienia na HS256 (symetryczny) i używa public key jako secret
- **Obrona**: waliduj algorytm server-side, nie polegaj na `alg` z headera tokenu
- Używaj oddzielnych kluczy do HMAC i RSA — nie mieszaj

### Token Sidejacking Prevention

- Dodaj **user context** (fingerprint) do tokenu — losowy string w hardened cookie (`__Secure-Fgp`)
- Przechowuj **SHA-256 hash** fingerprint w JWT (nie raw value — obrona przed XSS)
- Atakujący kradnący JWT bez cookie fingerprint nie może go wykorzystać

### Token Revocation

- JWT są **stateless** — domyślnie nie da się unieważnić
- Implementuj **denylist** (Redis, DB) — sprawdzaj przy każdym request
- Alternatywa: krótki TTL access token (5-15 min) + refresh token z rotation

### kid Header Injection

- `kid` (Key ID) header pozwala wybrać key z key store
- Atakujący może użyć **path traversal** w `kid`: `kid: "../../../dev/null"`
- Lub **SQL injection** w `kid` jeśli używane w query
- **Obrona**: waliduj `kid` przeciw allowlist znanych key IDs

### JWKS endpoint

- `/.well-known/jwks.json` musi być publicznie dostępny dla JWT validation
- Sprawdź czy nie ujawnia private keys (powinny być TYLKO public)
- `jku` claim w JWT pozwala specify JWKS URL — **NIGDY** nie ufaj user-supplied `jku`

## Pentesterskie deep dive

### Mniej znane techniki

- **JWT alg=none variations**: `none`, `None`, `NONE`, `nONe` - niektóre biblioteki case-sensitive.
- **Embedded JWK in header**: `jwk` header attack - atakujący includes own public key in header.
- **`jku` to attacker URL**: jeśli aplikacja blindly fetches JWKS from `jku`, atakujący sets jku to evil.com.
- **HS256 brute-force with rockyou**: 10M attempts/sec na CPU, 1B+ na GPU.
- **psychic signatures (CVE-2022-21449)**: Java < 18 ECDSA signature validation bug.

### Common pitfalls

- **`exp` checked tylko expiration ale nie nbf/iat**: atakujący może użyć tokenu pre-dated.
- **Payload contains user role**: atakujący flips `role: user` → `role: admin` and (jeśli alg=none possible) bypass.

### Świeżynki z research

- **PortSwigger JWT Lab**: https://portswigger.net/web-security/jwt
- **HackTricks JWT**: https://book.hacktricks.xyz/pentesting-web/hacking-jwt-json-web-tokens
- **jwt_tool**: https://github.com/ticarpi/jwt_tool
- **Burp JWT Editor**: https://github.com/PortSwigger/jwt-editor

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| JWT Editor | Manipulacja alg, signature, claims |
| JWT Heartbreaker | Auto-detect CVE-2018-0114 |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/06-Session_Management_Testing/10-Testing_JSON_Web_Tokens
- OWASP JWT CS: https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
- PortSwigger JWT: https://portswigger.net/web-security/jwt
- HackTricks JWT: https://book.hacktricks.xyz/pentesting-web/hacking-jwt-json-web-tokens
- jwt_tool: https://github.com/ticarpi/jwt_tool

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V3.5.1 | JWT validates algorithm explicitly. |
| V3.5.2 | JWT signed with strong algorithm. |
| V3.5.3 | JWT secrets/keys properly managed. |
