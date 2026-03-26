# WSTG-CONF-01 — Test Network Infrastructure Configuration

## Cele

- Review network config, validate frameworks are securely configured
- Identify unnecessary services, default configurations, and misconfigurations
- Assess server hardening and patch levels

## KOMENDY

### Nmap - skanowanie portow i uslug

```bash
nmap -sV -sC -p- TARGET -oN output_nmap_full.txt
nmap -sV --script vuln -p 80,443 TARGET -oN output_nmap_vuln.txt
nmap -sV --script "safe and vuln" TARGET -oN output_nmap_safe_vuln.txt
nmap -A -T4 TARGET -oN output_nmap_aggressive.txt

```

### Nmap NSE scripts - konfiguracja serwera

```bash
nmap --script http-methods -p 80,443 TARGET -oN output_nmap_methods.txt
nmap --script http-headers -p 80,443 TARGET -oN output_nmap_headers.txt
nmap --script ssl-enum-ciphers -p 443 TARGET -oN output_nmap_ssl_ciphers.txt
nmap --script ssl-cert -p 443 TARGET -oN output_nmap_ssl_cert.txt
nmap --script http-security-headers -p 80,443 TARGET -oN output_nmap_sec_headers.txt

```

### Nikto - skaner podatnosci webowych

```bash
nikto -h https://TARGET -o output_nikto.txt -Format txt
nikto -h https://TARGET -Tuning x -o output_nikto_all.txt

```

### SSLyze - analiza konfiguracji SSL/TLS

```bash
sslyze TARGET -o output_sslyze.txt
sslyze TARGET --regular | tee output_sslyze_regular.txt

```

### testssl.sh - kompleksowy test SSL

```bash
testssl.sh TARGET | tee output_testssl.txt
testssl.sh --vulnerable TARGET | tee output_testssl_vuln.txt

```

### Sprawdzenie domyslnych portow administracyjnych

```bash
nmap -sV -p 22,23,25,53,110,143,3306,5432,6379,27017,8080,8443,9090,9200 TARGET -oN output_nmap_admin_ports.txt

```

### Sprawdzenie SNMPv1/v2

```bash
nmap -sU -p 161 --script snmp-info TARGET -oN output_nmap_snmp.txt

```

### Sprawdzenie wersji protokolu SSH

```bash
nmap --script ssh2-enum-algos -p 22 TARGET -oN output_nmap_ssh_algos.txt

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - ten test opiera sie na skanerach
# Nmap, Nikto, SSLyze uzywaja wbudowanych baz podatnosci i sygnatur

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz czy niepotrzebne porty sa otwarte (FTP, Telnet, SNMP)
2. Zweryfikuj konfiguracje SSL/TLS - czy uzywane sa silne szyfry
3. Sprawdz czy serwer udostepnia informacje o wersji w naglowkach
4. Zweryfikuj czy domyslne strony serwera zostaly usuniete
5. Sprawdz czy dostep do paneli administracyjnych jest ograniczony
6. Przeanalizuj konfiguracje CORS i HSTS
7. Sprawdz czy serwer obsluguje stare wersje protokolow (SSLv3, TLS 1.0)
8. Zweryfikuj separacje srodowisk (dev/staging/prod)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Docker_Security_Cheat_Sheet.md

### Hardening infrastruktury sieciowej

- **Minimalizuj otwarte porty**: uruchamiaj TYLKO wymagane uslugi — zamknij wszystko inne
- **Segmentacja sieci**: izoluj baze danych, backend, admin panel od publicznego internetu
- **Firewall rules**: default deny — jawnie zezwalaj tylko na potrzebny ruch
- **Patch management**: aktualizuj systemy operacyjne, serwery webowe, bazy danych regularnie
- Wylacz **domyslne konta/hasla** na wszystkich urzadzeniach sieciowych

### Konfiguracja serwera webowego

- Usun domyslne strony, sample applications, dokumentacje (Apache: /manual, IIS: /iisstart)
- Wylacz **directory listing** — nie ujawniaj struktury katalogow
- Wylacz **Server signature** — ukryj wersje serwera (Apache: `ServerTokens Prod`)
- Ogranicz metody HTTP do wymaganych (GET, POST) — zablokuj TRACE, DELETE, PUT
- Ustaw prawidlowe **file permissions** — www-data nie powinien miec zapisu poza upload dir

### Docker/kontenery — bezpieczenstwo

- Nie uruchamiaj kontenerow jako **root** — uzyj `USER` w Dockerfile
- Uzyj **read-only filesystem**: `--read-only` — zapobiegaj modyfikacjom
- Skanuj obrazy pod katem CVE: Trivy, Snyk, Grype
- Nie przechowuj sekretow w obrazie — uzyj Docker secrets / env at runtime
- Ogranicz zasoby: `--memory`, `--cpus` — zapobiegaj DoS

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Active Scan++ | Rozszerzony skaner z dodatkowymi checkami infrastruktury | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
| Collaborator Everywhere | Wykrywanie ukrytych backendowych systemow przez pingbacki | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V12.1.1 | General TLS Security Guidance | Verify that only the latest recommended versions of the TLS protocol are enabled, such as TLS 1.2 and TLS 1.3. The latest version of the TLS protocol must be the preferred option. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V12.1.2 | General TLS Security Guidance | Verify that only recommended cipher suites are enabled, with the strongest cipher suites set as preferred. L3 applications must only support cipher suites which provide forward secrecy. |
| V12.3.1 | General Service to Service Communication Security | Verify that an encrypted protocol such as TLS is used for all inbound and outbound connections to and from the application, including monitoring systems, management tools, remote access and SSH, middleware, databases, mainframes, partner systems, or external APIs. The server must not fall back to insecure or unencrypted protocols. |
| V13.2.1 | Backend Communication Configuration | Verify that communications between backend application components that don't support the application's standard user session mechanism, including APIs, middleware, and data layers, are authenticated. Authentication must use individual service accounts, short-term tokens, or certificate-based authentication and not unchanging credentials such as passwords, API keys, or shared accounts with privileged access. |
| V13.2.2 | Backend Communication Configuration | Verify that communications between backend application components, including local or operating system services, APIs, middleware, and data layers, are performed with accounts assigned the least necessary privileges. |
