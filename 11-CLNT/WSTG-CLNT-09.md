# WSTG-CLNT-09 — Testing for Clickjacking

## Cele

- Assess application vulnerability to clickjacking attacks

## KOMENDY

### Sprawdzenie headerow ochronnych

```bash
curl -sI "https://TARGET/" | grep -i "x-frame-options\|content-security-policy"

```

### Test iframe embedding

```bash
# Stworz plik PoC:
# <html><body><iframe src="https://TARGET/sensitive-action" width="500" height="500"></iframe></body></html>

```

### Sprawdzenie CSP frame-ancestors

```bash
curl -sI "https://TARGET/" | grep -i "frame-ancestors"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Clickjacking

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Clickjacking/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz X-Frame-Options header (DENY, SAMEORIGIN)
2. Sprawdz CSP frame-ancestors directive
3. Stworz PoC HTML z iframe TARGET
4. Testuj czy krytyczne akcje (zmiana hasla, przelew) mozna osadzic w iframe
5. Sprawdz czy JavaScript frame-busting jest uzywany (i czy mozna go ominac)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Clickjacking_Defense_Cheat_Sheet.md

### Trzy niezalezne mechanizmy obrony (defence in depth — implementuj WSZYSTKIE)

### 1. CSP frame-ancestors (REKOMENDOWANY — primary defense)

- `Content-Security-Policy: frame-ancestors 'none';` — blokuje framowanie przez KAZDA domene (ZALECANE)
- `Content-Security-Policy: frame-ancestors 'self';` — pozwala framowanie TYLKO z tej samej domeny
- `Content-Security-Policy: frame-ancestors 'self' *.trusted.com;` — pozwala framowanie z trusted.com
- CSP frame-ancestors MA PRIORYTET nad X-Frame-Options (wg specyfikacji CSP)
- Uwaga: starsze przegladarki (Chrome 40, Firefox 35) moga ignorowac CSP i sluchac X-Frame-Options

### 2. X-Frame-Options (kompatybilnosc wsteczna)

- `X-Frame-Options: DENY` — blokuje framowanie (ZALECANE jesli nie potrzebujesz framowania)
- `X-Frame-Options: SAMEORIGIN` — pozwala framowanie z tej samej domeny
- `ALLOW-FROM uri` — PRZESTARZALE, nie dziala w nowoczesnych przegladarkach — uzywaj CSP frame-ancestors zamiast
- Dodaj header do KAZDEJ odpowiedzi z HTML — uzyj filtra/middleware aby dodac automatycznie
- Czeste bledy: nie ustawiaj na kazdej stronie, podwójne wartosci, brak w proxy/CDN

### 3. SameSite Cookie Attribute

- `SameSite=Strict` lub `SameSite=Lax` na session cookies
- Zapobiega dolaczaniu cookies sesji gdy strona jest ladowana w iframe z innej domeny
- Skutecznie ogranicza impact clickjacking nawet jesli framing jest mozliwy

### Framebusting JavaScript (fallback — NIE jako jedyna obrona)

- JavaScript frame-buster moze byc obejscie — atakujacy moze uzyc `sandbox` attribute na iframe
- Przyklad frame-buster: `if (top !== self) { top.location = self.location; }`
- Ograniczenia: moze byc zablokowany przez `sandbox="allow-scripts"` bez `allow-top-navigation`
- Traktuj jako dodatkowa warstwe, nie primary defense

### Uwagi dot. implementacji

- Ustaw headery na poziomie Web Application Firewall / Web Server / Application dla konsystencji
- Sprawdz czy reverse proxy/CDN nie usuwa headerow bezpieczenstwa
- Testuj w roznych przegladarkach — wsparcie moze sie roznic

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.4.6 | Browser Security Mechanism Headers | Verify that the web application uses the frame-ancestors directive of the Content-Security-Policy header field for every HTTP response to ensure that it cannot be embedded by default and that embedding of specific resources is allowed only when necessary. Note that the X-Frame-Options header field, although supported by browsers, is obsolete and may not be relied upon. |
