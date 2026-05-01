# WSTG-INFO-01 — Conduct Search Engine Discovery Reconnaissance for Information Leakage

## Cel

Identyfikacja informacji o aplikacji ujawnionej publicznie przez wyszukiwarki, archiwa i agregatory OSINT. Cel pasywny — zero requestów do produkcyjnej infrastruktury klienta — co czyni ten test pierwszym krokiem każdego engagementu (zero detekcji po stronie obrońcy).

> **Test manual-only**: brak automatyzacji Nuclei. Wyszukiwarki blokują automatyczne zapytania, a OSINT wymaga oceny kontekstowej. Patrz sekcja "Standard pentesterski" dla narzędzi specjalistycznych (theHarvester, Shodan, GitHub dorks).

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (8 kroków)

1. **Google dorking pasywny** — operatory: `site:`, `inurl:`, `intitle:`, `filetype:`, `cache:`, `intext:`. Konkretnie dla domeny celu plus interesujące rozszerzenia (`.bak`, `.sql`, `.env`, `.log`, `.config`).
2. **Bing/DuckDuckGo cross-check** — Google ma agresywny rate-limit i zniekształcone wyniki dla automatów. Bing często ma świeższe wyniki dla mniejszych domen.
3. **Wayback Machine + archive.today** — historyczne wersje stron często zawierają endpointy/parametry usunięte z aktualnej wersji. Kluczowe dla "phantom endpoints" (kod usunięty ale serwis jeszcze działa).
4. **Certificate Transparency logs** — `crt.sh`, `censys.io/certificates` ujawniają wszystkie subdomeny (włącznie z dev/staging) z wystawionych certyfikatów SSL.
5. **GitHub/GitLab/BitBucket dorks** — `org:<target> password`, `"<target.com>" api_key`, `<target.com> filename:.env`. Wycieki w repo deweloperów to klasyk (Sam Curry research).
6. **Pastebin / Pastes / Gist** — Pastebin search, GreyNoise, IntelX agregują wycieki z pastebin-like services.
7. **Shodan / Censys / FOFA** — pasywny fingerprint infrastruktury bez touchu na target. Filtry: `ssl:"<target.com>"`, `org:"<Company Name>"`, `http.favicon.hash:<hash>`.
8. **Social engineering OSINT** — LinkedIn employees → email format inference → username enumeration na panelu logowania (manualne weryfikowanie).

### Co MUSI być sprawdzone (12 punktów)

- [ ] Google `site:target.com` — pełna lista zaindeksowanych URL
- [ ] Google `site:target.com filetype:pdf|doc|xls|csv|sql|bak|env|log|conf|xml|json|yml`
- [ ] Google `site:target.com inurl:admin|login|api|debug|staging|dev|test`
- [ ] Google `site:target.com intitle:"index of"` — directory listing
- [ ] Bing `site:target.com` — różnice względem Google
- [ ] Wayback Machine snapshots ostatnie 5 lat (zmiany w robots, structure)
- [ ] Certificate Transparency: `crt.sh/?q=%.target.com`
- [ ] GitHub: `"target.com" password|secret|api_key|token`
- [ ] Pastebin Pro Search lub `psbdmp.ws`
- [ ] Shodan: `hostname:target.com` + `org:"<CompanyName>"`
- [ ] LinkedIn — employees, tech stack mentions w opisach
- [ ] Wayback / archive — stare wersje robots.txt, sitemap.xml

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Analiza Attack Surface — co zmapować

- **Punkty wejścia danych**: formularze, URL parametry, nagłówki HTTP, cookies, pliki upload, API endpoints
- **Punkty wyjścia danych**: odpowiedzi HTTP, pliki do pobrania, emaile, WebSocket
- **Zasoby**: pliki statyczne, bazy danych, pliki konfiguracyjne, logi, backupy
- **Infrastruktura**: serwery, porty, subdomeny, CDN, load balancery, microservices

### Grupowanie wg ryzyka

- **Najwyższe ryzyko**: endpointy dostępne anonimowo z internetu (login, rejestracja, API publiczne)
- **Wysokie ryzyko**: endpointy uwierzytelnione z dostępem do wrażliwych danych (profil, płatności)
- **Średnie ryzyko**: endpointy wewnętrzne (panel admin, monitoring)
- **Niższe ryzyko**: zasoby statyczne (obrazy, CSS, JS — ale sprawdź czy nie zawierają sekretów)

### OSINT — pasywne zbieranie informacji

- **Google Dorking**: `site:TARGET filetype:pdf`, `inurl:admin`, `intitle:"index of"`
- **Shodan/Censys**: skanowanie portów, usług, certyfikatów SSL bez bezpośredniego kontaktu z TARGET
- **Wayback Machine**: historyczne wersje stron — może ujawniać stare endpointy, pliki konfiguracyjne
- **GitHub/GitLab**: wyciek kodu źródłowego, kluczy API, credentials — `"TARGET" password`, `"TARGET" api_key`
- **DNS**: subdomeny, rekordy MX, TXT (SPF, DKIM), CNAME — amass, subfinder, dnsrecon
- **Certificate Transparency**: crt.sh — odkrywanie subdomen z certyfikatów SSL

### Monitoring zmian Attack Surface

