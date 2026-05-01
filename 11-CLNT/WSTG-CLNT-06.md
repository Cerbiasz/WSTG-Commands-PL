# WSTG-CLNT-06 — Testing for Client-side Resource Manipulation

## Cel

Wykrycie miejsc gdzie atakujący kontroluje URL zasobu ładowanego przez stronę (`<script src=X>`, `<link href=X>`, `<form action=X>`, `<iframe src=X>`). Pivot do XSS (controlled JS), data exfil (controlled CSS), phishing (controlled form action).

> **Test mostly manual**: cross-ref WSTG-CLNT-01 (DOM XSS markers), WSTG-CLNT-04 (URL redirect).

## Automatyzacja Nuclei

```bash
# DOM XSS markers - obejmuje resource manipulation patterns
nuclei -l burp-export.xml -im burp -t templates/wstg-clnt-01-dom-xss.yaml

# URL redirect - obejmuje user-controlled URLs
nuclei -l burp-export.xml -im burp -t templates/wstg-clnt-04-url-redirect.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Source enumeration**: szukać `script.src = userInput`, `link.href = ...`, `iframe.src = ...` w JS bundle.
2. **Server-side reflection**: `<script src="/api/dynamic.js?lang={{userLang}}">` — czy `lang` controlled?
3. **CSP audit**: jeśli CSP `script-src *.target.com` + atakujący kontroluje subdomain → bypass.
4. **SRI verification**: zewnętrzne `<script src="cdn">` powinny mieć `integrity=` attribute.
5. **PoC**: stworzyć attacker URL serwujący JS → submit input → check JS execution.

### Co MUSI być sprawdzone (8 punktów)

- [ ] `<script src="...">` z user-controlled URL?
- [ ] `<link href="...">` (CSS)
- [ ] `<iframe src="...">`
- [ ] `<form action="...">`
- [ ] `<object data="...">`, `<embed src="...">`
- [ ] `<img src="...">` (mniej krytyczne ale tracking)
- [ ] SRI (integrity attribute) na zewnętrznych zasobach
- [ ] CSP `script-src` / `style-src` rules

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — DOM_based_XSS_Prevention_Cheat_Sheet.md

### Client-side Resource Manipulation — mechanizm

- Atakujący kontroluje **URL zasobu** ładowanego przez stronę (src, href, action, data)
- Skutek: ładowanie złośliwego skryptu, CSS, obrazka, formularza z kontrolowanego serwera
- Różnica vs XSS: nie wstrzykuje kodu, ale **zmienia źródło** zasobu

### Niebezpieczne atrybuty/sinki

| Atrybut/Sink | Ryzyko |
|-------------|--------|
| `<script src=X>` | Ładowanie złośliwego JS — pełne RCE w kontekście strony |
| `<link href=X>` | Ładowanie złośliwego CSS — exfiltracja danych, UI redress |
| `<img src=X>` | Tracking pixel, SSRF (jeśli server-side fetch) |
| `<iframe src=X>` | Ładowanie strony atakującego — phishing |
| `<form action=X>` | Przekierowanie formularza na serwer atakującego — credential theft |
| `<object data=X>` | Ładowanie złośliwego contentu |

### Obrona

- **Nigdy** nie używaj danych użytkownika bezpośrednio w atrybutach src/href/action
- Waliduj URL-e: allowlist dozwolonych domen, sprawdź schemat (https://)
- Użyj **CSP**: `script-src 'self'`, `style-src 'self'` — blokuj zewnętrzne zasoby
- **Subresource Integrity (SRI)**: `integrity="sha384-..."` na `<script>` i `<link>` — weryfikuj hash zasobu
- Sanityzuj URL-e: odrzucaj `javascript:`, `data:`, `blob:` schematy

## Pentesterskie deep dive

### Mniej znane techniki

- **CDN takeover via SRI mismatch**: jeśli CDN serwuje plik bez expected integrity hash, plik się nie ładuje. Ale aplikacje często aktualizują CDN bez updating SRI — broken site OR drop SRI = security regression.
- **Service Worker resource manipulation**: SW może intercept fetch i zwracać attacker content. XSS → register malicious SW for persistence.
- **HTTP/2 server push z attacker-controlled resource**: rzadkie, ale push może override expected resource z attacker-controlled.
- **DNS prefetch + speculative loading**: `<link rel="dns-prefetch">` z user input → DNS leak, czasami fetch.

### Common pitfalls

- **`integrity=` not on dynamic resources**: aplikacje mają SRI na main bundle ale nie na dynamic chunks → race condition exploit.
- **CSP `script-src *.target.com` + subdomain takeover**: pełen bypass.

### Świeżynki z research

- **HackTricks Resource Manipulation**: https://book.hacktricks.xyz/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Reflector | User input reflection w resource attributes | [GitHub](https://github.com/elkokc/reflector) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/06-Testing_for_Client-side_Resource_Manipulation
- OWASP DOM XSS Prevention CS: https://cheatsheetseries.owasp.org/cheatsheets/DOM_based_XSS_Prevention_Cheat_Sheet.html
- W3C Subresource Integrity: https://www.w3.org/TR/SRI/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.2.4 | Dependency (L2) | Subresource Integrity (SRI) used for third-party JS. |
| V14.4.3 | Configuration (L1) | CSP set deny by default. |
