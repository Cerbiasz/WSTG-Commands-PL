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

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Active Scan++ | Rozszerzony skaner z dodatkowymi checkami infrastruktury | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
| Collaborator Everywhere | Wykrywanie ukrytych backendowych systemow przez pingbacki | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |
