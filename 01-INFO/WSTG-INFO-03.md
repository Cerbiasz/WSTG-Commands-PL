# WSTG-INFO-03 — Review Webserver Metafiles for Information Leakage

## Cel

Identyfikacja ścieżek, endpointów i metadanych ujawnianych przez pliki "menedżerskie" web serwera: `robots.txt`, `sitemap*.xml`, katalog `/.well-known/*`, `humans.txt`, `crossdomain.xml`. Te pliki są publiczne z definicji — często ujawniają ścieżki administracyjne, konfigurację OAuth/OIDC, klucze JWT, kontakty bug bounty.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-03-metafiles.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-info-03.jsonl
```

Szablon w 11 krokach: robots.txt + sitemap warianty + security.txt (z extractem Contact/Expires/Policy) + openid-configuration + oauth-authorization-server + jwks.json + assetlinks.json + apple-app-site-association + host-meta + nodeinfo + matrix federation + crossdomain.xml/clientaccesspolicy.xml + change-password + dnt-policy + humans.txt. Każdy plik = osobny finding z ekstraktorami zwracającymi konkretne wartości (np. listę Disallow paths, JWT key IDs, OAuth issuer).

### Dodatkowe oficjalne szablony Nuclei

```bash
# Exposed config files / .well-known scans
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/configs/ \
       -t resources/nuclei-templates/http/exposures/files/

# Backup files exposure (klasyczny pivot z metafiles)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/backups/

# Git/SVN exposure
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/configs/git-config.yaml \
       -t resources/nuclei-templates/http/exposures/configs/svn-wc-db.yaml

# Misconfiguration: directory listing, options method, robots.txt parsing
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/

# OAuth/OIDC well-known
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/configs/oauth2-config-exposure.yaml
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| robots.txt + Disallow extraction | ✓ | — |
| sitemap.xml + sitemap_index + warianty (news/images) | ✓ | — |
| /.well-known/security.txt (RFC 9116) | ✓ | — |
| /.well-known/openid-configuration (RFC 8414) | ✓ | — |
| /.well-known/oauth-authorization-server | ✓ | — |
| /.well-known/jwks.json (JWT public keys) | ✓ | — |
| /.well-known/assetlinks.json (Android App Links) | ✓ | — |
| /.well-known/apple-app-site-association | ✓ | — |
| /.well-known/host-meta + nodeinfo + matrix + webfinger | ✓ | — |
| crossdomain.xml + clientaccesspolicy.xml (Flash/Silverlight) | ✓ | — |
| /.well-known/change-password (RFC 8615) | ✓ | — |
| Walk Disallow paths z robots.txt → status check | — | wykonane w skrypcie wrappera |
| `<meta>` tagi w HTML (noindex/nofollow) | — | wykrywane w INFO-05 |
| OpenAPI/Swagger discovery | — | wykrywane w WSTG-APIT |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (7 kroków)

1. **Pull metafiles**: pobrać wszystkie warianty (`/robots.txt` HTTP i HTTPS, `/sitemap.xml`, `/sitemap_index.xml`, `/.well-known/*`).
2. **Parsuj robots**: każdy `Disallow:` zdejmować jako kandydata do ręcznego sprawdzenia. `Allow:` w połączeniu z `Disallow:` ujawnia internal routing.
3. **Map sitemap**: rozwinąć `sitemap_index.xml` → wszystkie sitemap → wszystkie URL. Częsty wyciek: URL niedostępne z głównej nawigacji (staging, archive).
4. **OAuth/OIDC discovery**: jeśli `openid-configuration` istnieje — zanotować `issuer`, `authorization_endpoint`, `token_endpoint`, `jwks_uri`, `grant_types_supported`. To pivot do testów OAuth (open redirect, PKCE bypass, scope confusion).
5. **JWT keys**: `jwks.json` ujawnia `kid`, algorytmy. Brak `RS256/ES256` lub obecność `none/HS256` z public RSA = testować JWT confusion.
6. **Mobile app linking**: `apple-app-site-association` i `assetlinks.json` ujawniają package/team IDs i deep-link patterns — pivot do mobile pentesting i universal-link hijacking.
7. **Legacy crossdomain**: jeśli istnieje `<allow-access-from domain="*"/>` — Flash już nie żyje, ale `clientaccesspolicy.xml` wciąż używany przez niektóre Silverlight portale enterprise.

