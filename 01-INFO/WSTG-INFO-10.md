# WSTG-INFO-10 — Map Application Architecture

## Cel

Mapowanie pełnej architektury: CDN, WAF, load balancer, reverse proxy, app server, database, cache, message queue, microservices, external APIs. Identyfikacja warstw pozwala kalibrować ataki — np. SSRF na backend wymaga ominięcia WAF na CDN.

> **Test manual-only**: kompleksowe mapowanie architektury wymaga korelacji wielu sygnałów (headers, timing, error pages, DNS) — automatyzacja Nuclei wykrywa pojedyncze warstwy ale nie buduje całościowego diagramu.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (8 kroków)

1. **CDN identification**: `CF-Ray`, `X-Akamai-Transformed`, `X-Cache`, `Via` headers + DNS resolution (różne IP per region = CDN).
2. **WAF identification**: `wafw00f https://target` + manual probing (`?id=1' OR 1=1--` → response 403/406 z markers).
3. **Load balancer detection**: cookie `BIGipServer*` (F5), różne odpowiedzi z różnych IP, sticky session cookies.
4. **Reverse proxy markers**: `Via`, `X-Forwarded-By`, `X-Real-IP`, `X-Forwarded-For` headers.
5. **App server identification**: per WSTG-INFO-02 — Server header + error pages.
6. **Database fingerprint**: błędy SQL z payloadem (per WSTG-INPV-05) + cookie names z framework hints.
7. **Cache layer detection**: `X-Cache`, `Age`, `X-Varnish`, `X-Cache-Hit`.
8. **External services pivot**: w aplikacji szukać `<form action="https://stripe.com/...">`, `<script src="googleanalytics">`, OAuth redirect URLs.

### Co MUSI być sprawdzone (12 punktów)

- [ ] CDN identification (provider + region)
- [ ] WAF identification (vendor + bypass strategies)
- [ ] Load balancer (typ + sticky session cookie)
- [ ] Reverse proxy (typ + chain via Via header)
- [ ] App server stack (z WSTG-INFO-02)
- [ ] Database type (z error pages lub cookie/header markers)
- [ ] Cache layer (Varnish, Redis, Memcached, CloudFront cache)
- [ ] Message queue indicators (RabbitMQ headers, SQS endpoints)
- [ ] External services (payment, email, OAuth, SMS, captcha)
- [ ] Cloud provider (AWS / Azure / GCP via metadata IPs, IAM patterns)
- [ ] Containerization (Kubernetes via `/healthz`, `/readyz`, `/metrics`)
- [ ] Microservice topology (różne `/api/v*/<service>` endpointy)

### Per architektura — typowe sygnały

| Architektura | Sygnał |
|---|---|
| Monolith on-prem | Single Server header, brak X-Forwarded, brak CDN |
| LAMP stack | Apache + PHP cookie + MySQL errors |
| MEAN stack | Express + Mongo errors + Node-specific |
| Spring monolith | JSESSIONID + Tomcat banner + actuator |
| K8s + microservices | `/healthz`, `/metrics`, multiple Server headers per `/api/v*/` |
| Serverless (AWS Lambda) | `X-Amz-Cf-Id`, `Apigw-Requestid`, cold start latency spikes |
| Serverless (Vercel/Netlify) | `X-Vercel-Cache`, `X-Nf-Request-Id` |
| JAMstack | CDN + serverless functions + headless CMS |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Docker_Security_Cheat_Sheet.md

### Komponenty architektury — identyfikacja

| Komponent | Jak wykryć | Nagłówki/sygnatury |
|-----------|-----------|-------------------|
| CDN | Nagłówki `CF-Ray`, `X-CDN`, `X-Cache`, `X-Served-By` | Cloudflare, Akamai, Fastly, CloudFront |
| WAF | Strony blokowania, nagłówki, wafw00f | ModSecurity, Cloudflare, AWS WAF, Imperva |
| Load Balancer | Różne odpowiedzi, nagłówek `Via`, cookie `BIGipServer` | F5, HAProxy, Nginx, AWS ALB |
| Reverse Proxy | Nagłówki `Via`, `X-Forwarded-For`, różne Server headers | Nginx, Apache, Envoy, Traefik |
| Cache | `X-Cache: HIT/MISS`, `Age`, `X-Varnish` | Varnish, Redis, Memcached |
| Database | Błędy SQL, nagłówki specyficzne | MySQL, PostgreSQL, MongoDB, MSSQL |

### CDN — identyfikacja per provider

| CDN | Sygnatury |
|-----|-----------|
| Cloudflare | Nagłówek `CF-Ray`, `Server: cloudflare`, cookie `__cfduid` |
| Akamai | Nagłówek `X-Akamai-Transformed`, cookie `AkamaiGHP` |
| AWS CloudFront | Nagłówek `X-Amz-Cf-Id`, `X-Amz-Cf-Pop`, `Via: ... CloudFront` |
| Fastly | Nagłówek `X-Served-By`, `X-Cache`, `Fastly-Debug-Digest` |
| Azure CDN | Nagłówek `X-Azure-Ref`, `X-MSEdge-Ref` |

### WAF detection — wskazówki

- Wyślij złośliwe zapytanie (np. `?id=1' OR 1=1--`) i sprawdź odpowiedź
- WAF zwykle zwraca: 403, custom error page, lub modyfikuje request
- `wafw00f` automatycznie identyfikuje > 100 typów WAF
- Nagłówki WAF: `X-WAF-Event`, `X-Protected-By`, `X-CDN-Forward`
- WAF bypass: nie oznacza że aplikacja jest bezpieczna — WAF to dodatkowa warstwa

### Architektura typowa — warstwy

```
Klient → CDN → WAF → Load Balancer → Reverse Proxy → App Server → Database
                                                    → Cache (Redis/Memcached)
                                                    → Message Queue
                                                    → External APIs
```

### Mapowanie architektury — checklist

1. **Frontend**: CDN, statyczne zasoby, SPA framework
2. **Warstwa bezpieczeństwa**: WAF, rate limiting, DDoS protection
3. **Load balancing**: round-robin, sticky sessions, health checks
4. **Application tier**: web server, app server, konteneryzacja (Docker/K8s)
5. **Data tier**: baza danych (relacyjna/NoSQL), cache, storage
6. **Zewnętrzne usługi**: payment gateway, email, SMS, OAuth providers
7. **Infrastruktura**: on-premise vs cloud (AWS/Azure/GCP), regiony

### Obrona

- Minimalizuj informacje ujawniane w nagłówkach HTTP
- Konfiguruj CDN/WAF aby nie ujawniały backend IP
- Użyj osobnych sieci dla różnych warstw (DMZ, backend, database)
- Monitoruj każdą warstwę osobno — logi, metryki, alerty
- Dokumentuj architekturę i aktualizuj diagram przy zmianach

## Pentesterskie deep dive

### Mniej znane techniki

- **Backend IP discovery via DNS history**: SecurityTrails, DNSdumpster mają historyczne A records — przed CDN frequently expose direct IP. Pivot do bypass WAF.
- **Cloudflare bypass via origin server**: jeśli backend serwuje na publicznym IP bez whitelistowania CF IP ranges, można połączyć się bezpośrednio przez `curl --resolve target.com:443:<origin_ip>`.
- **Different cache layers per Vary**: niektóre architektury cache per `User-Agent` lub `Accept-Encoding`. Bypass cache rules przez modyfikację Vary input.
- **WAF rule timing analysis**: różne WAF rules mają różną latencję — `?id=1' OR 1=1--` (SQLi rule) vs `?id=<script>` (XSS rule). Pozwala mapować kolejność rule processing.
- **Request smuggling reveals backend**: HTTP/2 → HTTP/1 desync może ujawniać prawdziwy backend stack pod CDN (frontend mówi `Server: cloudflare`, backend response z innym Server).
- **Subdomain takeover via CNAME audit**: `dig CNAME staging.target.com` może wskazywać `<oldname>.azurewebsites.net` który może być re-claimowany.

### Common pitfalls

- **CDN może ukryć WAF i ON to NICE**: warstwy mogą się nakładać — Cloudflare jako CDN + AWS WAF za nim. Trzeba probować z różnych IP regions.
- **Sticky session cookies leak backend pool size**: `BIGipServer<pool>=<id>` — analizując różne `<id>` można policzyć liczbę backend serverów.
- **Health check endpoints leak K8s topology**: `/healthz`, `/readyz`, `/livez` zwracają liveness/readiness — pojawia się gdy K8s frontend.
- **AWS Lambda cold start signature**: latencja pierwszego requestu po idle (2+ minuty) > 1s, kolejne < 100ms = serverless. Pozwala identyfikować ARN-based architecture.
- **JWT iss field as architecture hint**: `iss: "https://auth.target.com"` ujawnia auth service — często osobny endpoint do testów (OAuth/OIDC).

### Świeżynki z research

- **Cache Deception 2.0** — patterns z PortSwigger Research: nowsze warianty wykorzystują CDN URL normalization. https://portswigger.net/research/practical-web-cache-poisoning
- **HTTP Smuggling Reborn** — James Kettle research; HTTP/2 → HTTP/1 backend conversion ujawnia prawdziwy stack: https://portswigger.net/research/http2
- **Connection-state attacks (Browser-Powered Desync)** — https://portswigger.net/research/browser-powered-desync-attacks
- **Cloud metadata via SSRF** — Orange Tsai research; mapowanie cloud provider przez probing 169.254.169.254 (AWS), metadata.google.internal (GCP).
- **Origin server discovery via Censys** — https://search.censys.io/ szuka certyfikatów TLS — backend IP często mają cert dla tej samej domeny (mismatch!).
- **HackTricks Pentesting Methodology**: https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-methodology

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| HTTP Request Smuggler | Detekcja smugglingu = ujawnia backend stack | [GitHub](https://github.com/PortSwigger/http-request-smuggler) |
| Param Miner | Cache poisoning + hidden parameter discovery | [GitHub](https://github.com/PortSwigger/param-miner) |
| Wafw00f (CLI) | Identyfikacja WAF z markerów | [GitHub](https://github.com/EnableSecurity/wafw00f) |
| Asset Discover | Discovery powiązanych zasobów i domen | [GitHub](https://github.com/redhuntlabs/BurpSuite-Asset_Discover) |
| Logger++ | Centralne logowanie + filtrowanie warstwami | [GitHub](https://github.com/PortSwigger/logger-plus-plus) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/10-Map_Application_Architecture
- HackTricks Pentesting Methodology: https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-methodology
- HackTricks Cloud Pentesting: https://cloud.hacktricks.xyz/
- PortSwigger HTTP/2 Smuggling: https://portswigger.net/research/http2
- PortSwigger Web Cache Poisoning: https://portswigger.net/research/practical-web-cache-poisoning
- Wafw00f: https://github.com/EnableSecurity/wafw00f
- Censys: https://search.censys.io/
- DNSdumpster: https://dnsdumpster.com/
- SecurityTrails: https://securitytrails.com/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.1.4 | Architecture (L2) | Verified architecture and high-level threat modeling. |
| V1.10.1 | Architecture (L2) | Source code uses different repos for different security levels. |
| V13.4.6 | Information Leakage (L3) | No detailed version information of backend components. |