- Porównuj attack surface PRZED i PO każdym wdrożeniu
- Nowe endpointy, nowe parametry, nowe formularze = nowe ryzyko
- Automatyzuj discovery: regularne skanowanie, crawlowanie, porównywanie z baseline

### Dane wrażliwe do identyfikacji

- PII (dane osobowe): imiona, adresy, PESEL, email
- Credentials: hasła, tokeny, klucze API, connection strings
- Dane finansowe: numery kart, konta bankowe
- Dane medyczne, prawne — regulacje GDPR, HIPAA, PCI DSS

## Pentesterskie deep dive

### Mniej znane techniki

- **Wayback CDX API**: programatyczny dostęp do snapshotów (`https://web.archive.org/cdx/search/cdx?url=target.com&output=json&collapse=urlkey`) — pełna lista historycznych URL bez UI.
- **GitHub code search regex**: nowe GitHub Search wspiera regex w content (`/AKIA[0-9A-Z]{16}/`) — szybkie wyłapywanie hardcoded AWS keys per organization.
- **Shodan favicon hash pivot**: `http.favicon.hash:<hash>` znajdzie wszystkie hosty z tym samym favicon → odkrywa nieznane instancje aplikacji w innej infrastrukturze.
- **Censys SAN scanning**: certyfikaty SAN ujawniają wszystkie subdomeny używane na danym IP — wsteczna identyfikacja CDN/load balancer setupów.
- **Search engine cache resurrection**: `cache:target.com/admin/login` Google cache trzyma stronę nawet po jej usunięciu — przydatne dla dev environments które już zniknęły.
- **Public S3 bucket enumeration**: GrayhatWarfare, S3 Search engines indexują publiczne bucketsy — `<company-backup>`, `<company-logs>`, `<company-staging>` często odkryte.

### Common pitfalls

- **Google rate-limit**: ręczne zapytania > automatyczne. Po 50 dorks Google zażąda CAPTCHA i zablokuje IP. Używaj Tor / proxy chain dla większego volume.
- **Wayback Machine respektuje robots.txt retroaktywnie**: jeśli aktualny `robots.txt` zabrania indeksowania, archiwum często zwraca "Page cannot be displayed". Bypass: zmiana User-Agent, próba alternatywnych snapshotów.
- **GitHub usunięte wycieki**: GitHub usuwa commity z secrets w ~30 sekund po raporcie automatycznym, ale forki mogą zachować je permanentnie.
- **Tilde-username enumeration**: `https://target.com/~username/` (Apache UserDir) — czasem aktywne na legacy hostach (HackTricks).
- **Shodan może nie odświeżyć danych**: Last-Update timestamp może być sprzed roku — historyczne dane, nie current state.

### Świeżynki z research

- **GitHub Code Search 2.0** (2023+) — pełna semantic search w kodzie, regex support; pivot do organization-wide secret hunting.
- **Wayback CDX + DOM parsing** — nowsze techniki wyciągania URL z historycznych snapshotów (PortSwigger Burp Suite "Wayback" extension).
- **Crt.sh wildcard fuzzing** — pattern: zapytanie o `%.target.com` zwraca wildcard SAN cert który może ujawnić wszystkie internal subdomain naming conventions.
- **OSINT for OAuth client_id leakage** — community research; client_id zarejestrowane przez aplikację mogą wyciec w mobile app binaries (assetlinks/aasa).
- **PortSwigger Web Security Academy — Information disclosure**: https://portswigger.net/web-security/information-disclosure — labs dotyczą głównie active testing, ale pattern "find by ID enumeration" stosuje się też do OSINT.
- **HackTricks External Recon Methodology**: https://book.hacktricks.xyz/generic-methodologies-and-resources/external-recon-methodology

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| GAP-Burp-Extension | Automatyczne wyciąganie parametrów, linków i słów z odpowiedzi | [GitHub](https://github.com/xnl-h4ck3r/GAP-Burp-Extension) |
| Asset Discover | Odkrywanie powiązanych zasobów i domen | [GitHub](https://github.com/redhuntlabs/BurpSuite-Asset_Discover) |
| Domain Hunter | Wyszukiwanie powiązanych domen i subdomen | [GitHub](https://github.com/bit4woo/domain_hunter) |
| Wayback Burp | Pull URLs z Wayback Machine bezpośrednio do Site Map | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/01-Conduct_Search_Engine_Discovery_Reconnaissance_for_Information_Leakage
- OWASP Cheat Sheet — Attack Surface Analysis: https://cheatsheetseries.owasp.org/cheatsheets/Attack_Surface_Analysis_Cheat_Sheet.html
- HackTricks External Recon: https://book.hacktricks.xyz/generic-methodologies-and-resources/external-recon-methodology
- Google Hacking Database (Exploit-DB): https://www.exploit-db.com/google-hacking-database
- crt.sh Certificate Transparency: https://crt.sh/
- Shodan: https://www.shodan.io/
- Censys: https://search.censys.io/
- Wayback Machine: https://web.archive.org/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.1 | Unintended Information Leakage (L1) | Verify that the application is deployed without source control metadata (.git/.svn). |
| V13.4.5 | Unintended Information Leakage (L2) | Verify that documentation and monitoring endpoints are not exposed unless explicitly intended. |
