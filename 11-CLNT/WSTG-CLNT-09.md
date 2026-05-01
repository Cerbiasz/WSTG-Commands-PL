# WSTG-CLNT-09 — Testing for Clickjacking

## Cel

Sprawdzenie obrony przed clickjacking: aplikacja musi blokować embedowanie w iframe na obcych domenach (X-Frame-Options DENY/SAMEORIGIN lub CSP frame-ancestors). Bez ochrony atakujący embeduje target w evil.com i przejmuje user clicks.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-clnt-09-clickjacking.yaml
```

Wykrywa: brak X-Frame-Options + brak CSP frame-ancestors, ALLOWALL/wildcard, ALLOW-FROM (deprecated), frame-ancestors *.

### Cross-reference

```bash
# Pełen security headers audit
nuclei -l burp-export.xml -im burp -t templates/wstg-conf-14-security-headers.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| X-Frame-Options brak | ✓ | — |
| X-Frame-Options ALLOWALL/wildcard | ✓ | — |
| X-Frame-Options ALLOW-FROM (deprecated) | ✓ | — |
| CSP frame-ancestors brak / wildcard | ✓ | — |
| Per-endpoint inconsistency | częściowe | manual per page |
| JS frame-busting (soft protection) | — | manual review |
| SameSite cookie defense | — | cross WSTG-SESS-02 |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (4 kroki)

1. **Header audit**: GET na sensitive pages (login, settings, admin) — sprawdzić X-Frame-Options + CSP frame-ancestors.
2. **PoC creation**: stworzyć attacker HTML z `<iframe src="https://target.com/sensitive">` — czy się ładuje?
3. **JS frame-busting test**: jeśli JS frame-buster, próbować `sandbox="allow-scripts"` (no allow-top-navigation) → buster blocked.
4. **SameSite check**: cookies z SameSite=Lax/Strict ograniczają impact (cookies nie wysyłane w cross-site iframe).

### Co MUSI być sprawdzone (8 punktów)

- [ ] X-Frame-Options DENY/SAMEORIGIN obecny LUB
- [ ] CSP frame-ancestors 'none'/'self'
- [ ] Sensitive pages (login, transfer, admin) — header check
- [ ] Header consistency across all sensitive endpoints
- [ ] iframe PoC w external page
- [ ] SameSite cookie attribute
- [ ] CSP frame-src (per page restrictions)
- [ ] JS frame-busting (defense-in-depth)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Clickjacking_Defense_Cheat_Sheet.md

### Trzy niezależne mechanizmy obrony (defence in depth — implementuj WSZYSTKIE)

### 1. CSP frame-ancestors (REKOMENDOWANY — primary defense)

- `Content-Security-Policy: frame-ancestors 'none';` — blokuje framowanie przez KAŻDĄ domenę (ZALECANE)
- `Content-Security-Policy: frame-ancestors 'self';` — pozwala framowanie TYLKO z tej samej domeny
- `Content-Security-Policy: frame-ancestors 'self' *.trusted.com;` — pozwala framowanie z trusted.com
- CSP frame-ancestors MA PRIORYTET nad X-Frame-Options (wg specyfikacji CSP)
- Uwaga: starsze przeglądarki (Chrome 40, Firefox 35) mogą ignorować CSP i słuchać X-Frame-Options

### 2. X-Frame-Options (kompatybilność wsteczna)

- `X-Frame-Options: DENY` — blokuje framowanie (ZALECANE jeśli nie potrzebujesz framowania)
- `X-Frame-Options: SAMEORIGIN` — pozwala framowanie z tej samej domeny
- `ALLOW-FROM uri` — PRZESTARZAŁE, nie działa w nowoczesnych przeglądarkach — używaj CSP frame-ancestors zamiast
- Dodaj header do KAŻDEJ odpowiedzi z HTML — użyj filtra/middleware aby dodać automatycznie
- Częste błędy: nie ustawiaj na każdej stronie, podwójne wartości, brak w proxy/CDN

### 3. SameSite Cookie Attribute

- `SameSite=Strict` lub `SameSite=Lax` na session cookies
- Zapobiega dołączaniu cookies sesji gdy strona jest ładowana w iframe z innej domeny
- Skutecznie ogranicza impact clickjacking nawet jeśli framing jest możliwy

### Framebusting JavaScript (fallback — NIE jako jedyna obrona)

- JavaScript frame-buster może być obejście — atakujący może użyć `sandbox` attribute na iframe
- Przykład frame-buster: `if (top !== self) { top.location = self.location; }`
- Ograniczenia: może być zablokowany przez `sandbox="allow-scripts"` bez `allow-top-navigation`
- Traktuj jako dodatkową warstwę, nie primary defense

### Uwagi dot. implementacji

- Ustaw headery na poziomie Web Application Firewall / Web Server / Application dla konsystencji
- Sprawdź czy reverse proxy/CDN nie usuwa headerów bezpieczeństwa
- Testuj w różnych przeglądarkach — wsparcie może się różnić

## Pentesterskie deep dive

### Mniej znane techniki

- **Drag-and-Drop attack**: nawet z X-Frame-Options, ataker może użyć `draggable` elements z prefilled values → user dragnie credentials z iframe (rzadko ale historyczne).
- **Cursor-jacking**: CSS cursor manipulation - changing cursor position display, user clicks elsewhere than thinks.
- **UI redress via mouse hijacking**: showing fake UI overlay nawet bez iframe - using opacity/positioning.
- **iframe sandbox bypass for frame-buster**: `<iframe src="target" sandbox="allow-scripts">` blocks `top.location = self.location`.
- **HTTP/3 + HTTP/2 framing differences**: cross-protocol could occasionally bypass headers, edge case.

### Common pitfalls

- **Per-page X-Frame-Options inconsistent**: aplikacja ma DENY na większości pages ale `/embed/widget` ma ALLOWALL → atakujący wykorzystuje.
- **CSP frame-ancestors obowiązuje TYLKO gdy CSP enforced**: Report-Only nie blokuje.
- **Reverse proxy strip headers**: CDN może usunąć security headers - test direct backend.

### Świeżynki z research

- **PortSwigger Clickjacking lab**: https://portswigger.net/web-security/clickjacking
- **HackTricks Clickjacking**: https://book.hacktricks.xyz/pentesting-web/clickjacking

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Clickjacker | PoC generator | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/09-Testing_for_Clickjacking
- OWASP Clickjacking CS: https://cheatsheetseries.owasp.org/cheatsheets/Clickjacking_Defense_Cheat_Sheet.html
- PortSwigger Clickjacking: https://portswigger.net/web-security/clickjacking

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.4 | Configuration (L2) | All responses contain CSP header. |
| V14.4.6 | Configuration (L1) | X-Frame-Options or CSP frame-ancestors set. |
