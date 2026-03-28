# WSTG-CONF-12 — Testing for Content Security Policy

## Cele

- Review CSP header for misconfigurations
- Identify bypasses in Content Security Policy
- Assess effectiveness of CSP against XSS and data injection attacks

## KOMENDY

### cURL - pobranie naglowka CSP

```bash
curl -sI https://TARGET | grep -i "Content-Security-Policy" | tee output_csp.txt
curl -sI https://TARGET | grep -i "Content-Security-Policy-Report-Only" | tee output_csp_report_only.txt

```

### Analiza CSP z roznych stron

```bash
curl -sI https://TARGET/ | grep -i "Content-Security-Policy"
curl -sI https://TARGET/login | grep -i "Content-Security-Policy"
curl -sI https://TARGET/api/ | grep -i "Content-Security-Policy"

```

### Sprawdzenie CSP META tag

```bash
curl -s https://TARGET | grep -iE 'meta.*content-security-policy' | tee output_csp_meta.txt

```

### Nmap - naglowki bezpieczenstwa

```bash
nmap --script http-security-headers -p 80,443 TARGET -oN output_nmap_sec_headers.txt

```

### Nuclei - szablony CSP

```bash
nuclei -u https://TARGET -tags csp -o output_nuclei_csp.txt
nuclei -u https://TARGET -tags security-headers -o output_nuclei_headers.txt

```

### Sprawdzenie typowych bledow CSP

```bash
# NIEBEZPIECZNE dyrektywy:
# - unsafe-inline (pozwala na inline script/style)
# - unsafe-eval (pozwala na eval())
# - * (wildcard - pozwala na wszystko)
# - data: w script-src (pozwala na data: URI jako script)
# - brak default-src (brak fallback policy)

```

### Testowanie CSP bypass z znanych CDN

```bash
# Jesli CSP pozwala na *.googleapis.com, *.cloudflare.com, *.jsdelivr.net
# mozna hostowac zlosliwy JS na tych domenach

```

### shcheck - sprawdzenie naglowkow bezpieczenstwa

