# WSTG-CONF-10 — Test for Subdomain Takeover

## Cel

Identyfikacja dangling DNS records (CNAME wskazujący na nieistniejącą instancję cloud service) umożliwiających atakującemu rejestrację service i przejęcie subdomeny. Krytyczne — przejęcie subdomeny daje cookies stealing, phishing z trusted domain, CSP/OAuth bypass.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-10-subdomain-takeover.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-10.jsonl
```

Szablon w jednym requeście z 16 named matcherami: AWS S3, AWS CloudFront, GitHub Pages, Heroku, Azure, Shopify, Tumblr, Squarespace, Fastly, Pantheon, Bitbucket, Netlify, Surge, Statuspage, Helpjuice, UserVoice.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Pełna baza takeover patterns
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/takeovers/

# Lub przez tag
nuclei -l burp-export.xml -im burp -tags takeover
```

### Suplementarne narzędzia

```bash
# Subjack - DNS-side check (CNAME analysis)
subjack -w subdomains.txt -t 100 -timeout 30 -ssl -c subjack-fingerprints.json -v

# Subzy - akywne sprawdzanie service availability
subzy run --targets subdomains.txt

# Cloud-specific:
# AWS S3 buckets
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/configs/aws-cloudfront-mil.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| AWS S3, CloudFront | ✓ | — |
| GitHub Pages, Heroku, Azure | ✓ | — |
| Shopify, Tumblr, Squarespace | ✓ | — |
| Fastly, Pantheon, Bitbucket | ✓ | — |
| Netlify, Surge, Statuspage | ✓ | — |
| Helpjuice, UserVoice | ✓ | — |
| DNS NS takeover (nameserver) | — | manual via `dig NS` |
| Dangling A/AAAA z released cloud IP | — | wymaga DNS history (SecurityTrails) |
| Email MX takeover | — | manual via `dig MX` |
| Pełna baza 100+ services | częściowe | use http/takeovers/ official |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Subdomain enumeration**: `subfinder + amass + crt.sh` → pełna lista subdomen.
2. **DNS resolution check**: `dnsx -resp -a -aaaa -cname` — które subdomeny mają CNAME do cloud services.
3. **Active probe**: `httpx -l subs.txt -title -tech-detect` — które serwują content.
4. **Subjack/Subzy scan**: DNS-side analysis CNAME → identyfikuje dangling.
5. **Nuclei takeover scan**: nasz szablon na każdej subdomenie.
6. **Manual verification**: dla każdego potencjalnego — sprawdź czy faktycznie service jest dostępny do rejestracji (np. AWS S3: `aws s3 mb s3://target-bucket`).

### Co MUSI być sprawdzone (10 punktów)

- [ ] Pełna lista subdomen (passive + active)
- [ ] DNS records: CNAME, A, AAAA, NS, MX per subdomena
- [ ] Subjack/Subzy run
- [ ] Nuclei takeover templates
- [ ] AWS S3 specifically (NoSuchBucket markers)
- [ ] Azure App Service domyślne strony
- [ ] GitHub Pages "There isn't a GitHub Pages site"
- [ ] Heroku "No such app"
- [ ] DNS NS records pointing to wycofane nameservers
- [ ] Dangling MX records (email takeover)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Subdomain takeover — mechanizm

1. Organizacja tworzy CNAME: `blog.target.com → target.herokuapp.com`
2. Organizacja kasuje konto na Heroku, ale **nie usuwa rekordu CNAME**
3. Atakujący rejestruje `target.herokuapp.com` na swoim koncie Heroku
4. `blog.target.com` teraz serwuje treść atakującego — może kraść cookies, phishing

### Usługi podatne na subdomain takeover

| Usługa | Sygnatura (error message) | Podatna? |
|--------|--------------------------|----------|
| GitHub Pages | "There isn't a GitHub Pages site here" | Tak |
| AWS S3 | "NoSuchBucket", "The specified bucket does not exist" | Tak |
| Heroku | "No such app" | Tak |
| Azure (App Service) | Domyślna strona Azure | Tak (zależy od konfiguracji) |
| Shopify | "Sorry, this shop is currently unavailable" | Tak |
| Fastly | "Fastly error: unknown domain" | Tak |
| Pantheon | "404 error unknown site" | Tak |
| Tumblr | "There's nothing here" + Tumblr branding | Tak |
| WordPress.com | "Do you want to register" | Tak |
| Ghost | "The thing you were looking for is no longer here" | Tak |
| Surge.sh | "project not found" | Tak |
| Cloudfront | "Bad Request: ERROR: The request could not be satisfied" | Możliwa |

