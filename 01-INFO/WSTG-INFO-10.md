# WSTG-INFO-10 — Map Application Architecture

## Cele

- Understand architecture and technologies in use
- Identify web servers, application servers, databases, load balancers, WAF, CDN
- Map network topology and infrastructure components

## KOMENDY

### WAF Detection - wafw00f

```bash
wafw00f https://TARGET | tee output_wafw00f.txt
wafw00f https://TARGET -a | tee output_wafw00f_all.txt

```

### Nmap - pelne skanowanie

```bash
nmap -sV -sC -p- TARGET -oN output_nmap_full.txt
nmap -sV -sC -A TARGET -oN output_nmap_aggressive.txt
nmap -sV --script "banner,http-headers,http-server-header" -p 80,443 TARGET -oN output_nmap_banners.txt

```

### Traceroute - mapowanie trasy

```bash
traceroute TARGET | tee output_traceroute.txt
mtr TARGET -r -c 10 | tee output_mtr.txt

```

### DNS - mapowanie infrastruktury

```bash
dig TARGET ANY +noall +answer | tee output_dig_any.txt
dig TARGET A +noall +answer
dig TARGET AAAA +noall +answer
dig TARGET MX +noall +answer
dig TARGET NS +noall +answer
dig TARGET TXT +noall +answer
dig TARGET SOA +noall +answer
dig TARGET CNAME +noall +answer

```

### Host

```bash
host TARGET | tee output_host.txt
host -t any TARGET

```

### Whois

```bash
whois TARGET | tee output_whois.txt

```

### Load Balancer Detection

```bash
lbd TARGET | tee output_lbd.txt
halberd TARGET | tee output_halberd.txt

```

### Sprawdzenie CDN

```bash
curl -sI https://TARGET | grep -iE "^(Server|Via|X-Cache|X-CDN|CF-Ray|X-Amz-Cf|X-Served-By|X-Cache-Hits|X-Fastly):" | tee output_cdn_headers.txt

```

### Sprawdzenie reverse proxy

```bash
curl -sI https://TARGET | grep -iE "^(Via|X-Forwarded|X-Real-IP|X-Proxy):" | tee output_proxy_headers.txt

```

### Sprawdzenie wielu IP (round-robin DNS)

```bash
for i in $(seq 1 10); do dig +short TARGET; done | sort | uniq -c | sort -rn | tee output_dns_roundrobin.txt

```

### SSL/TLS analiza

```bash
sslyze TARGET | tee output_sslyze.txt
testssl.sh TARGET | tee output_testssl.txt
openssl s_client -connect TARGET:443 2>/dev/null | openssl x509 -noout -text | tee output_ssl_cert.txt

```

### ASN lookup

```bash
whois -h whois.radb.net -- "-i origin $(whois TARGET | grep -i origin | awk '{print $NF}')" | tee output_asn.txt

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - ten test polega na identyfikacji architektury
# za pomoca narzedzi sieciowych i analizy naglowkow

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Przeanalizuj naglowki HTTP w DevTools - zidentyfikuj serwer, proxy, CDN
2. Sprawdz czy istnieje load balancer (rozne odpowiedzi na te same zapytania)
3. Sprawdz certyfikat SSL - kto go wystawil, dla jakich domen
4. Zidentyfikuj WAF - wyslij zlosliwe zapytanie i sprawdz odpowiedz
5. Narysuj diagram architektury: klient > CDN > WAF > LB > serwer > DB
6. Sprawdz rozne porty i uslugi na TARGET (FTP, SSH, SMTP, itp.)
7. Uzyj Shodan/Censys do identyfikacji uslug na danym IP
8. Przeanalizuj DNS records - czy wskazuja na chmure (AWS, Azure, GCP)
9. Sprawdz headery Set-Cookie - flagi Secure, HttpOnly, SameSite
10. Zidentyfikuj backend database na podstawie bledow lub naglowkow

