# WSTG-INFO-04 — Enumerate Applications on Webserver / Attack Surface Identification

## Cel

Identyfikacja wszystkich aplikacji webowych dostępnych na docelowym serwerze (vhost discovery, niestandardowe porty, ukryte ścieżki/panele). Cel: zmapować pełną powierzchnię ataku przed pójściem w głąb pojedynczej aplikacji.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-04-attack-surface.yaml \
       -proxy http://127.0.0.1:8080 \
       -V auth_token="$AUTH_TOKEN" \
       -o results/wstg-info-04.jsonl
```

Szablon w 6 grupach: panele admin (admin/manager/phpmyadmin/jboss), Spring Boot Actuator chain (env/heapdump/threaddump → CVE-bait), debug consoles (Werkzeug, Laravel `_ignition`, Rails routes, Symfony Profiler, Django debug toolbar, Yii debug, Xdebug), API discovery (Swagger/OpenAPI/GraphQL/GraphiQL), source control leaks (.git/.svn/.hg), backup/temp (.env, wp-config.bak, phpinfo, server-status).

### Dodatkowe oficjalne szablony Nuclei

```bash
# Exposed panels (kompleksowa baza paneli admin)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposed-panels/

# Konfiguracje wycieków (.env, web.config, database.yml)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/configs/

# Backup files exposure
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/backups/

# Source code leaks
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/files/

# Misconfiguration (directory listing, default content)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Admin panels (admin/manager/phpmyadmin/jboss) | ✓ | — |
| Spring Boot Actuator (full chain) | ✓ | — |
| Debug consoles (Werkzeug/Laravel/Rails/Symfony/Yii/Django) | ✓ | — |
| API discovery (Swagger/OpenAPI/GraphQL) | ✓ | — |
| Source control leaks (.git/.svn/.hg/.bzr/CVS) | ✓ | — |
| .env / config backup files | ✓ | — |
| phpinfo / server-status / nginx_status | ✓ | — |
| Subdomain enumeration | — | osobno: subfinder, amass (passive) |
| Vhost discovery (Host header fuzzing) | — | wymaga listy candidate hostów |
| Port enumeration (8080, 3000, 9090) | — | nmap/masscan w fazie pre-scan |
| DNS enumeration (TXT, MX, NS, AXFR) | — | dnsrecon, dig |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (8 kroków)

1. **Subdomain enumeration pasywna**: `subfinder -d target.com`, `amass enum -passive`, `crt.sh`. Zbierz wszystkie subdomeny zanim ruszysz aktywnie.
2. **Subdomain enumeration aktywna**: `puredns bruteforce wordlist.txt target.com` — uzupełnia pasywne. Filtr przez wildcard detection.
3. **Port scan**: `nmap -p- --min-rate 1000 target` lub `masscan -p1-65535 target` — identyfikacja niestandardowych portów (8080, 9000, 9090, 3000, 8443).
4. **HTTP service detection**: `httpx -l hosts.txt -title -tech-detect -status-code` na wszystkich (subdomena × port).
5. **Vhost fuzzing**: dla każdego unikalnego IP (po subdomenach), próba alt-hostów: `ffuf -u https://IP -H "Host: FUZZ.target.com" -fs <baseline>`.
6. **Path enumeration**: na każdej zidentyfikowanej aplikacji uruchomić nasz szablon Nuclei + dorzucić `feroxbuster` z wordlistą per stack.
7. **Tech-stack pivot**: po identyfikacji stacka (z INFO-08), uruchomić specyficzne szablony (np. dla WordPress: `nuclei -tags wordpress`).
8. **Internal vs external**: weryfikacja czy panel/console wymaga auth, czy pozwala na nieuwierzytelniony dostęp.

### Co MUSI być sprawdzone (15 punktów)

- [ ] Subdomeny zebrane pasywnie (crt.sh, subfinder, amass)
- [ ] Subdomeny pwierdzone aktywnie (DNS resolution, HTTP probe)
- [ ] Wszystkie unikalne IP enumerowane (`hosts.txt | dnsx -resp`)
- [ ] Port scan każdego unikalnego IP (nmap top 1000 + 65k jeśli scope pozwala)
- [ ] HTTP probe per subdomena × port
- [ ] Vhost fuzzing dla IP-only access (Host: x.target.com)
- [ ] `/admin`, `/administrator/`, `/login` per subdomena
- [ ] `/actuator/*` Spring chain (env, heapdump, threaddump)
- [ ] `/swagger-ui/`, `/api-docs`, `/graphql`, `/playground`
- [ ] `.git/HEAD`, `.svn/entries`, `.env`, backup files
- [ ] `/server-status`, `/server-info`, `/nginx_status`, `/phpinfo.php`
- [ ] Debug consoles (Werkzeug, Laravel `_ignition`, Rails routes)
- [ ] Niestandardowe porty (8080, 9090, 3000, 8443) per host
- [ ] Wayback URLs porównane z aktualnymi (phantom endpoints)
- [ ] DNS records (TXT, MX, NS) przeanalizowane

