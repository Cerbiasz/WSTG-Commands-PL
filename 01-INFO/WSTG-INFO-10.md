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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Docker_Security_Cheat_Sheet.md

### Komponenty architektury — identyfikacja

| Komponent | Jak wykryc | Naglowki/sygnatury |
|-----------|-----------|-------------------|
| CDN | Naglowki `CF-Ray`, `X-CDN`, `X-Cache`, `X-Served-By` | Cloudflare, Akamai, Fastly, CloudFront |
| WAF | Strony blokowania, naglowki, wafw00f | ModSecurity, Cloudflare, AWS WAF, Imperva |
| Load Balancer | Rozne odpowiedzi, naglowek `Via`, cookie `BIGipServer` | F5, HAProxy, Nginx, AWS ALB |
| Reverse Proxy | Naglowki `Via`, `X-Forwarded-For`, rozne Server headers | Nginx, Apache, Envoy, Traefik |
| Cache | `X-Cache: HIT/MISS`, `Age`, `X-Varnish` | Varnish, Redis, Memcached |
| Database | Bledy SQL, naglowki specyficzne | MySQL, PostgreSQL, MongoDB, MSSQL |

### CDN — identyfikacja per provider

| CDN | Sygnatury |
|-----|-----------|
| Cloudflare | Naglowek `CF-Ray`, `Server: cloudflare`, cookie `__cfduid` |
| Akamai | Naglowek `X-Akamai-Transformed`, cookie `AkamaiGHP` |
| AWS CloudFront | Naglowek `X-Amz-Cf-Id`, `X-Amz-Cf-Pop`, `Via: ... CloudFront` |
| Fastly | Naglowek `X-Served-By`, `X-Cache`, `Fastly-Debug-Digest` |
| Azure CDN | Naglowek `X-Azure-Ref`, `X-MSEdge-Ref` |

### WAF detection — wskazówki

- Wyslij zlosliwe zapytanie (np. `?id=1' OR 1=1--`) i sprawdz odpowiedz
- WAF zwykle zwraca: 403, custom error page, lub modyfikuje request
- `wafw00f` automatycznie identyfikuje > 100 typow WAF
- Naglowki WAF: `X-WAF-Event`, `X-Protected-By`, `X-CDN-Forward`
- WAF bypass: nie oznacza ze aplikacja jest bezpieczna — WAF to dodatkowa warstwa

### Architektura typowa — warstwy

```
Klient → CDN → WAF → Load Balancer → Reverse Proxy → App Server → Database
                                                    → Cache (Redis/Memcached)
                                                    → Message Queue
                                                    → External APIs
```

### Mapowanie architektury — checklist

1. **Frontend**: CDN, statyczne zasoby, SPA framework
2. **Warstwa bezpieczenstwa**: WAF, rate limiting, DDoS protection
3. **Load balancing**: round-robin, sticky sessions, health checks
4. **Application tier**: web server, app server, konteneryzacja (Docker/K8s)
5. **Data tier**: baza danych (relacyjna/NoSQL), cache, storage
6. **Zewnetrzne uslugi**: payment gateway, email, SMS, OAuth providers
7. **Infrastruktura**: on-premise vs cloud (AWS/Azure/GCP), regiony

### Obrona

- Minimalizuj informacje ujawniane w naglowkach HTTP
- Konfiguruj CDN/WAF aby nie ujawnialy backend IP
- Uzyj osobnych sieci dla roznych warstw (DMZ, backend, database)
- Monitoruj kazda warstwe osobno — logi, metryki, alerty
- Dokumentuj architekture i aktualizuj diagram przy zmianach

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Collaborator Everywhere | Wstrzykiwanie naglowkow do wykrywania backendowych systemow | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |
| Reverse Proxy Detector | Wykrywanie serwerow reverse proxy | [BApp Store](https://portswigger.net/bappstore/a112997070354d249b64b4cf68eabc04) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.1.1 | Configuration Documentation | Verify that all communication needs for the application are documented. This must include external services which the application relies upon and cases where an end user might be able to provide an external location to which the application will then connect. |
| V12.3.1 | General Service to Service Communication Security | Verify that an encrypted protocol such as TLS is used for all inbound and outbound connections to and from the application, including monitoring systems, management tools, remote access and SSH, middleware, databases, mainframes, partner systems, or external APIs. The server must not fall back to insecure or unencrypted protocols. |