### Co MUSI być sprawdzone (13 punktów)

- [ ] `/robots.txt` HTTP i HTTPS — wartości Disallow, Allow, Sitemap, Crawl-delay
- [ ] `/sitemap.xml` + `/sitemap_index.xml` + warianty (`-news.xml`, `-images.xml`)
- [ ] Każdy URL z sitemap sprawdzony pod kątem 200/3xx/auth
- [ ] `/.well-known/security.txt` — Contact, Expires (data nieaktualna = brak żywego programu), Policy URL
- [ ] `/.well-known/openid-configuration` — issuer + endpoints + supported grant types
- [ ] `/.well-known/oauth-authorization-server` — alternatywna lokalizacja OAuth metadata
- [ ] `/.well-known/jwks.json` — `kid`, `kty`, `alg`, `n`/`e` (RSA pub)
- [ ] `/.well-known/assetlinks.json` — Android `package_name`, SHA-256 fingerprints
- [ ] `/.well-known/apple-app-site-association` — `appID`, `applinks.details.paths`
- [ ] `/crossdomain.xml` — `<allow-access-from domain="*">` = wildcard CORS dla Flash legacy
- [ ] `/.well-known/host-meta` + `/nodeinfo` (federacja Mastodon/ActivityPub)
- [ ] `/.well-known/change-password` (RFC 8615) — często wskazuje na implementację SCM (single-click)
- [ ] `/humans.txt` — kontakty zespołu, czasem wycieki email/imion (social engineering)

### Per stack — kluczowe różnice

| Stack | robots.txt | sitemap | well-known | crossdomain |
|---|---|---|---|---|
| WordPress | autogenerowane przez plugin Yoast/Rank Math | `wp-sitemap.xml` (od 5.5) | rzadko | brak domyślnie |
| Drupal | `robots.txt` w core, listuje `/admin/`, `/CHANGELOG.txt` | `/sitemap.xml` przez moduł XML Sitemap | `/.well-known/security.txt` często ustawiony | brak |
| Spring Boot | rzadko default | brak default | brak — programmer-controlled | brak |
| Express + Helmet | brak default | brak | brak — programmer-controlled | brak |
| Django | `django.contrib.sitemaps` framework | `/sitemap.xml` przez framework | brak default | brak |
| Rails | `public/robots.txt` w skeleton | `/sitemap.xml.gz` (sitemap_generator gem) | brak default | legacy `/crossdomain.xml` w starszych Rails |
| Next.js | `public/robots.txt` lub `app/robots.ts` | `next-sitemap` paczka | konfigurowalne | brak |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### robots.txt — co szukać

- **Disallow** wpisy ujawniają ukryte ścieżki — atakujący sprawdzają je w pierwszej kolejności
- Nie używaj `robots.txt` do ukrywania wrażliwych zasobów — to informacja publiczna
- `User-agent: *` + `Disallow: /admin/` = informacja dla atakującego gdzie jest panel admina
- Sprawdź różnice między wersjami HTTP i HTTPS robots.txt

### Typowe wycieki w robots.txt

| Wpis Disallow | Co ujawnia |
|--------------|-----------|
| `/admin/`, `/administrator/` | Panel administracyjny |
| `/backup/`, `/old/`, `/temp/` | Katalogi z backupami |
| `/api/`, `/api/v1/internal/` | Wewnętrzne endpointy API |
| `/staging/`, `/dev/`, `/test/` | Środowiska deweloperskie |
| `/cgi-bin/`, `/scripts/` | Skrypty serwerowe |
| `/wp-admin/`, `/wp-includes/` | Struktura WordPress |

### sitemap.xml — informacje

- Zawiera pełną listę URL-ów strony — mapuje powierzchnię ataku
- Może zawierać URL-e niedostępne z głównej nawigacji
- Sprawdź `sitemap_index.xml` — może wskazywać na wiele sitemapów
- Porównaj URL-e z sitemap z wynikami crawlingu — różnice mogą wskazywać na ukryte zasoby

