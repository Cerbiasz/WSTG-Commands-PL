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