```bash
shcheck https://TARGET | tee output_shcheck.txt

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - test polega na analizie naglowka CSP
# Uzyj narzedzi online: https://csp-evaluator.withgoogle.com/

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz naglowek CSP w DevTools > Network > Response Headers
2. Uzyj CSP Evaluator (csp-evaluator.withgoogle.com) do analizy polityki
3. Szukaj unsafe-inline, unsafe-eval, wildcard (*), data: w script-src
4. Sprawdz czy CSP jest ustawiony na wszystkich stronach czy tylko na niektorych
5. Przetestuj bypass CSP: czy dozwolone domeny hostuja kontrolowany content
6. Sprawdz czy jest Report-Only zamiast enforcing
7. Zweryfikuj czy CSP blokuje inline scripts i eval()
8. Przetestuj XSS payload - czy CSP go blokuje
9. Sprawdz czy base-uri jest ustawiony (ochrona przed base tag injection)
10. Zweryfikuj czy frame-ancestors jest ustawiony (ochrona przed clickjacking)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Content_Security_Policy_Cheat_Sheet.md

### Strict CSP — rekomendowane podejscie

- **Nonce-based**: `script-src 'nonce-{random}'` — losowy nonce per request, TYLKO skrypty z tym nonce sa wykonywane
- **Hash-based**: `script-src 'sha256-{hash}'` — TYLKO skrypty z dokladnym hashem sa wykonywane
- Nonce/hash approach jest SILNIEJSZY niz allowlist domen — eliminuje wiele bypass technik

### Niebezpieczne dyrektywy (UNIKAJ)

- `unsafe-inline` — pozwala na inline `<script>` i `on*` event handlers — czyni XSS mozliwym
- `unsafe-eval` — pozwala na `eval()`, `Function()`, `setTimeout(string)` — otwiera droge do code injection
- `*` (wildcard) — pozwala na ladowanie z dowolnej domeny — praktycznie brak ochrony
- `data:` w `script-src` — pozwala na `<script src="data:text/javascript,alert(1)">`
- Domeny CDN (`*.googleapis.com`, `*.cloudflare.com`) — atakujacy moze hostowac JS na tych CDN

### Kluczowe dyrektywy CSP

- `default-src 'none'` — deny by default, potem allowlist per typ
- `script-src 'nonce-{random}'` — inline skrypty tylko z nonce
- `style-src 'self'` — CSS tylko z tej samej domeny
- `img-src 'self' data:` — obrazy z tej samej domeny + data URI
- `frame-ancestors 'none'` — blokuje iframe embedding (zastepuje X-Frame-Options)
- `base-uri 'self'` — zapobiega base tag injection
- `form-action 'self'` — formularze moga byc wysylane tylko na te sama domene
- `object-src 'none'` — blokuje Flash, Java, inne pluginy

### Wdrozenie CSP

- **Krok 1**: `Content-Security-Policy-Report-Only` — testuj bez blokowania
- **Krok 2**: Monitoruj raporty (`report-uri /csp-report`) — identyfikuj co by bylo zablokowane
- **Krok 3**: Napraw naruszenia (usun inline scripts, uzyj nonce)
- **Krok 4**: Wlacz enforcing: `Content-Security-Policy` (bez Report-Only)
- Ustaw CSP na WSZYSTKICH stronach — nie tylko na wybranych

### CSP Bypass — co testowac

- Czy dozwolone domeny hostuja kontrolowany content (CDN, cloud storage)
- Czy `unsafe-inline` lub `unsafe-eval` sa wlaczone
- Czy brak `base-uri` (base tag injection)
- Czy brak `frame-ancestors` (clickjacking)
- Czy CSP jest Report-Only zamiast enforcing

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| CSP Bypass | Wykrywanie slabosci w konfiguracji Content-Security-Policy | [GitHub](https://github.com/moloch--/CSP-Bypass) |
| CSP Auditor | Analiza i audyt naglowkow CSP | [GitHub](https://github.com/GoSecure/csp-auditor) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.4.3 | Browser Security Mechanism Headers | Verify that HTTP responses include a Content-Security-Policy response header field which defines directives to ensure the browser only loads and executes trusted content or resources, in order to limit execution of malicious JavaScript. As a minimum, a global policy must be used which includes the directives object-src 'none' and base-uri 'none' and defines either an allowlist or uses nonces or hashes. For an L3 application, a per-response policy with nonces or hashes must be defined. |
| V3.4.6 | Browser Security Mechanism Headers | Verify that the web application uses the frame-ancestors directive of the Content-Security-Policy header field for every HTTP response to ensure that it cannot be embedded by default and that embedding of specific resources is allowed only when necessary. Note that the X-Frame-Options header field, although supported by browsers, is obsolete and may not be relied upon. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.4.7 | Browser Security Mechanism Headers | Verify that the Content-Security-Policy header field specifies a location to report violations. |


---

## HackTricks Tips

### CSP Bypass

- **`unsafe-inline`**: dowolny `<script>alert(1)</script>` działa
- **`unsafe-eval` + CDN**: load Angular 1.x z `cdnjs.cloudflare.com` → `{{$eval.constructor('alert(1)')()}}`
- **JSONP na allowed domains**: `<script src="https://www.google.com/complete/search?callback=alert#1">`
- **Open redirect w whitelisted domain**: `https://www.google.com/amp/s/attacker.com/evil.js`
- **Third-party abuse**: `*.amazonaws.com`, `*.azurewebsites.net`, `*.firebaseapp.com`, `cdn.jsdelivr.net` → register resource
- **Nonce reuse**: `document.querySelector("[nonce]").nonce` → inject `<script>` z tym nonce
- **`strict-dynamic`**: trusted script inject nowy `<script>` → ten też jest trusted
- **RPO**: `https://example.com/scripts/react/..%2fangular%2fangular.js`
- **File upload + `'self'`**: upload `.wave` z JS content → include jako `<script src="/uploads/file.wave">`
- **`form-action` bypass**: `default-src` nie pokrywa `form-action` → inject form na attacker server
- **`Content-Security-Policy-Report-Only`**: ten header NIE blokuje — CSP not enforced

### CSP via iframe

- `sandbox="allow-scripts allow-same-origin"` to NOT security boundary — iframe może usunąć own sandbox
- **Nonce theft z same-origin iframe**: `top.document.querySelector('[nonce]').nonce`
- **`srcdoc` iframe**: same-origin z parent (relative URLs resolve do parent origin)
