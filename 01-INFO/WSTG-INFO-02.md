# WSTG-INFO-02 — Fingerprint Web Server

## Cel

Identyfikacja typu i wersji serwera HTTP oraz frameworka aplikacyjnego stojącego za aplikacją. Wynik fingerprintu napędza dalszy rekonesans (CVE matching, default credentials, default paths) i kalibruje payloady w testach INPV/CONF.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-02-fingerprint-server.yaml \
       -proxy http://127.0.0.1:8080 \
       -V auth_token="$AUTH_TOKEN" \
       -o results/wstg-info-02.jsonl
```

Szablon w trzech krokach: (1) GET / — analiza nagłówków `Server`, `X-Powered-By`, `X-AspNet-Version`, `X-Runtime`, `Via`, `ETag` (inode disclosure), domyślnych ciasteczek frameworka (`PHPSESSID`, `JSESSIONID`, `ASP.NET_SessionId`, `CFID`); (2) GET /losowy-path — odciski domyślnych stron 404 dla Apache/Nginx/IIS/Tomcat/Lighttpd/Jetty/uvicorn; (3) OPTIONS / — wykrywa włączone metody TRACE/TRACK i nagłówki DAV.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Apache - wersja, default page, banner
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/apache/apache-detect.yaml

# Nginx - banner + version disclosure
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/nginx/nginx-version.yaml

# IIS - banner + ASP.NET disclosure
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/microsoft/

# Tomcat - manager, examples, version
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/tomcat/

# Wykrywanie ramy aplikacyjnej dla per-stack pivot (Spring, Django, Laravel...)
nuclei -l burp-export.xml -im burp \
       -tags tech -severity info
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Server header (Apache/Nginx/IIS/Tomcat/Lighttpd/Caddy/LiteSpeed) | ✓ | — |
| X-Powered-By (PHP/ASP.NET/Express/Servlet) | ✓ | — |
| Default error page banners (Apache/Nginx/IIS/Tomcat/Lighttpd/Jetty/FastAPI) | ✓ | — |
| ETag inode disclosure (CVE-2003-1418 pattern) | ✓ | — |
| TRACE/TRACK enabled (CWE-200, XST) | ✓ | — |
| Default framework cookies (PHPSESSID/JSESSIONID/ASP.NET) | ✓ | — |
| Header ordering analysis | — | wymaga raw socket |
| TLS fingerprint (JA3/JARM) | — | osobno w WSTG-CRYP-01 |
| Favicon hash matching | — | osobny szablon (technologies/favicon) |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Banner grabbing pasywny**: zebrać `Server`, `X-Powered-By`, `X-AspNet-Version`, `X-Runtime`, `X-Generator`, `Via`, `Set-Cookie` z domyślnej odpowiedzi. Każdy nagłówek odnotować z dokładną wartością.
2. **Banner grabbing aktywny — error pages**: wymusić 404 (random path) oraz 500 (np. malformed query string), porównać body i nagłówki. Domyślne strony błędów ujawniają server/framework w 70% przypadków nawet gdy `ServerTokens Prod`.
3. **Method probing**: `OPTIONS /` ujawnia listę metod, `TRACE` testować dla XST, niestandardowe (`PROPFIND`, `MKCOL`) wykrywają WebDAV.
4. **Protocol delta**: porównać odpowiedź HTTP/1.0 vs HTTP/1.1 vs HTTP/2 — różnice w handlingu `Connection`, `Transfer-Encoding`, kolejność nagłówków.
5. **Cookie fingerprint**: nazwa ciastka sesji to silny fingerprint frameworka — `PHPSESSID` (PHP), `JSESSIONID` (Java EE/Spring), `ASP.NET_SessionId` (ASP.NET), `CFID/CFTOKEN` (ColdFusion), `_session_id` (Rails), `connect.sid` (Express + connect), `laravel_session` (Laravel), `django_session` (Django).
6. **Version pivot**: po identyfikacji wersji od razu sprawdzić CVE database i default paths/credentials dla tego stacka.

### Co MUSI być sprawdzone (12 punktów)

- [ ] Nagłówek `Server` w odpowiedzi na GET `/`
- [ ] Nagłówek `X-Powered-By` (jeśli obecny — wersja PHP/ASP.NET/Express)
- [ ] Nagłówek `X-AspNet-Version` (legacy ASP.NET — często zapomniany przy hardeningu)
- [ ] Domyślna strona 404 (porównanie z `nginx default 404`, `Apache default 404`)
- [ ] Domyślna strona 500 (random POST z malformed JSON często wymusza)
- [ ] `OPTIONS /` z analizą `Allow:` — TRACE/TRACK powinny być wyłączone
- [ ] ETag `inode:size:mtime` pattern (Apache leak)
- [ ] Nazwa ciasteczka sesji
- [ ] `Set-Cookie` z markerami frameworka (np. `path=/`, `domain=`)
- [ ] Strona instalacji default (`/server-status`, `/server-info` Apache, `/iisstart.htm`)
- [ ] Reverse proxy detection (`Via`, `X-Forwarded-By`, `Server: cloudflare`)
- [ ] Wirtualny host fingerprint (`Host: localhost` vs prawdziwy host — różne odpowiedzi)

### Per stack — kluczowe różnice

| Stack | Server header | Cookie sesji | Default paths | Hardening |
|---|---|---|---|---|
| Apache | `Apache/2.4.x` | brak (zależy od backendu) | `/server-status`, `/icons/`, `/manual` | `ServerTokens Prod`, `ServerSignature Off` |
| Nginx | `nginx/1.x` | brak | `/nginx_status` | `server_tokens off` |
| IIS | `Microsoft-IIS/10.0` | `ASP.NET_SessionId` | `/iisstart.htm`, `/aspnet_client/` | URL Rewrite usunąć `X-Powered-By` |
| Tomcat | `Apache-Coyote/1.1` | `JSESSIONID` | `/manager/html`, `/host-manager/`, `/examples/` | Custom `<Connector server="WebServer">` |
| Express (Node) | często ukryty | `connect.sid` | `/api/*`, brak default | `app.disable('x-powered-by')` |
| Spring Boot | brak Server (Tomcat embed) | `JSESSIONID` lub `SESSION` | `/actuator/*` (RCE bez auth!) | `management.endpoints.web.exposure` |
| Django | brak / serwer reverse | `sessionid`, `csrftoken` | `/admin/`, `/static/admin/` | `DEBUG=False`, `SECURE_*` |
| Laravel | często ukryty | `laravel_session`, `XSRF-TOKEN` | `/storage/`, `/.env`, `/_ignition/` | `APP_DEBUG=false`, `.env` poza webroot |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, HTTP_Headers_Cheat_Sheet.md

### Fingerprinting serwera — źródła informacji

| Źródło | Co ujawnia | Jak ukryć |
|--------|-----------|-----------|
| Nagłówek `Server` | Nazwa i wersja serwera | `ServerTokens Prod` (Apache), `server_tokens off` (Nginx) |
| Nagłówek `X-Powered-By` | Framework/język (PHP, ASP.NET) | `expose_php=Off` (PHP), usuń nagłówek |
| Nagłówek `X-AspNet-Version` | Wersja ASP.NET | `<httpRuntime enableVersionHeader="false"/>` |
| Strony błędów (404/500) | Stack trace, ścieżki, wersje | Custom error pages bez informacji technicznych |
| Kolejność nagłówków | Identyfikacja serwera | Trudne do ukrycia — unikalna per serwer |
| Nagłówek `ETag` | Inode number (Apache) | `FileETag None` lub `FileETag MTime Size` |

### Techniki fingerprinting

- **Banner grabbing**: nagłówek `Server` w odpowiedzi HTTP
- **Error page analysis**: domyślne strony błędów są unikalne per serwer
- **HTTP method behavior**: różne serwery różnie obsługują nieznane metody
- **Header ordering**: Apache i Nginx zwracają nagłówki w różnej kolejności
- **Protocol behavior**: różnice w HTTP/1.0 vs HTTP/1.1 handling
- **Favicon hash**: hash favicony może identyfikować technologie (Shodan dork: `http.favicon.hash`)

### Konfiguracja — ukrywanie informacji per serwer

| Serwer | Konfiguracja |
|--------|-------------|
| Apache | `ServerTokens Prod`, `ServerSignature Off` |
| Nginx | `server_tokens off;` |
| IIS | Usuń `X-Powered-By`, `X-AspNet-Version` via URL Rewrite |
| Tomcat | `server` attribute w `<Connector>`, usuń default error pages |
| Node.js/Express | `app.disable('x-powered-by')` |

### Obrona

- Ukryj wersję serwera i frameworka — nie eliminuje ryzyka, ale spowalnia rekonesans
- Custom error pages: 400, 401, 403, 404, 500 bez stack traces i ścieżek
- Usuń domyślne strony instalacji (Apache default page, IIS welcome, Nginx welcome)
- Usuń niepotrzebne nagłówki: `X-Powered-By`, `X-AspNet-Version`, `X-Generator`
- **Security through obscurity nie wystarczy** — to dodatkowa warstwa, nie główna obrona

### Uzupełnienia do CHEATSHEET

| Źródło | Co ujawnia | Notka |
|---|---|---|
| `Via:` | Łańcuch proxy + wersja oprogramowania pośredniczącego | RFC 7230 §5.7.1 |
| `X-Cache:` / `Age:` | Wersja CDN (Varnish, Akamai, CloudFront) | Cache poisoning surface |
| Domyślne ciasteczko frameworka | Stack identification (lepsze niż Server header) | `JSESSIONID` = Java, `_csrf-token` = Rails 5+ |
| Komponent w `Set-Cookie` Path/Domain | Subpath aplikacji (np. `/grafana/`) | Mapuje internal routing |

## Pentesterskie deep dive

### Mniej znane techniki

- **HTTP/2 fingerprint via SETTINGS frame**: parametry HTTP/2 (HEADER_TABLE_SIZE, INITIAL_WINDOW_SIZE) są stack-specific. Można odczytać z `curl --http2 -v` i porównać z bazą AKAMAI/Cloudflare/nginx/h2load. Idea: tak jak JA3 dla TLS, tak HTTP/2 settings są fingerprintem L7.
- **Time-based stack detection**: różne stacki mają różną latencję pierwszego bajtu — Tomcat z lazy-init kontrastuje z Express; PHP-FPM cold-start daje skok 50-200ms na pierwszym hicie po idle. Mierzalne przez 10× powtórzenie.
- **Response body whitespace**: serwery mają różne style minify/format. Spring Boot zwraca JSON bez spacji, Express domyślnie z. Node native http vs Fastify vs Express różnią się kolejnością nagłówków `Content-Type` i `Date`.
- **Error path delta**: Apache zwraca 403 dla `/.htaccess`, Nginx 404 (chyba że `location ~ /\.ht`). Probing kilku ukrytych ścieżek konfiguracyjnych mówi które reguły są w configu.
- **WebDAV residual detection**: niektóre instalacje mają moduł `mod_dav` lub `WebDAV` ale nie są używane. `OPTIONS /` zwróci nagłówki `DAV:`, `MS-Author-Via:` — sygnał że można się dobrać do `PUT/DELETE/PROPFIND`.

### Common pitfalls

- **CDN maskuje server**: Cloudflare nadpisuje `Server: cloudflare`, ale `cf-ray`, `cf-cache-status` zdradzają CDN; backend można obejść przez DNS history (SecurityTrails) lub direct-IP scan.
- **Reverse proxy zacieranie**: Nginx-jako-proxy do Apache zwróci `Server: nginx/...` — prawdziwy backend ujawni się w error page lub przez `Server: Apache` w odpowiedzi 502.
- **Custom 404 page handler**: aplikacja może mieć middleware przechwytujący 404 i zwracający `200 OK` z brandowaną stroną — wymusić 500 przez malformed body zamiast 404.
- **Mock servers w dev**: niektóre środowiska QA używają mockoonów / wiremock — fingerprint pokazuje "fake" stack a nie produkcyjny.
- **HTTP/2 connection coalescing**: jeden connection do CDN może serwować wiele różnych aplikacji backendowych — fingerprint per host: nagłówek wymaga ostrożności.

### Świeżynki z research (patterns)

- **HTTP/2 request smuggling fingerprint** — stack reagujący różnie na `transfer-encoding` w HTTP/2 jest fingerprintem (PortSwigger Research, James Kettle).
- **Connection-state attacks** — backend stack ujawnia się przez różne handling pipelined / coalesced requests; pattern z portswigger.net/research.
- **Spring Actuator probing** — gdy `Server` ukryte, `/actuator`, `/actuator/env`, `/actuator/heapdump` natychmiast identyfikują Spring Boot. Kluczowe dla pivot do RCE (CVE-2022-22963 SpEL).
- **Next.js `__next/data` paths** — fingerprint Next.js przez `_next/data/<buildId>/...` w body.
- **Laravel `_ignition` debug detection** — `/_ignition/health-check` zwraca JSON jeśli debug włączony (CVE-2021-3129 dla starszych wersji).
- **Werkzeug debugger console** — `/console` lub `?__debugger__=yes` zwraca interaktywny REPL → RCE w Flask/Werkzeug dev mode.
- **PortSwigger Web Security Academy — Information disclosure**: https://portswigger.net/web-security/information-disclosure — labs są golden standardem ćwiczeń.
- **HackTricks Pentesting Web** — https://book.hacktricks.xyz/network-services-pentesting/pentesting-web — sekcje per stack (Apache, Nginx, Tomcat, IIS).

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Pasywne wykrywanie wersji w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Active Scan++ | Rozszerzony skaner aktywny i pasywny z dodatkowymi checkami | [GitHub](https://github.com/PortSwigger/active-scan-plus-plus) |
| Burp Retire JS | Wykrywanie podatnych wersji bibliotek JavaScript | [GitHub](https://github.com/h3xstream/burp-retire-js) |
| HTTP Request Smuggler | Detekcja smugglingu = pivot do fingerprint backend | [GitHub](https://github.com/PortSwigger/http-request-smuggler) |
| Wappalyzer (browser ext) | Identyfikacja stosu technologii passively | [Wappalyzer](https://www.wappalyzer.com/) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/02-Fingerprint_Web_Server
- OWASP Cheat Sheet — HTTP Headers: https://cheatsheetseries.owasp.org/cheatsheets/HTTP_Headers_Cheat_Sheet.html
- OWASP Cheat Sheet — Attack Surface Analysis: https://cheatsheetseries.owasp.org/cheatsheets/Attack_Surface_Analysis_Cheat_Sheet.html
- HackTricks Pentesting Web: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web
- PortSwigger — Information Disclosure: https://portswigger.net/web-security/information-disclosure
- PortSwigger Research (HTTP smuggling, connection-state): https://portswigger.net/research
- ProjectDiscovery — nuclei-templates technologies: https://github.com/projectdiscovery/nuclei-templates/tree/main/http/technologies
- ASVS V13.4 — Unintended Information Leakage: https://owasp.org/www-project-application-security-verification-standard/

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Unintended Information Leakage (L3) | Verify that the application does not expose detailed version information of backend components. |
