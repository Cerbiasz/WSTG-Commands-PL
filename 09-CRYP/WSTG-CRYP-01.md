# WSTG-CRYP-01 — Testing for Weak Transport Layer Security

## Cel

Weryfikacja konfiguracji TLS: protokoły (TLS 1.0/1.1 wyłączone, 1.2/1.3 enabled), cipher suites (brak null/anonymous/EXPORT/RC4/3DES, preferencja AEAD z PFS), HSTS, certyfikat (RSA 2048+/ECDSA P-256+, SHA-256+, SAN). Słaba TLS = MitM possible.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-cryp-01-tls-config.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-cryp-01.jsonl
```

Szablon HTTP-side: HSTS missing, mixed content (HTTPS strona z HTTP resources), cookies bez Secure flag, CSP bez `upgrade-insecure-requests`. Pełna analiza TLS (protokoły, cipher suites, certyfikat) wymaga TLS-level toolingu.

### Pełna analiza TLS - dedicated tooling

```bash
# nuclei ssl/ - TLS-level scanner (protocol versions, expired certs, weak ciphers)
nuclei -target https://target.com \
       -t resources/nuclei-templates/ssl/

# testssl.sh - kompleksowa analiza
testssl.sh https://target.com --full

# sslyze - szybki, headless TLS scanner
python3 -m sslyze --regular target.com

# SSL Labs (online)
curl -s "https://api.ssllabs.com/api/v3/analyze?host=target.com&fromCache=on" | jq

# CryptCheck.fr (online)
curl -s "https://tls.imirhil.fr/https/target.com.json" | jq
```

### Cross-reference templates

```bash
# WSTG-CONF-07 (HSTS specifically)
nuclei -l burp-export.xml -im burp -t templates/wstg-conf-07-hsts.yaml

# WSTG-CRYP-03 (unencrypted channels - mixed content overlap)
nuclei -l burp-export.xml -im burp -t templates/wstg-cryp-03-unencrypted-channels.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| HSTS missing/weak (HTTP-side) | ✓ | (cross-ref CONF-07) |
| Mixed content (HTTPS z HTTP resources) | ✓ | dynamic JS injection - manual |
| Cookie bez Secure flag | ✓ | (cross WSTG-SESS-02) |
| CSP `upgrade-insecure-requests` | ✓ | — |
| Protocol versions (SSLv2/v3, TLS 1.0/1.1) | — | testssl.sh / nuclei ssl/ |
| Cipher suites (NULL/EXPORT/RC4/3DES) | — | testssl.sh / nuclei ssl/ |
| Certificate validity / expiry | — | nuclei ssl/expired-ssl.yaml |
| Certificate signature algorithm (SHA-1) | — | testssl.sh |
| HSTS preload list status | — | manual via hstspreload.org |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **TLS protocol scan**: `testssl.sh -p target.com` lub `nuclei -t ssl/` — które wersje TLS są aktywne.
2. **Cipher suite enumeration**: `testssl.sh -E` — lista wszystkich cipher suites + ocena.
3. **Certificate analysis**: ważność, signature algorithm (musi być SHA-256+), klucz size, SAN coverage, CT logs.
4. **HSTS verification**: nasz szablon + cross-ref WSTG-CONF-07.
5. **Mixed content scan**: nasz szablon + DevTools Console z testowanej strony.
6. **Cookie flags audit**: per cookie sprawdzić Secure + HttpOnly + SameSite (cross WSTG-SESS-02).

### Co MUSI być sprawdzone (15 punktów)