### Per stack — kluczowe różnice

| Stack | Ścieżki wysokiego ryzyka | Sprawdzić zawsze |
|---|---|---|
| Java/Spring Boot | `/actuator/env`, `/actuator/heapdump` | Spring Cloud Gateway: `/actuator/gateway/routes` |
| Java/Tomcat | `/manager/html`, `/host-manager/`, `/examples/` | Default credentials tomcat:tomcat |
| Java/JBoss | `/jmx-console/`, `/web-console/`, `/admin-console/` | Auth bypass via `..%3B` |
| PHP | `/phpmyadmin/`, `/info.php`, `/.env`, `/.git/` | Composer: `/vendor/composer/installed.json` |
| Node.js | `/api/swagger.json`, `/api-docs`, debug ports 9229 | Source maps `.js.map` często leak |
| Python/Flask | `/console`, `?__debugger__=yes` | Werkzeug RCE jeśli console aktywne |
| Python/Django | `/__debug__/`, `/admin/` | DEBUG=True w prod = full stack trace |
| Ruby/Rails | `/rails/info/routes`, `/rails/conductor` | Dev mode UI w prod |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Powierzchnia ataku — co enumerować

| Element | Narzędzia | Dlaczego ważne |
|---------|-----------|---------------|
| Subdomeny | subfinder, amass, crt.sh | Każda subdomena to potencjalny cel |
| Virtual hosts | ffuf, gobuster vhost | Różne aplikacje na tym samym IP |
| Porty webowe | nmap, masscan | Niestandardowe porty (8080, 3000, 9090) |
| DNS records | dig, dnsrecon | MX, TXT, NS — ujawniają infrastrukturę |
| Certificate Transparency | crt.sh | Historyczne i aktywne subdomeny z certyfikatów |
| Reverse DNS | host, dig -x | Inne domeny na tym samym IP |

### Źródła pasywnej enumeracji subdomen

| Źródło | Opis |
|--------|------|
| Certificate Transparency (crt.sh) | Publiczne logi certyfikatów SSL |
| Wayback Machine | Historyczne snapshoty z archive.org |
| DNS aggregators (SecurityTrails, PassiveTotal) | Historyczne rekordy DNS |
| Search engines (Google: `site:*.target.com`) | Zaindeksowane subdomeny |
| Shodan / Censys | Skanowanie portów i usług |
| GitHub / Pastebin | Wycieki kodu z hardcoded subdomenami |

### Virtual hosts — testowanie

- Różne aplikacje mogą być hostowane na tym samym IP pod różnymi nagłówkami `Host`
- ffuf: `ffuf -u https://IP -H "Host: FUZZ.target.com" -w wordlist.txt -fs SIZE`
- Filtruj po rozmiarze odpowiedzi (`-fs`) aby wyeliminować domyślne odpowiedzi

### DNS zone transfer (AXFR)

- `dig target.com AXFR @ns1.target.com` — jeśli dozwolony, ujawnia wszystkie rekordy
- Większość serwerów DNS jest poprawnie skonfigurowana (AXFR disabled)
- Ale zawsze warto sprawdzić — to pełna mapa DNS domeny

### Obrona — minimalizacja powierzchni ataku

- Regularnie inwentaryzuj subdomeny i usuwaj niepotrzebne
- Usuwaj rekordy DNS dla wycofanych usług (zapobieganie subdomain takeover)
- Nie hostuj wewnętrznych aplikacji na publicznych subdomenach
- Użyj wildcard DNS z rozwagą — `*.target.com` ujawnia każdą subdomenę
- Monitoruj Certificate Transparency logi pod kątem nieautoryzowanych certyfikatów
- Segmentuj aplikacje: osobne serwery/kontenery dla różnych usług

## Pentesterskie deep dive

### Mniej znane techniki

