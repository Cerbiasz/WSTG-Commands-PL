# WSTG-CONF-01 — Test Network Infrastructure Configuration

## Cel

Identyfikacja słabości konfiguracji infrastruktury sieciowej: otwarte porty, niepotrzebne usługi, brak segmentacji, default credentials na urządzeniach sieciowych. Test prerekursywny dla pozostałych CONF — bez mapy infrastruktury nie można ocenić powierzchni ataku.

> **Test infrastructural / manual-heavy**: skanowanie sieci to nmap/masscan a nie Nuclei. Nuclei używamy do per-host fingerprintingu i misconfig — to jest w innych testach (CONF-02, INFO-04). Tu MD opisuje metodologię i checklist.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (7 kroków)

1. **Asset discovery**: subdomain enumeration (subfinder/amass/crt.sh) → DNS resolution → IP space.
2. **Port scan kompletny**: `nmap -p- --min-rate 1000 -T4 <ip>` lub `masscan -p1-65535` na każdym unikalnym IP.
3. **Service version detection**: `nmap -sV -sC -p<otwartych>` z scriptami default — identyfikacja banner/version per port.
4. **HTTP service probe per port**: `httpx -p <ports>` — które porty serwują HTTP/HTTPS.
5. **Niestandardowe porty**: 8080, 8443, 9000, 9090, 5000, 3000, 8888 — często aplikacje admin / debug.
6. **Default credentials check**: po identyfikacji usług (FTP, SSH, Telnet, Redis, MongoDB, ElasticSearch) sprawdzić default `admin/admin`, `root/toor`, brak hasła.
7. **Network segmentation test**: czy z DMZ można dotrzeć do internal db? (pivot test gdy mamy dostęp do shell).

### Co MUSI być sprawdzone (12 punktów)

- [ ] Pełny TCP port scan (1-65535) na wszystkich IP
- [ ] UDP scan top-1000 (`nmap -sU --top-ports 1000`)
- [ ] Service banner per otwarty port
- [ ] HTTP probe per HTTP-like port
- [ ] SSH service version (CVE-relevant)
- [ ] FTP anonymous access
- [ ] SMB / NFS exposure
- [ ] Database direct access (Redis 6379, MongoDB 27017, MySQL 3306, PG 5432)
- [ ] Search engines exposed (Elasticsearch 9200, Kibana 5601, Solr 8983)
- [ ] Monitoring exposed (Prometheus 9090, Grafana 3000, Cockpit 9090)
- [ ] Container orchestration (Docker 2375 unauth, Kubernetes 6443)
- [ ] Default credentials na zidentyfikowanych usługach

### Per scenario — kluczowe ryzyka

| Wykryte | Ryzyko | Następny krok |
|---|---|---|
| Redis 6379 bez auth | RCE przez `CONFIG SET dir`+`SAVE` | HackTricks Redis |
| MongoDB 27017 bez auth | Pełny dump bazy | mongo direct connect |
| Elasticsearch 9200 open | Index dump + RCE w starych wersjach | direct curl |
| Docker daemon 2375 | Container takeover → host | docker -H tcp://target:2375 |
| Kubernetes 6443 unauth | Pełna kontrola klastra | kubectl --insecure-skip-tls-verify |
| Prometheus 9090 | Internal metrics + service discovery | metrics endpoint |
| Memcached 11211 | Reflection DDoS amp source | manual |
| RabbitMQ 15672 default | guest/guest = pełny queue access | direct login |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Docker_Security_Cheat_Sheet.md

### Hardening infrastruktury sieciowej

- **Minimalizuj otwarte porty**: uruchamiaj TYLKO wymagane usługi — zamknij wszystko inne
- **Segmentacja sieci**: izoluj bazę danych, backend, admin panel od publicznego internetu
- **Firewall rules**: default deny — jawnie zezwalaj tylko na potrzebny ruch
- **Patch management**: aktualizuj systemy operacyjne, serwery webowe, bazy danych regularnie
- Wyłącz **domyślne konta/hasła** na wszystkich urządzeniach sieciowych

### Konfiguracja serwera webowego

- Usuń domyślne strony, sample applications, dokumentację (Apache: /manual, IIS: /iisstart)
- Wyłącz **directory listing** — nie ujawniaj struktury katalogów
- Wyłącz **Server signature** — ukryj wersje serwera (Apache: `ServerTokens Prod`)
- Ogranicz metody HTTP do wymaganych (GET, POST) — zablokuj TRACE, DELETE, PUT
- Ustaw prawidłowe **file permissions** — www-data nie powinien mieć zapisu poza upload dir

### Docker/kontenery — bezpieczeństwo

- Nie uruchamiaj kontenerów jako **root** — użyj `USER` w Dockerfile
- Użyj **read-only filesystem**: `--read-only` — zapobiegaj modyfikacjom
- Skanuj obrazy pod kątem CVE: Trivy, Snyk, Grype
- Nie przechowuj sekretów w obrazie — użyj Docker secrets / env at runtime
- Ogranicz zasoby: `--memory`, `--cpus` — zapobiegaj DoS

## Pentesterskie deep dive

### Mniej znane techniki

- **TLS fingerprint via JARM**: `jarm <ip>` daje hash TLS handshake config — identyfikuje stack (Nginx vs Cloudflare vs F5) gdy banner ukryty.
- **DNS amplification potential check**: jeśli DNS server otwarty na świat z recursion enabled = potencjalne źródło DDoS amplification (ANY query).
- **NTP monlist (legacy)**: NTP servers z `monlist` enabled (CVE-2013-5211) — DDoS amplification vector.
- **IPv6 exposed**: wiele organizacji ma IPv6 prefix bez tej samej hardening co IPv4. `nmap -6 <ipv6>` — często znajduje "phantom" services.
- **Reverse DNS sweep**: `dnsx -ptr -l ip-list.txt` ujawnia inne domeny per IP — pivot do unrelated apps na tym samym hoście.

### Common pitfalls

- **CDN maskuje origin IP**: scan Cloudflare IP nie da informacji — wymaga discovery origin (Censys SAN, DNS history).
- **Rate limiting na portscan**: wykrywany przez IDS, banowany przez ISP. Slow scan (`-T2`) lub split scope.
- **Firewall stateful — port wydaje się open**: `nmap -sF -sX -sN` (FIN/Xmas/Null) może dawać "open|filtered" mylące.
- **Internal scan z external scope**: gdy klient ma `xx.xx.xx.0/16`, portscan trzeba autoryzować — w razie błędu eskalacja prawna.

### Świeżynki z research

- **Cloud metadata via SSRF** (krzyżowe z INPV-19) — wektor uzyskania internal infra knowledge.
- **Censys/Shodan favicon hash pivot** (community pattern) — identyfikacja innych hostów z tym samym backendem.
- **JARM fingerprinting**: https://github.com/salesforce/jarm
- **HackTricks Pentesting Network**: https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-network

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backslash Powered Scanner | Active scan++ z probe-based detection | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
| Asset Discover | Enumeracja powiązanych zasobów | [GitHub](https://github.com/redhuntlabs/BurpSuite-Asset_Discover) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/01-Test_Network_Infrastructure_Configuration
- HackTricks Pentesting Network: https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-network
- Nmap Network Scanning: https://nmap.org/book/
- Masscan: https://github.com/robertdavidgraham/masscan
- JARM: https://github.com/salesforce/jarm

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.14.1 | Architecture (L2) | Verified network segmentation between trust zones. |
| V14.1.1 | Configuration (L1) | Application build process documented and repeatable. |
| V14.2.2 | Dependency (L2) | Removed unneeded features, components, dependencies. |
