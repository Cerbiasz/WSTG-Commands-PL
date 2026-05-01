# WSTG-INFO-08 — Fingerprint Web Application Framework

## Cel

Identyfikacja frameworka webowego (Spring Boot, Django, Laravel, Express, ASP.NET, Rails) oraz frontendowych SPA (React, Vue, Angular, Svelte, Next.js, Nuxt) używanych przez aplikację. Framework determinuje dalsze testy: każdy ma swoje typowe podatności, default paths, i znane CVE.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-08-framework-fingerprint.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-info-08.jsonl
```

Szablon w jednym requeście do `/` z ~25 named matcherami: WordPress / Drupal / Joomla / Magento (CMS), Laravel / Symfony / Django / Flask / Rails / Spring / Express / ASP.NET / ColdFusion (server-side frameworks), React / Vue / Angular / Svelte (SPA), Next.js / Nuxt / Astro / Remix (meta-frameworks), HTMX / Alpine / Stimulus (hypermedia), Vite / Webpack (build tools).

### Dodatkowe oficjalne szablony Nuclei

```bash
# 516 dedykowanych szablonów technologii w nuclei-templates/http/technologies/
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/ -tags tech

# Selektywnie dla typowych frameworków:
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/spring-detect.yaml \
       -t resources/nuclei-templates/http/technologies/laravel-detect.yaml \
       -t resources/nuclei-templates/http/technologies/django-detect.yaml \
       -t resources/nuclei-templates/http/technologies/wordpress-detect.yaml \
       -t resources/nuclei-templates/http/technologies/drupal-detect.yaml \
       -t resources/nuclei-templates/http/technologies/joomla-detect.yaml

# Wykrywanie CMS-ów (WPScan / JoomScan style)
nuclei -l burp-export.xml -im burp \
       -tags wordpress -severity info,low,medium

# Frontend SPA detection
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/ -tags react,vue,angular
```

### Suplementarne narzędzia

```bash
# WhatWeb / Wappalyzer - aggressive fingerprinting
whatweb https://target -v -a 3

# WPScan dla WordPress
wpscan --url https://target --enumerate u,vp,vt

# JoomScan dla Joomla
joomscan -u https://target

# Droopescan dla Drupal/SilverStripe/Moodle
droopescan scan drupal -u https://target
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| CMS: WordPress / Drupal / Joomla / Magento | ✓ | inne (Ghost/October/Statamic) → tech templates |
| PHP: Laravel / Symfony | ✓ | CodeIgniter, Yii — w tech templates |
| Python: Django / Flask | ✓ | FastAPI, Tornado, Pyramid |
| Ruby: Rails | ✓ | Sinatra |
| Java: Spring Boot | ✓ | Wildfly, Quarkus, Micronaut |
| Node: Express | ✓ | Koa, Fastify, NestJS |
| .NET: ASP.NET MVC / Core | ✓ | — |
| ColdFusion | ✓ | — |
| Frontend: React/Vue/Angular/Svelte | ✓ | — |
| Meta-frameworks: Next/Nuxt/Astro/Remix | ✓ | SvelteKit (osobno) |
| Hypermedia: HTMX/Alpine/Stimulus | ✓ | — |
| Build tools: Vite/Webpack | ✓ | Parcel, esbuild, Rollup |
| Wykrywanie *wersji* frameworka | częściowe | użyj tech templates dla precyzji |
| Favicon hash matching | — | osobny szablon (technologies/favicon) |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Pasywny fingerprint**: header (`X-Powered-By`, `X-Generator`, `Server`), cookie names, meta generator. Bez aktywnych requestów.
2. **Aktywny fingerprint**: nasz szablon Nuclei + WhatWeb/Wappalyzer.
3. **Per-stack deep dive**: po identyfikacji uruchomić specyficzne szablony (np. WordPress → wpscan, Spring → actuator chain).
4. **Version pinpointing**: użyj plików wersji (CHANGELOG, readme.html) lub static asset hashes do precyzyjnej wersji.
5. **CVE matching**: gdy wersja znana, sprawdź NVD / Snyk / nuclei `cves` tag.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Cookie name fingerprint (`PHPSESSID`/`JSESSIONID`/`ASP.NET_SessionId`/...)
- [ ] Header markers (`X-Powered-By`, `X-Drupal-Cache`, `X-AspNet-Version`)
- [ ] Meta generator tag (`<meta name="generator" content="...">`)
- [ ] Static asset paths (`/wp-content/`, `/sites/default/`, `/_next/static/`)
- [ ] CSRF token field name (framework-specific)
- [ ] Default error page banner
- [ ] Body markers (`Drupal.settings`, `__NEXT_DATA__`, `ng-version`)
- [ ] Build tool fingerprint (Vite, Webpack, Parcel)
- [ ] Hidden inputs (ASP.NET `__VIEWSTATE`, `__RequestVerificationToken`)
- [ ] Po identyfikacji — uruchomić tech-specific scanner (wpscan/joomscan/droopescan)