- **Subdomain takeover detection**: `subjack`, `nuclei -t takeovers/`. Wycofany serwis (Heroku app, S3 bucket, Azure CNAME) z dangling DNS = atakujący może zaregistr serwis i przejąć subdomenę.
- **Spring Cloud Gateway routes leak**: `/actuator/gateway/routes` ujawnia wewnętrzne routes (microservices) — często otwierające drogę do internal-only API przez gateway.
- **HTTP/2 connection coalescing**: jeden TLS connection do CDN może być reused dla wielu subdomen jeśli są w tym samym certyfikacie SAN — pivot do testów cross-host.
- **DNS rebinding via short TTL**: rekordy DNS z TTL 0 mogą być wykorzystane do bypassu SOP (Same-Origin Policy) - patrz INPV-19 SSRF.
- **Hidden services on uncommon ports**: 8443 (alt HTTPS), 9000 (Sonatype Nexus, Portainer), 5601 (Kibana), 8080 (alt HTTP, JBoss), 3000 (Grafana), 9090 (Prometheus, Cockpit).
- **Vhost confusion attack**: backend server może obsłużyć żądanie z `Host: alt.target.com` mimo że frontend serwuje tylko `target.com` — odkrywa internal apps (HackTricks vhost confusion).

### Common pitfalls

- **Wildcard DNS daje false positives w vhost fuzzing**: `*.target.com` resolve do tego samego IP → wszystkie odpowiedzi 200. Filtr przez `-fs <baseline_size>`.
- **CDN cache shadowing**: `/admin` może zwrócić 200 z cache po raz pierwszy, a 401/403 przy kolejnych requestach. Cache-buster (`?cb=<random>`) w fuzzingu.
- **Skanery nie potrafią deanonimizować internal**: `127.0.0.1`, `localhost` w vhost fuzzing czasem zwraca dev-mode app — wymaga oddzielnej kategorii.
- **Spring Boot Actuator chain CVE pivots**: `/actuator/heapdump` zwraca .hprof binary z hasłami, JWT secrets w pamięci. Ale skanery często go nie pobierają z size > 1GB.
- **Source maps zwrócone z 200 ale pusty body**: niektóre serwery wysyłają plik `.map` ale ze skompresowanym body niewspierany przez Nuclei → false negative.

### Świeżynki z research

- **Spring Boot Actuator Heapdump → Credentials** — community pattern, hprof analysis przez `jmap -dump` lub `eclipse MAT`.
- **GraphQL Introspection enumeration** — `?query={__schema{types{name,fields{name}}}}` ujawnia całą schema. Patrz HackTricks GraphQL.
- **Subdomain takeover via dangling AWS CloudFront** — Sam Curry / Frans Rosén research; CNAME → cloudfront.net który nie należy już do org.
- **Vhost confusion in cloud setups** — community research; ALB / Traefik z weak host validation = bypass do internal apps.
- **PortSwigger Web Cache Vulnerabilities Lab** — https://portswigger.net/web-security/web-cache-deception
- **HackTricks Pentesting Methodology**: https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-methodology
- **OWASP Amass project** — https://github.com/OWASP/Amass

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp Bounty | Active scan++ scenariusze, custom panel detection | [GitHub](https://github.com/wagiro/BurpBounty) |
| Param Miner | Hidden parameter discovery + cache poisoning | [GitHub](https://github.com/PortSwigger/param-miner) |
| Turbo Intruder | Wysokowydajny fuzzing z Python scripts | [GitHub](https://github.com/PortSwigger/turbo-intruder) |
| HTTP Request Smuggler | Smuggling discovery + vhost confusion | [GitHub](https://github.com/PortSwigger/http-request-smuggler) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/04-Enumerate_Applications_on_Webserver
- HackTricks Pentesting Methodology: https://book.hacktricks.xyz/generic-methodologies-and-resources/pentesting-methodology
- HackTricks Spring Boot Actuators: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/spring-actuators
- ProjectDiscovery (subfinder, httpx, nuclei): https://github.com/projectdiscovery
- OWASP Amass: https://github.com/OWASP/Amass
- SecLists Discovery: https://github.com/danielmiessler/SecLists/tree/master/Discovery

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V15.2.3 | Architecture (L2) | Production environment only includes functionality required to function. |
| V13.4.1 | Information Leakage (L1) | Source control metadata not exposed. |
| V13.4.5 | Information Leakage (L2) | Documentation and monitoring endpoints not exposed unless intended. |
