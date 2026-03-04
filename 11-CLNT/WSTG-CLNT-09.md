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