### Per stack — sygnatury

| Framework | Cookie | Header | Body marker | Static path |
|---|---|---|---|---|
| WordPress | `wordpress_logged_in_*` | `Link: rel=https://api.w.org/` | `wp-emoji-release.min.js` | `/wp-content/`, `/wp-includes/` |
| Drupal | `Drupal.toolbar.*` | `X-Drupal-Cache:` | `Drupal.settings` | `/sites/default/files/` |
| Joomla | brak default | `Set-Cookie: <hash>` long | `<meta name="generator" content="Joomla">` | `/components/com_*` |
| Laravel | `laravel_session`, `XSRF-TOKEN` | brak default | `<meta name="csrf-token">` | brak default |
| Django | `csrftoken`, `sessionid` | brak default | `csrfmiddlewaretoken` input | `/static/admin/` |
| Rails | `_<app>_session` | `X-Runtime`, `X-Request-Id` | `<meta name="csrf-param">` | `/assets/<sha>.css` |
| Spring Boot | `JSESSIONID` lub `SESSION` | `X-Application-Context` | `_links.self` (HAL+JSON) | brak default |
| Express | `connect.sid` | `X-Powered-By: Express` | brak default | brak default |
| ASP.NET MVC | `ASP.NET_SessionId` | `X-AspNetMvc-Version` | `__VIEWSTATE`, `__RequestVerificationToken` | `/Content/`, `/Scripts/` |
| Next.js | brak default | brak default | `__NEXT_DATA__`, `<div id="__next">` | `/_next/static/` |
| Nuxt | brak default | brak default | `window.__NUXT__` | `/_nuxt/` |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Third_Party_Javascript_Management_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Identyfikacja frameworka — sygnatury

| Framework/CMS | Sygnatury |
|--------------|-----------|
| WordPress | Cookie: `wordpress_`, ścieżka `/wp-content/`, `/wp-includes/`, meta generator |
| Joomla | Cookie: `joomla_`, ścieżka `/administrator/`, `/components/` |
| Drupal | Nagłówek `X-Drupal-Cache`, `/sites/default/files/`, `Drupal.settings` w JS |
| Laravel | Cookie: `laravel_session`, `XSRF-TOKEN`, nagłówek `X-Powered-By: PHP` |
| Django | Cookie: `csrftoken`, `sessionid`, strona admin `/admin/` |
| Spring Boot | Ścieżki `/actuator/`, cookie `JSESSIONID` |
| ASP.NET | Cookie: `ASP.NET_SessionId`, nagłówek `X-AspNet-Version`, ViewState |
| Express.js | Nagłówek `X-Powered-By: Express` (jeśli nie wyłączony) |
| Ruby on Rails | Cookie: `_session_id`, nagłówek `X-Runtime` |
| Next.js | Nagłówek `X-Powered-By: Next.js`, ścieżka `/_next/` |

### Cookie names → technologia

| Cookie | Technologia |
|--------|------------|
| `PHPSESSID` | PHP |
| `JSESSIONID` | Java (Tomcat, JBoss, Jetty) |
| `ASP.NET_SessionId` | ASP.NET |
| `connect.sid` | Node.js (Express) |
| `laravel_session` | Laravel (PHP) |
| `csrftoken` + `sessionid` | Django (Python) |
| `_rails_session` | Ruby on Rails |
| `CFID` + `CFTOKEN` | ColdFusion |

### JavaScript libraries — wykrywanie wersji

- Sprawdź w DevTools Console: `jQuery.fn.jquery`, `angular.version`, `React.version`
- Retire.js: automatyczne wykrywanie podatnych wersji bibliotek JS
- SRI (Subresource Integrity): sprawdź czy `<script>` używa atrybutu `integrity`
- Znane podatne wersje: jQuery < 3.5.0 (XSS), Angular.js 1.x (sandbox escape), Lodash < 4.17.21 (prototype pollution)

### CMS version detection — techniki

| CMS | Jak sprawdzić wersję |
|-----|---------------------|
| WordPress | `/wp-links-opml.php`, `/feed/`, meta generator, `/readme.html` |
| Joomla | `/language/en-GB/en-GB.xml`, `/administrator/manifests/files/joomla.xml` |
| Drupal | `/CHANGELOG.txt`, `/core/install.php`, nagłówek `X-Generator` |
| Magento | `/magento_version`, `/RELEASE_NOTES.txt` |

### Obrona

