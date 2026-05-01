# WSTG-CRYP-03 — Testing for Sensitive Information Sent via Unencrypted Channels

## Cel

Weryfikacja że wrażliwe dane (credentials, payment, PII, session tokens) NIE są przesyłane przez HTTP. Atakujący w MitM (Wi-Fi public, ARP poison, malicious ISP) może sniffować plaintext credentials.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-cryp-03-unencrypted-channels.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-cryp-03.jsonl
```

Szablon w jednym requeście z 7 matcherami: login form action HTTP, password field na HTTP page, credit card field na HTTP, HTTP API z sensitive data, Authorization Basic na HTTP, session cookie bez Secure flag, HTTP→HTTPS redirect missing.

### Cross-reference

```bash
# WSTG-CRYP-01 (TLS config) - mixed content overlap
nuclei -l burp-export.xml -im burp -t templates/wstg-cryp-01-tls-config.yaml

# WSTG-CONF-07 (HSTS) - HTTPS enforcement
nuclei -l burp-export.xml -im burp -t templates/wstg-conf-07-hsts.yaml

# WSTG-SESS-02 (Cookie attributes)
nuclei -l burp-export.xml -im burp -t templates/wstg-sess-02-cookie-attributes.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Login form action HTTP | ✓ | — |
| Password/CC field na HTTP page | ✓ | — |
| HTTP API z sensitive data w response | ✓ | — |
| Basic auth challenge na HTTP | ✓ | — |
| Session cookie bez Secure flag | ✓ | (cross WSTG-SESS-02) |
| HTTP→HTTPS redirect missing | ✓ | — |
| WebSocket cleartext (ws://) | — | manual / osobny test |
| Email/SMTP cleartext | — | poza zakresem WSTG-web |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Test obu portów**: HTTP (80) i HTTPS (443) per host. Niektóre target serwują równolegle.
2. **Form action audit**: każdy `<form action="...">` — czy zawsze HTTPS lub relative na HTTPS page.
3. **Cookie audit**: każdy Set-Cookie z session/auth/token w nazwie → musi mieć Secure + HttpOnly + SameSite.
4. **API endpoint test**: każdy `/api/*` na HTTP — czy akceptuje requests czy odrzuca z 426 Upgrade Required.
5. **Mixed content audit**: na HTTPS page — szukać `src="http://"`, `href="http://"` (cross-ref CRYP-01).

### Co MUSI być sprawdzone (10 punktów)

- [ ] Login page serwowany przez HTTPS (cert valid)
- [ ] Login form action używa HTTPS (nie HTTP, nie relative na HTTP page)
- [ ] Password fields tylko na HTTPS page
- [ ] Payment fields tylko na HTTPS page
- [ ] PII fields (SSN, PESEL) tylko na HTTPS
- [ ] Session cookie z Secure flag
- [ ] HTTP wszystkie endpointy redirectują 301 do HTTPS
- [ ] HTTPS-only API (HTTP zwraca 426 lub redirect)
- [ ] Basic auth tylko przez HTTPS (nigdy plaintext na HTTP)
- [ ] Brak mixed content na HTTPS (cross CRYP-01)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Transport_Layer_Security_Cheat_Sheet.md, HTTP_Strict_Transport_Security_Cheat_Sheet.md

### TLS na wszystkich stronach

- **HTTPS wszędzie** — nie tylko na login/checkout; strony HTTP mogą ujawnić session cookies
- Strony HTTP dają atakującemu możliwość: sniffowania tokenów sesji, wstrzykiwania JavaScript (MitM)
- **API endpoints**: wyłącz HTTP całkowicie — failuj requesty zamiast redirectować

### Redirect HTTP → HTTPS

- HTTP 301 (permanent redirect) na poziomie serwera
- UWAGA: sam redirect NIE chroni — pierwszy request idzie przez HTTP (możliwy MitM)
- Dlatego HSTS jest NIEZBĘDNY jako uzupełnienie redirectu

### HSTS (HTTP Strict Transport Security)

- `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload`
- `max-age` — czas w sekundach (31536000 = 1 rok) — przeglądarka pamięta że strona używa HTTPS
- `includeSubDomains` — HSTS dotyczy też wszystkich subdomen
- `preload` — dodanie do preload list w przeglądarkach (permanentne, trudne do cofnięcia)
- Bez HSTS: atakujący może użyć **sslstrip** do downgrade HTTPS→HTTP w sieci lokalnej

### Mixed Content

- NIE ładuj zasobów (JS, CSS, obrazki) przez HTTP na stronie HTTPS
- Nowoczesne przeglądarki blokują active mixed content (JS, CSS) — ale passive (obrazki) mogą być ładowane
- Sprawdź konsolę przeglądarki — ostrzeżenia o mixed content

### Cookie Security

- **Secure flag** na WSZYSTKICH cookies — przeglądarka nie wyśle ich przez HTTP
- Ważne nawet jeśli serwer nie słucha na porcie 80 — atakujący MitM może sproofować serwer HTTP
- Cookie bez Secure flag może być przechwycone w otwartej sieci Wi-Fi

### Cachowanie danych wrażliwych

- Ustaw na odpowiedziach z wrażliwymi danymi:
  - `Cache-Control: no-cache, no-store, must-revalidate`
  - `Pragma: no-cache`
  - `Expires: 0`
- TLS chroni dane w transporcie, ALE nie chroni po dotarciu do klienta — dane mogą być w cache przeglądarki

## Pentesterskie deep dive

### Mniej znane techniki

- **sslstrip2 / sslstrip+**: nowsza wersja sslstrip która handluje też HSTS przez Mapping zaufanych subdomen na atakera (nie blokuje wszystkich, tylko subset). Wciąż effective gdy HSTS preload missing.
- **HTTP-only intranet leaks credentials globally**: gdy klient deklaruje "intranet HTTP only", a użytkownicy logują się przez VPN z podzielnym tunelem → credentials sent po VPN, ale browser może auto-fill na external HTTP page też.
- **Mixed content via 3rd party plugin**: aplikacja sama HTTPS, ale 3rd party widget (chat, analytics) ładowany z HTTP → HTTPS page się zhackuje.
- **Wi-Fi captive portal HTTP**: nawet HTTPS-aware aplikacje mogą być przekierowane do HTTP captive portal — atakujący z fake captive portal przechwytuje credentials.
- **HTTP/2 mixed content edge cases**: HTTP/2 wymaga TLS, więc nie może być "HTTP/2 cleartext" w przeglądarce — ale niektóre legacy backendy używają h2c (HTTP/2 cleartext) za reverse proxy.

### Common pitfalls

- **Self-signed cert na staging → habit**: developers przyzwyczajają się do akceptowania self-signed → real MitM passed.
- **HSTS bez preload na new domain**: pierwszy request idzie przez HTTP (TOFU window) — vulnerable do sslstrip.
- **Cookie domain `.target.com` na subdomain z HTTP**: jeśli `cookies set on https://target.com` z domain `.target.com`, są wysyłane też do `http://staging.target.com` jeśli takie istnieje (without Secure flag).

### Świeżynki z research

- **HTTPS-only Mode w przeglądarkach** (Firefox, Chrome): nowy default — wszystkie requests upgradowane do HTTPS, fallback na HTTP wymaga user interaction.
- **HSTS supercookies attack** (legacy ale nadal istotne) — using HSTS state to track users.
- **Mozilla SSL Configuration Generator**: https://ssl-config.mozilla.org/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Detekcja insecure versions w transport | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/09-Testing_for_Weak_Cryptography/03-Testing_for_Sensitive_Information_Sent_via_Unencrypted_Channels
- OWASP TLS Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Transport_Layer_Security_Cheat_Sheet.html
- OWASP HSTS Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Strict_Transport_Security_Cheat_Sheet.html
- HSTS Preload List: https://hstspreload.org/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V9.1.1 | Communications (L1) | TLS for all client connectivity. |
| V8.2.2 | Sensitive Data (L1) | No sensitive data in browser localStorage/sessionStorage. |
| V13.4.7 | Information Leakage (L3) | Web tier serves only specific file extensions. |