- [ ] TLS 1.0 wyłączone
- [ ] TLS 1.1 wyłączone
- [ ] TLS 1.2 + 1.3 włączone (preferowane 1.3)
- [ ] Brak NULL ciphers, anonymous, EXPORT, RC4, 3DES, DES
- [ ] AEAD ciphers z PFS preferowane (AES-GCM, ChaCha20-Poly1305 z ECDHE)
- [ ] Cert klucz: RSA 2048+/ECDSA P-256+
- [ ] Cert signature: SHA-256 lub silniejszy
- [ ] Cert SAN: właściwa domena + warianty
- [ ] Cert ważność: nie wygasły, nie self-signed (chyba że internal)
- [ ] CAA DNS records ustawione
- [ ] HSTS poprawny (max-age, includeSubDomains, preload)
- [ ] HTTP → HTTPS redirect 301
- [ ] Cookie Secure flag na wszystkich cookies
- [ ] Brak mixed content na HTTPS pages
- [ ] CSP `upgrade-insecure-requests` lub `block-all-mixed-content`

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transport_Layer_Security_Cheat_Sheet.md, TLS_Cipher_String_Cheat_Sheet.md

### Konfiguracja protokołów

- **TLS 1.3** (preferowany) + **TLS 1.2** (jeśli wymagana kompatybilność) — JEDYNE dozwolone protokoły
- **WYŁĄCZ**: SSL 2.0, SSL 3.0, TLS 1.0, TLS 1.1 — PCI DSS ZABRANIA używania legacy protocols
- Włącz `TLS_FALLBACK_SCSV` extension — zapobiega downgrade attacks na nowsze klienty
- TLS 1.0 TYLKO w wyjątkowych sytuacjach (legacy browsers np. IE 10) — z ostrożnością

### Cipher suites