- Usuń meta tagi `generator` ujawniające CMS i wersję
- Aktualizuj framework i wszystkie biblioteki JS do najnowszych wersji
- Użyj SRI (Subresource Integrity) dla zewnętrznych skryptów JS
- Monitoruj CVE dla używanych technologii (Snyk, Dependabot, npm audit)
- Usuń domyślne pliki frameworka ujawniające wersje (CHANGELOG, README, VERSION)

## Pentesterskie deep dive

### Mniej znane techniki

- **Spring Boot Actuator chain pivot do RCE**: po identyfikacji Spring (przez `JSESSIONID` lub `_links` HAL), sprawdzić `/actuator/env` + `/actuator/heapdump`. CVE-2022-22965 (Spring4Shell) wymaga konkretnej konfiguracji ale fingerprint Spring + JDK 9+ + Tomcat = warunki spełnione.
- **Laravel `_ignition` chain do RCE**: CVE-2021-3129 (laravel/laravel <= 8.4.2 z `APP_DEBUG=true`); fingerprint Laravel + obecność `/_ignition/health-check` = krytyczna ścieżka.
- **Django version via `DEBUG=True` errors**: nawet bez `/admin/` można wymusić błąd przez `?param[invalid]=1` na endpoincie filtrującym, Django zwraca pełny stack trace z wersją.
- **Next.js getServerSideProps leakage**: SSR Next.js wstrzykuje initial state w `__NEXT_DATA__`. Czasami serwowane są dane authenticated użytkownika niezalogowanym (różne wycieki).
- **WordPress XML-RPC fingerprint**: `/xmlrpc.php` zwraca `<methodName>system.listMethods</methodName>` jeśli aktywny — jednocześnie pozwala na pingback DDoS i brute force amplification.
- **Mid-page framework hint via `<!-- HTML comment -->`**: wiele frameworków zostawia komentarze diagnostyczne (Symfony WebProfiler `<!-- WDT -->`, Laravel debug bar). Skanery body często to ignorują.

### Common pitfalls

- **CDN/WAF maskuje X-Powered-By**: Cloudflare strip `X-Powered-By` domyślnie; framework wciąż wykrywalny przez body markers.
- **`X-Powered-By: Express` można wyłączyć**: `app.disable('x-powered-by')` jest standardem hardeningu — fingerprint Express przez `connect.sid` cookie.
- **SPA hydration markers ujawniają framework za routingiem**: SPA może mieć custom backend, ale `<div id="__next">` zawsze zdradza Next.js niezależnie od backendu API.
- **Multi-framework deployments**: wiele aplikacji enterprise ma jeden frontend SPA + wiele backend frameworków (microservices). Każdy `/api/*` może być inny stack.
- **Old `X-Powered-By: PHP/8.0.x` z reverse proxy stripping**: nawet gdy current request bez X-Powered-By, request na `/random.php` z 404 może ujawnić PHP.

### Świeżynki z research

- **Spring4Shell + Spring Cloud Function** (2022 chain) — research community pokazał że nawet ukryte Spring instancje są wykrywalne przez stack trace markers.
- **Laravel ignition exploitation** (research community) — wzorzec: phpggc + `_ignition/execute-solution` = RCE. https://github.com/ambionics/phpggc
- **Astro SSR data leakage** — community pattern; Astro w SSR mode może wyciekać server-only props w hydration JSON.
- **HTMX server-side rendering attacks** — community research; HTMX endpointy zwracają HTML fragments, ale `hx-` attributes mogą być inputem dla XSS jeśli backend nie escape.
- **PortSwigger Web Security Academy — Insecure deserialization (per stack)**: https://portswigger.net/web-security/deserialization
- **HackTricks Pentesting Web — per framework**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web (sekcje per Spring/Laravel/Django/Rails)

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Pasywne wykrywanie wersji w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Burp Retire JS | Identyfikacja podatnych wersji bibliotek JavaScript | [GitHub](https://github.com/h3xstream/burp-retire-js) |
| Wappalyzer (browser ext) | Pasywna detekcja stosu technologii | https://www.wappalyzer.com/ |
| ActiveScan++ | Rozszerzony skaner aktywny + framework checks | [GitHub](https://github.com/PortSwigger/active-scan-plus-plus) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/08-Fingerprint_Web_Application_Framework
- HackTricks Pentesting Web: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web
- Wappalyzer database: https://www.wappalyzer.com/
- ProjectDiscovery technology templates: https://github.com/projectdiscovery/nuclei-templates/tree/main/http/technologies
- WPScan: https://wpscan.com/
- JoomScan: https://github.com/OWASP/joomscan
- Droopescan: https://github.com/SamJoan/droopescan
- Retire.js: https://retirejs.github.io/retire.js/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Information Leakage (L3) | No detailed version information of backend components. |
| V15.2.3 | Architecture (L2) | Production environment only includes required functionality. |
