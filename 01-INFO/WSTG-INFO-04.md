# WSTG-INFO-04 — Attack Surface Identification (Enumerate Applications)

## Cele

- Enumerate apps, DNS names, subdomains, virtual hosts, certificate transparency
- Identify all web applications hosted on the target infrastructure
- Discover non-obvious entry points and hidden services

## KOMENDY

### Amass - enumeracja subdomen

```bash
amass enum -d TARGET -o output_amass.txt
amass enum -passive -d TARGET -o output_amass_passive.txt
amass enum -active -d TARGET -o output_amass_active.txt -brute

```

### Subfinder - szybka enumeracja subdomen

```bash
subfinder -d TARGET -o output_subfinder.txt
subfinder -d TARGET -all -o output_subfinder_all.txt

```

### Assetfinder - znajdowanie zasobow

```bash
assetfinder TARGET | tee output_assetfinder.txt
assetfinder --subs-only TARGET | tee output_assetfinder_subs.txt

```

### Certificate Transparency - crt.sh

```bash
curl -s "https://crt.sh/?q=%25.TARGET&output=json" | jq -r '.[].name_value' | sort -u | tee output_crtsh.txt

```

### DNSRecon - rekonesans DNS

```bash
dnsrecon -d TARGET -t std -o output_dnsrecon.txt
dnsrecon -d TARGET -t brt -D Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt -o output_dnsrecon_brute.txt
dnsrecon -d TARGET -t axfr -o output_dnsrecon_axfr.txt

```

### Gobuster DNS - brute-force subdomen

```bash
gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt -o output_gobuster_dns.txt
gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt -o output_gobuster_dns_20k.txt

```

### Gobuster VHOST - brute-force virtual hostow

```bash
gobuster vhost -u https://TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt -o output_gobuster_vhost.txt

```

### Nmap - skanowanie portow i uslug

```bash
nmap -sV -sC -p- TARGET -oN output_nmap_full.txt
nmap -sV -p 80,443,8080,8443,8000,8888,9090,3000,5000 TARGET -oN output_nmap_web.txt

```

### Dig - zapytania DNS

```bash
dig TARGET ANY +noall +answer
dig TARGET MX +noall +answer
dig TARGET NS +noall +answer
dig TARGET TXT +noall +answer
dig TARGET AXFR +noall +answer

```

### Host - rozwiazywanie DNS

```bash
host TARGET
host -t mx TARGET
host -t ns TARGET

```

### Sprawdzanie wielu portow na subdomenach

```bash
# Po zebraniu subdomen mozna je sprawdzic httpx
cat output_subfinder.txt | httpx -ports 80,443,8080,8443 -o output_httpx.txt

```

## KOMENDY Z WORDLISTAMI

### SecLists DNS wordlists

```bash
# Mala lista (5000 subdomen)
gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt -o output_dns_5k.txt

# Srednia lista (20000 subdomen)
gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt -o output_dns_20k.txt

# Duza lista (110000 subdomen)
gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-110000.txt -o output_dns_110k.txt

```

### ffuf VHOST discovery

```bash
ffuf -u https://TARGET -H "Host: FUZZ.TARGET" -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt -mc 200,301,302,403 -o output_ffuf_vhost.json

```

### DNSRecon brute z wordlista

```bash
dnsrecon -d TARGET -t brt -D Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt

```

### OneListForAll do content discovery na subdomenach

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/OneListForAll-main/onelistforallshort.txt -mc 200,301,302,403 -o output_ffuf_olfa.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz DNS records w narzedziu online (dnsdumpster.com, securitytrails.com)
2. Uzyj crt.sh (crt.sh/?q=%25.TARGET) do wyszukania certyfikatow SSL
3. Sprawdz rozne porty na TARGET w przegladarce (8080, 8443, 3000, itp.)
4. W Burp Suite: zmien naglowek Host na rozne subdomeny i obserwuj odpowiedzi
5. Sprawdz Shodan/Censys pod katem uslug i portow TARGET
6. Przejrzyj znalezione subdomeny - kazda moze hostowac inna aplikacje
7. Sprawdz czy subdomeny prowadza do roznych serwerow (rozne IP)
8. Zweryfikuj reverse DNS lookup na znalezionych adresach IP