### Typy dangling DNS records

| Typ rekordu | Ryzyko |
|-------------|--------|
| CNAME → wycofana usługa | Subdomain takeover — najczęstszy |
| A/AAAA → zwolniony IP | IP może być przejęty przez innego użytkownika chmury |
| NS → wycofany nameserver | Pełna kontrola nad subdomeną (DNS takeover) |
| MX → wycofany mail server | Przechwycenie maili — password reset, weryfikacja |

### Konsekwencje subdomain takeover

- **Cookie stealing**: jeśli cookie scope to `.target.com`, atakujący może kraść sesje
- **Phishing**: legitymna subdomena target.com z treścią atakującego
- **CSP bypass**: jeśli CSP zezwala na `*.target.com`
- **OAuth/SAML bypass**: jeśli redirect_uri akceptuje subdomeny
- **Email spoofing**: jeśli SPF zawiera `include:` dla przejętej domeny

### Obrona

- **Usuwaj rekordy DNS** przed usunięciem usługi/zasobu — nie odwrotnie
- Regularnie skanuj subdomeny i sprawdzaj CNAME pod kątem dangling records
- Użyj **DNS monitoring** do alertowania o zmianach rekordów
- Scope cookies do konkretnej subdomeny (`blog.target.com`), nie `.target.com`
- Zminimalizuj wildcard w CSP i OAuth redirect_uri
- Prowadź **inwentarz subdomen** i ich powiązania z usługami

## Pentesterskie deep dive

### Mniej znane techniki

- **Cookie scope abuse via takeover**: `.target.com` cookie scope = takeover ANY subdomeny pozwala czytać auth cookies. Przykład: `staging.target.com` takeover → wszystkie sesje na produkcji vulnerable.
- **OAuth `redirect_uri` whitelist `*.target.com`**: po takeover atakujący ma legitimate subdomenę → OAuth flow oddaje token atakującemu (Sam Curry research na bug bounty).
- **CSP `script-src *.target.com`**: takeover daje JS execution context jako zaufana domena → bypass CSP defenses.
- **DNS NS record takeover**: rzadsze ale gorsze — przejęcie nameserver pozwala na pełną kontrolę DNS subdomeny + wystawianie certs (nawet z DNS-01 challenge).
- **Email takeover via dangling MX**: atakujący przejmuje mail flow → otrzymuje password reset emails → account takeover.
- **Cloudfront subdomain takeover bez CNAME**: niektóre warianty CloudFront pozwalają na takeover poprzez wskazanie wycofanego dystrybucji.

### Common pitfalls

- **CNAME pointing to existing-but-not-claimed service**: serwis istnieje (status 404 z brand markerami), ale atakujący nie zawsze może go zarejestrować. Każdy provider ma inne mechanizmy.
- **Cloudflare protected → false positive**: jeśli subdomena jest za Cloudflare, error page może być Cloudflare 522/523 a nie service-specific.
- **DNS caching**: TTL może powodować że subjack widzi old CNAME. Use `dig +short @8.8.8.8` for fresh resolution.

### Świeżynki z research

- **Sam Curry — Apple subdomain takeover chain**: https://samcurry.net/hacking-apple/
- **EdOverflow Can-I-Take-Over-XYZ**: https://github.com/EdOverflow/can-i-take-over-xyz (live database)
- **Frans Rosén research na cloud subdomain takeover**: https://hackerone.com/reports
- **HackerOne disclosed reports na subdomain takeover**: filterowane po type "Subdomain Takeover"

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Asset Discover | Discovery powiązanych zasobów | [GitHub](https://github.com/redhuntlabs/BurpSuite-Asset_Discover) |
| Subjack (CLI) | DNS-side dangling CNAME check | [GitHub](https://github.com/haccer/subjack) |
| Subzy (CLI) | Active service availability check | [GitHub](https://github.com/PentestPad/subzy) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/10-Test_for_Subdomain_Takeover
- Can-I-Take-Over-XYZ: https://github.com/EdOverflow/can-i-take-over-xyz
- Subjack: https://github.com/haccer/subjack
- Subzy: https://github.com/PentestPad/subzy
- 0xpatrik Subdomain Takeover Basics: https://0xpatrik.com/subdomain-takeover-basics/
- HackerOne disclosed reports: https://hackerone.com/hacktivity

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Information Leakage (L3) | No detailed version information of backend components. |
| V14.1.1 | Configuration (L1) | Build process documented and repeatable. |
