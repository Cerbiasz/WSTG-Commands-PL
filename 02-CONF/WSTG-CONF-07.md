# WSTG-CONF-07 — Test HTTP Strict Transport Security

## Cel

Weryfikacja poprawnej konfiguracji HSTS — kluczowej obrony przed SSL stripping. HSTS bez `max-age >= 31536000`, bez `includeSubDomains` lub bez `preload` osłabia ochronę. Brak HSTS = atakujący w MitM może downgrade HTTPS → HTTP.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-07-hsts.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-07.jsonl
```

Szablon w jednym requeście z 5 matcherami: brak HSTS na HTTPS, max-age = 0, brak includeSubDomains, brak preload, oraz extractor zwracający faktyczne max-age value.

### Dodatkowe oficjalne szablony Nuclei

```bash
# HSTS misconfiguration
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/http-missing-security-headers.yaml \
       -t resources/nuclei-templates/http/misconfiguration/missing-strict-transport-security.yaml

# TLS-related (cross WSTG-CRYP)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/ssl/
```

### Manual checks

```bash
# Sprawdzenie HSTS preload list status
curl -s "https://hstspreload.org/api/v2/status?domain=target.com" | jq

# Test HTTP redirect do HTTPS
curl -sI http://target.com | grep -i Location
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| HSTS missing on HTTPS | ✓ | — |
| max-age < 31536000 | ✓ (extractor + warning) | numeric comparison delegowane do wrapper |
| includeSubDomains brak | ✓ | — |
| preload brak | ✓ informational | — |
| HSTS preload list status | — | manual via hstspreload.org |
| HTTP→HTTPS redirect (prerequisite) | — | osobny request, w wrapperze |
| Mixed content detection | — | osobny test (CONF-12 CSP cross-ref) |
| TLS configuration (versions, ciphers) | — | WSTG-CRYP-01 |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **GET HTTPS endpoint**: sprawdź HSTS header obecność i wartość.
2. **GET HTTP endpoint**: sprawdź czy redirect 301/302 do HTTPS (prerequisite HSTS).
3. **Subdomain test**: HSTS na `target.com` ale nie na `staging.target.com` — `includeSubDomains` brakuje lub nie ustawione na origin.
4. **Preload list verification**: `hstspreload.org` status check + wymagania (max-age >= 1y, includeSubDomains, preload).

### Co MUSI być sprawdzone (8 punktów)

- [ ] HSTS header obecny na HTTPS
- [ ] max-age >= 31536000 (1 rok)
- [ ] includeSubDomains obecne
- [ ] preload obecne (lub świadoma decyzja braku)
- [ ] HTTP redirect do HTTPS (`http://target.com` → 301 → `https://target.com`)
- [ ] HSTS NIE na HTTP response (browsery ignorują, ale to misconfig)
- [ ] Wszystkie subdomeny obsługują HTTPS (jeśli includeSubDomains)
- [ ] Status na hstspreload.org

### Per scenario — typowe problemy

| Wykryte | Ryzyko | Fix |
|---|---|---|
| HSTS missing | sslstrip MitM | `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload` |
| max-age=86400 (1 dzień) | TOFU window jeden dzień | Zwiększyć do 31536000 |
| Brak includeSubDomains | subdomeny vulnerable | Dodać directive |
| Brak preload + brak HTTP→HTTPS redirect | Pierwszy request bezbronny | Preload + redirect 301 |
| Mixed content (HTTPS strona ładuje HTTP resource) | Active mixed content blokowane | CSP `upgrade-insecure-requests` |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTTP_Strict_Transport_Security_Cheat_Sheet.md, Transport_Layer_Security_Cheat_Sheet.md

### HSTS — konfiguracja

- **max-age**: minimum `31536000` (1 rok) — krótszy jest niewystarczający
- **includeSubDomains**: chroń WSZYSTKIE subdomeny — nie tylko główną domenę
- **preload**: dodaj do preload list (hstspreload.org) — ochrona od pierwszego requestu
- Pełny nagłówek: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- HSTS musi być wysyłany TYLKO przez HTTPS — NIE przez HTTP

### Dlaczego HSTS jest kluczowy

- Bez HSTS: pierwszy request może iść przez HTTP → **sslstrip** atak
- Atakujący w MitM może przechwycić HTTP → proxy → nie przekieruj do HTTPS
- HSTS zmusza przeglądarkę do używania HTTPS **bezwarunkowo** po pierwszym użyciu
- **HSTS preload**: przeglądarka zna domenę PRZED pierwszym requestem — zero HTTP requestów

### Wymagania HSTS preload list

- `max-age` >= 31536000 (1 rok)
- `includeSubDomains` musi być obecne
- `preload` musi być obecne
- Serwer musi obsługiwać HTTPS na głównej domenie (nie tylko subdomenach)
- HTTP musi przekierowywać 301 do HTTPS
- Wszystkie subdomeny muszą obsługiwać HTTPS

### Mixed content — zagrożenie

- Strona HTTPS ładująca zasoby przez HTTP = **mixed content**
- Active mixed content (script, iframe) — blokowane przez przeglądarkę
- Passive mixed content (obrazy, audio) — ostrzeżenie, ale ładowane
- Sprawdź: `curl -s https://TARGET | grep -i "http://" | grep -v "https://"`
- CSP: `upgrade-insecure-requests` — automatycznie upgraduj HTTP do HTTPS

### TLS konfiguracja

- TLS 1.2+ (najlepiej TLS 1.3) — wyłącz TLS 1.0/1.1
- Wyłącz słabe cipher suites: RC4, DES, 3DES, NULL, EXPORT
- Preferuj AEAD: AES-GCM, ChaCha20-Poly1305 z ECDHE (PFS)
- Narzędzie: **Mozilla SSL Configuration Generator** — generuj prawidłową konfigurację

## Pentesterskie deep dive

### Mniej znane techniki

- **HSTS bypass via subdomain takeover + cookie flags**: jeśli HSTS bez includeSubDomains, atakujący na controlled subdomenie ustawia cookie z `Domain=target.com` (bez Secure flag) → cookie wyciekający przez HTTP.
- **Preload removal lifecycle**: HSTS preload jest hardcoded w przeglądarkach — nawet po zmianie konfiguracji na serwerze, preload list aktualizowana 6+ miesięcy. Real-world removal jest długi.
- **HSTS NEL (Network Error Logging) leak**: `Report-To` header w połączeniu z HSTS może ujawniać informacje o failed connections — testowanie connectivity z attacker monitoring.
- **HTTPS Everywhere extension**: Tor Browser i HTTPS-Everywhere wymuszają HTTPS niezależnie od HSTS — dla testowania użyj curl bez tych mitigations.

### Common pitfalls

- **HSTS na HTTP response — przeglądarka ignoruje**: nieprawidłowe ale niesignal — niektóre nieprawidłowe konfiguracje serwera wysyłają HSTS przez HTTP.
- **Nginx `add_header` issue**: `add_header` w `location` block override directives w `server` block. HSTS może być w server ale nadpisany przez location.
- **Cloudflare HSTS**: jeśli klient deklaruje "HSTS aktywny" ale tylko Cloudflare ustawia HSTS, backend bez HSTS — direct backend access dalej vulnerable.

### Świeżynki z research

- **HSTS supercookies** (legacy ale nadal istotne) — using HSTS to track users across sites.
- **TLS 1.3 0-RTT replay** — early data może obejść HSTS w specific scenarios.
- **PortSwigger Web Security Academy — Lab: Insecure HTTPS redirection**: https://portswigger.net/web-security
- **Mozilla SSL Configuration Generator**: https://ssl-config.mozilla.org/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Retire.js | TLS/security related JS lib detection | [GitHub](https://github.com/h3xstream/burp-retire-js) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/07-Test_HTTP_Strict_Transport_Security
- OWASP HSTS Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html
- HSTS Preload List: https://hstspreload.org/
- Mozilla SSL Config Generator: https://ssl-config.mozilla.org/
- RFC 6797 (HSTS): https://datatracker.ietf.org/doc/html/rfc6797

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.5 | Configuration (L1) | HSTS header used with sufficient max-age. |
| V9.1.1 | Communications (L1) | TLS used for all client connectivity. |
| V9.1.3 | Communications (L1) | Only the latest TLS protocol versions enabled. |