### security.txt (RFC 9116)

- Lokalizacja: `/.well-known/security.txt`
- Zawiera: kontakt do zgłaszania podatności, polityka, klucz PGP
- Może ujawnić: adresy email, programy bug bounty, scope testów
- Sprawdź pole `Expires` — przestarzały plik może zawierać nieaktualne informacje

### .well-known — interesujące endpointy

| Endpoint | Co zawiera |
|----------|-----------|
| `/.well-known/openid-configuration` | Konfiguracja OAuth/OIDC — token endpoint, supported scopes |
| `/.well-known/assetlinks.json` | Powiązania Android App Links |
| `/.well-known/apple-app-site-association` | Powiązania iOS Universal Links |
| `/.well-known/change-password` | URL do zmiany hasła (jeśli zaimplementowany) |
| `/.well-known/jwks.json` | Klucze publiczne JWT — weryfikacja tokenów |

### Obrona

- Nie polegaj na `robots.txt` jako mechanizmie bezpieczeństwa — to sugestia dla crawlerów
- Blokuj dostęp do wrażliwych zasobów przez autentykację i autoryzację, nie robots.txt
- Nie umieszczaj wewnętrznych ścieżek w robots.txt — użyj `noindex` meta tag zamiast tego
- Regularnie przeglądaj sitemap.xml — usuwaj ścieżki które nie powinny być publiczne

### Uzupełnienia do CHEATSHEET

| Endpoint | Co zawiera | Pivot |
|---|---|---|
| `/.well-known/oauth-authorization-server` | Alternatywna lokalizacja OAuth metadata (RFC 8414) | OAuth attack surface |
| `/.well-known/host-meta(.json)` | XRD — discovery (ActivityPub) | Federation account enumeration |
| `/.well-known/nodeinfo` | Mastodon/ActivityPub instance info | Software version, user count |
| `/.well-known/webfinger` | Account discovery (`?resource=acct:user@host`) | User enumeration |
| `/.well-known/openpgpkey/hu/<wkd-hash>` | WKD — Web Key Directory dla emaili | Email enumeration |
| `/.well-known/matrix/server` + `/client` | Matrix federation discovery | Identyfikacja instancji + delegacja |
| `/clientaccesspolicy.xml` | Silverlight cross-domain | Legacy enterprise — wide-open często |
| `/sitemap.xml.gz` | Skompresowany sitemap (Rails default) | Sometimes pomijany przez skanery |

## Pentesterskie deep dive

### Mniej znane techniki

- **HTTP/HTTPS delta na metafiles**: serwery z dwoma virtualhost mogą serwować różne `robots.txt` per protokół. Klasyk: `https://` ma pełny robots, `http://` zwraca 301 redirect — Disallowy widoczne tylko na HTTPS.
- **Sitemap loc spoofing przez `<image:loc>`**: rzadziej skanowane sitemap variants (`<image:loc>` w `<image:image>`) zawierają cdn-only URL — czasem niezprotegowane bucket assets.
- **JWKS rotation window**: aplikacja rotująca klucze trzyma stare i nowe `kid` w `jwks.json`. Stare klucze nadal akceptowane do wygaśnięcia tokenów = okno ataku JWT confusion na stary algorytm.
- **assetlinks.json package_name leak**: ujawnia internal Android `package_name` (np. `com.company.app.staging`) co umożliwia pull APK z Play Store / mirrors → reverse engineering.
- **OAuth `registration_endpoint`**: jeśli `openid-configuration` zwraca `registration_endpoint`, to dynamic client registration włączone (RFC 7591) — można zarejestrować client_id z dowolnym redirect_uri = pivot do account takeover.
- **WebFinger user enumeration**: `?resource=acct:admin@target.com` zwraca 200 lub 404 — enumeration kont przez federation discovery.

### Common pitfalls