- **Preferuj AEAD**: AES-GCM, ChaCha20-Poly1305 — zapewniają poufność + integralność + autentyczność
- **Perfect Forward Secrecy (PFS)**: ECDHE key exchange — kompromitacja klucza nie ujawnia przeszłego ruchu
- **WYŁĄCZ**: Null ciphers, Anonymous ciphers, EXPORT ciphers, RC4, DES, 3DES
- Generator bezpiecznej konfiguracji: [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- Grupy Diffie-Hellman (TLS 1.3): `x25519`, `prime256v1`/`secp256r1`, `ffdhe3072`

### Certyfikaty

- Klucz prywatny: min **RSA 2048-bit** lub **ECDSA P-256** (Curve25519 preferowany)
- Algorytm hashowania: **SHA-256** — NIE używaj MD5 ani SHA-1
- Domain Name w certyfikacie: ustaw w `subjectAlternativeName` (SAN) — Chrome ignoruje CN
- **Wildcard certificates**: używaj ostrożnie — kompromitacja klucza dotyczy WSZYSTKICH subdomen
  - Nigdy nie współdziel wildcard między systemami o różnym poziomie zaufania (np. VPN + publiczny web server)
- **CAA DNS records**: ogranicz które CA mogą wydawać certyfikaty dla Twojej domeny
- **Let's Encrypt**: darmowe certyfikaty DV, zaufane przez wszystkie major browsers

### HSTS (HTTP Strict Transport Security)

- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- Wymusza HTTPS na wszystkich przyszłych requestach — przeglądarka nigdy nie użyje HTTP
- `includeSubDomains` — stosuje się do wszystkich subdomen
- `preload` — dodanie do listy preload w przeglądarkach (trwałe)
- Ustaw HSTS PO potwierdzeniu że HTTPS działa poprawnie — błąd może zablokować dostęp

### Aplikacja — zasady

- **TLS na WSZYSTKICH stronach** — nie tylko login/checkout; strony HTTP mogą ujawnić session cookies
- **Redirect HTTP → HTTPS**: HTTP 301 permanent redirect, potem wzmocnij HSTS
- **API endpoints**: wyłącz HTTP całkowicie — failuj requesty zamiast redirectować
- **Nie mieszaj TLS i non-TLS**: nie ładuj JS/CSS przez HTTP na stronie HTTPS (mixed content)
- **Secure cookie flag**: WSZYSTKIE cookies z atrybutem `Secure` — nie wysyłaj przez HTTP
- **Cache-Control**: `no-cache, no-store, must-revalidate` na odpowiedziach z wrażliwymi danymi

### Mutual TLS (mTLS)

- Klient i serwer wzajemnie weryfikują tożsamość przez certyfikaty
- Zapobiega man-in-the-middle nawet jeśli atakujący ma trusted CA cert
- Rozważ dla: high-value applications, API-to-API, wewnętrzne microservices
- Wyzwania: zarządzanie certyfikatami klienta, overhead administracyjny

### Testowanie konfiguracji TLS

- Online: SSL Labs, CryptCheck, Hardenize, ImmuniWeb, Mozilla Observatory
- Offline: testssl.sh, SSLyze, SSLScan, CipherScan, O-Saft
- Aktualizuj biblioteki kryptograficzne — Heartbleed, POODLE, BEAST, CRIME, FREAK, Logjam

## Pentesterskie deep dive

### Mniej znane techniki

- **Heartbleed (CVE-2014-0160)** — OpenSSL bug pozwala read pamięci serwera, leak private keys. Test: `nmap --script ssl-heartbleed -p 443 target`. Mimo wieku, wciąż występuje na legacy systemach.
- **CRIME / BREACH attacks**: kompresja TLS (CRIME) lub HTTP (BREACH) z reflected secret w response = chosen-plaintext attack na CSRF tokens. Wyłącz HTTP compression dla responses z secrets.
- **TLS 1.3 0-RTT replay**: TLS 1.3 early data może być replay'owana → idempotent endpoints OK, non-idempotent jak `/transfer-money` vulnerable.
- **Certificate Transparency (CT) monitoring**: CAA DNS + CT logs daje real-time alerts gdy ktoś wystawia cert dla twojej domeny — wykrywa unauthorized certs (gdy DNS hijack).
- **Cipher suite ordering attack**: gdy klient i serwer mają overlap cipherów, server-preferred może wybrać słabszy. Konfiguracja `SSLHonorCipherOrder on` (Apache) wymusza serwer's preference.
- **Post-quantum hybrid TLS**: nowe TLS 1.3 cipher suites z post-quantum keys (Kyber, Dilithium) zaczynają się pojawiać w cloud deployments — przyszły standard.

### Common pitfalls

- **HTTPS on internal networks "not needed"**: błędne myślenie. Internal MitM (przez ARP poison, malicious admin) jest powszechny. mTLS for internal API.
- **Self-signed cert "for staging"**: developers ignorują warnings → habit of accepting self-signed → real MitM passed.
- **Certificate pinning broken on update**: aplikacja mobile/desktop z pinned cert może przestać działać po renew → developers wyłączają pinning całkowicie.

### Świeżynki z research

- **TLS 1.3 0-RTT replay** (PortSwigger Research community) — patterns ataków.
- **Mozilla SSL Configuration Generator**: https://ssl-config.mozilla.org/ — gold standard configs.
- **CRYPTOREC, NIST PQC** — przyszłe post-quantum cryptography standards.
- **HackTricks Pentesting TLS**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| TLS-Attacker | Active TLS testing extension | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/09-Testing_for_Weak_Cryptography/01-Testing_for_Weak_Transport_Layer_Security
- OWASP TLS Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html
- OWASP TLS Cipher String CS: https://cheatsheetseries.owasp.org/cheatsheets/TLS_Cipher_String_Cheat_Sheet.html
- Mozilla SSL Config Generator: https://ssl-config.mozilla.org/
- testssl.sh: https://testssl.sh/
- sslyze: https://github.com/nabla-c0d3/sslyze
- SSL Labs: https://www.ssllabs.com/ssltest/
- CryptCheck: https://tls.imirhil.fr/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V9.1.1 | Communications (L1) | TLS used for all client connectivity. |
| V9.1.2 | Communications (L1) | Secure TLS configurations. |
| V9.1.3 | Communications (L1) | Only the latest TLS protocol versions enabled. |
| V9.2.2 | Communications (L2) | Encrypted communications (e.g. TLS) used for all inbound and outbound connections. |