- **Skanery pomijają `sitemap.xml.gz`**: Burp Spider/Acunetix domyślnie nie rozpakowują gz — manualnie `curl -s X.gz | gunzip`.
- **WAF przepuszcza `/robots.txt` bez auth, ale blokuje `/.well-known/*`**: błąd konfiguracji który widać po różnych statusach.
- **CDN cache shadowing**: Cloudflare cache może serwować stary `robots.txt` po deploy — porównać z `?cb=<random>` cache buster.
- **Reverse proxy maskuje 200 jako 404 dla `/.well-known/security.txt`**: aplikacja ma plik, proxy go nie serwuje. Wymusić bezpośredni IP scan jeśli możliwe.
- **JSON metafiles z BOM**: niektóre `assetlinks.json` mają UTF-8 BOM (Windows tooling) — niewspierane parsery zwrócą błąd, signal że plik istnieje ale niepoprawny.

### Świeżynki z research (patterns)

- **OAuth Discovery enumeration** — Frans Rosén research na temat scope/grant_types_supported jako attack surface.
- **JWT key confusion via JWKS** — pattern z research community: gdy `jwks_uri` = attacker-controlled URL (przez SSRF lub `kid` pointing) → token forgery.
- **Universal Link hijacking via apple-app-site-association** — Sam Curry research; gdy aplikacja zarejestrowana z `paths: ["*"]`, atakujący instalujący app o tym samym Team ID może przechwycić.
- **Sitemap Cache Poisoning** — Web Cache Deception variants; `target.com/sitemap.xml/foo.css` może być cached publicly z auth content.
- **`.well-known` directory listing** — niektóre serwery z włączonym `Indexes` ujawniają zawartość `/.well-known/` jako directory listing — pivot do plików o niespodziewanych nazwach.
- **PortSwigger Web Security Academy — OAuth labs**: https://portswigger.net/web-security/oauth — wszystkie warianty OAuth attacks pivotują z openid-configuration.
- **HackTricks OAuth**: https://book.hacktricks.xyz/pentesting-web/oauth-to-account-takeover

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| AdminPanelFinder | Enumeracja interfejsów administracyjnych aplikacji | [GitHub](https://github.com/moeinfatehi/Admin-Panel_Finder) |
| Backup Finder | Wyszukiwanie plików kopii zapasowych i tymczasowych | [GitHub](https://github.com/moeinfatehi/Backup-Finder) |
| Param Miner | Discovery hidden params + cache poisoning | [GitHub](https://github.com/PortSwigger/param-miner) |
| Hackvertor | Inspect/decode metafiles z BOM, base64, JWT | [GitHub](https://github.com/PortSwigger/hackvertor) |
| JWT Editor | Edycja i atakowanie JWT z jwks.json | [GitHub](https://github.com/PortSwigger/jwt-editor) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/03-Review_Webserver_Metafiles_for_Information_Leakage
- OWASP Cheat Sheet — Attack Surface Analysis: https://cheatsheetseries.owasp.org/cheatsheets/Attack_Surface_Analysis_Cheat_Sheet.html
- IANA Well-Known URIs registry: https://www.iana.org/assignments/well-known-uris/well-known-uris.xhtml
- RFC 5785 — `.well-known` URIs: https://datatracker.ietf.org/doc/html/rfc5785
- RFC 9116 — security.txt: https://datatracker.ietf.org/doc/html/rfc9116
- RFC 8414 — OAuth Authorization Server Metadata: https://datatracker.ietf.org/doc/html/rfc8414
- RFC 8615 — `.well-known/change-password`: https://datatracker.ietf.org/doc/html/rfc8615
- HackTricks Pentesting Web (Discovery): https://book.hacktricks.xyz/network-services-pentesting/pentesting-web
- PortSwigger Web Security Academy — OAuth: https://portswigger.net/web-security/oauth
- ProjectDiscovery exposures: https://github.com/projectdiscovery/nuclei-templates/tree/main/http/exposures

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.1 | Unintended Information Leakage (L1) | Verify that the application is deployed either without any source control metadata, including the .git or .svn folders, or in a way that these folders are inaccessible. |
| V13.4.5 | Unintended Information Leakage (L2) | Verify that documentation (such as for internal APIs) and monitoring endpoints are not exposed unless explicitly intended. |
| V13.4.7 | Unintended Information Leakage (L3) | Verify that the web tier is configured to only serve files with specific file extensions. |
