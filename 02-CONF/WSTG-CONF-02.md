# WSTG-CONF-02 — Test Application Platform Configuration

## Cel

Wykrycie pozostałości po deployu i debug/dev artefaktów które ujawniają informacje lub umożliwiają RCE: default pages frameworka, debug consoles (Werkzeug, Laravel Ignition, Symfony Profiler), Spring Boot Actuator, phpinfo, verbose error pages. Test krytyczny — często single misconfig daje pełen pivot do RCE.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-02-platform-config.yaml \
       -proxy http://127.0.0.1:8080 \
       -V auth_token="$AUTH_TOKEN" \
       -o results/wstg-conf-02.jsonl
```

Szablon w 7 grupach: Apache default content (`/manual/`, `/icons/`, `/server-status`), Nginx status, Tomcat default (`/manager/html`, `/examples/`, `/docs/`), PHP info (`phpinfo.php`, `info.php`), Spring Actuator chain (env/heapdump/threaddump/mappings/loggers — full pivot do CVE), debug consoles (Werkzeug `/console`, Laravel `/_ignition/health-check` z `can_execute_commands`, Rails routes, Symfony `_profiler`, Django toolbar), forced 500 error analysis (Django/Rails/ASP.NET/PHP/Java stack traces).

### Dodatkowe oficjalne szablony Nuclei

```bash
# Misconfiguration directory (~600 wzorców)
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/

# Spring Boot Actuator chain - dedicated
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/springboot/

# Tomcat manager + default credentials
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/default-logins/tomcat/ \
       -t resources/nuclei-templates/http/exposed-panels/tomcat-

# CVE templates dla typowych framework misconfigs
nuclei -l burp-export.xml -im burp \
       -tags springboot,actuator,cve
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Apache: /manual, /icons, server-status, server-info | ✓ | — |
| Nginx: nginx_status | ✓ | — |
| Tomcat: /manager, /host-manager, /examples, /docs | ✓ | default credentials → official tmpl |
| PHP: phpinfo, info.php, expose_php | ✓ | — |
| Spring Boot Actuator (env/heapdump/...) | ✓ | — |
| Werkzeug debugger | ✓ | — |
| Laravel _ignition + can_execute_commands | ✓ | — |
| Rails dev console | ✓ | — |
| Symfony WebProfiler / WDT | ✓ | — |
| Django debug toolbar | ✓ | — |
| Verbose error pages (Django/Rails/ASP.NET/PHP/Java) | ✓ | — |
| Per stack default credentials | częściowe | użyj http/default-logins/* |
| WebDAV exposed | — | osobno w CONF-06 |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Default content sweep**: Apache /manual, Tomcat /examples, IIS /iisstart, phpMyAdmin paths.
2. **Debug console probing**: Werkzeug, Laravel _ignition, Rails routes, Symfony Profiler — każdy jest osobnym RCE pivot.
3. **Spring Actuator chain**: jeśli jakikolwiek `/actuator/*` zwraca 200 → pivot do `/actuator/env` (env vars), `/actuator/heapdump` (memory dump z hasłami), `/actuator/gateway/routes` (internal microservices).
4. **Forced error analysis**: malformed query / body żeby wymusić 500 — Django zwraca yellow page z DEBUG=True; Rails dev mode UI; ASP.NET detailed errors; PHP warnings z paths.
5. **Hardening verification**: jeśli klient deklaruje `ServerTokens Prod`, sprawdzić czy wszystkie warianty banner są zhardened (Server header, error pages, manual content).
6. **Per stack pivot**: Spring → check CVE-2022-22963/22965; Laravel → CVE-2021-3129; Werkzeug → console RCE.

### Co MUSI być sprawdzone (15 punktów)

- [ ] Apache /manual/, /icons/ (200 = default content not removed)
- [ ] Apache /server-status, /server-info (mod_status exposed)
- [ ] Nginx /nginx_status
- [ ] Tomcat /manager/html, /host-manager/html (auth bypass attempts)
- [ ] Tomcat /examples/, /docs/ (sample apps)
- [ ] phpinfo.php, /info.php, /test.php
- [ ] Spring /actuator + chain (env/heapdump/threaddump/mappings)
- [ ] Werkzeug /console + ?__debugger__=yes
- [ ] Laravel /_ignition/health-check (z can_execute_commands check)
- [ ] Rails /rails/info/routes, /rails/info/properties
- [ ] Symfony /_profiler, /_wdt
- [ ] Django /__debug__/ + DEBUG=True via forced error
- [ ] Forced error → analyze stack trace dla file paths
- [ ] Custom error pages — czy zawierają stack traces?
- [ ] Static asset paths Apache (`?M=A` directory listing)

### Per stack — kluczowe ścieżki konfiguracyjne

| Stack | Default content path | Hardening setting |
|---|---|---|
| Apache | /manual, /icons, /server-status | `ServerTokens Prod`, `ServerSignature Off`, usunąć /manual |
| Nginx | /nginx_status | `server_tokens off` + nie wystawiać status |
| Tomcat | /manager, /host-manager, /examples, /docs | Custom server attribute, usunąć /examples + /docs |
| IIS | /iisstart.htm, /aspnet_client/ | Usunąć default pages, custom error pages |
| PHP | /phpinfo.php, /info.php | `expose_php=Off`, `display_errors=Off` |
| Django | /__debug__/, /admin/ | `DEBUG=False`, `ALLOWED_HOSTS` set |
| Rails | /rails/info/routes | `config.consider_all_requests_local=false` |
| Spring Boot | /actuator/* | `management.endpoints.web.exposure.include=health,info` |
| Werkzeug/Flask | /console | NIGDY w produkcji - dev-only |
| Laravel | /_ignition/* | `APP_DEBUG=false` w .env |
| Symfony | /_profiler, /_wdt | `framework.profiler.enabled: false` w prod |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Error_Handling_Cheat_Sheet.md, Logging_Cheat_Sheet.md

### Konfiguracja platformy aplikacyjnej — checklist

- **Debug mode OFF** na produkcji — Django: `DEBUG=False`, Rails: `config.consider_all_requests_local=false`
- **Verbose errors OFF** — nie pokazuj stack traces, ścieżek plików, zapytań SQL
- Usuń **sample apps** i **default pages** (Tomcat: /examples, IIS: /iisstart.htm, Apache: /manual)
- Usuń **domyślne konta**: Tomcat manager (admin/admin), Jenkins (admin), phpMyAdmin (root bez hasła)
- Zweryfikuj **error pages**: custom 404/500 bez informacji technicznych

### Konfiguracja per technologia

| Technologia | Kluczowe ustawienia |
|-------------|-------------------|
| Apache | `ServerTokens Prod`, `ServerSignature Off`, usuń `/manual`, `/icons` |
| Nginx | `server_tokens off`, usuń domyślną stronę |
| IIS | Usuń default pages, wyłącz detailed errors, usuń `.aspx` traceback |
| Tomcat | Usuń `/manager`, `/host-manager`, `/examples`, zmień domyślne credentials |
| PHP | `display_errors=Off`, `expose_php=Off`, `error_reporting=E_ALL` (do logów) |
| Django | `DEBUG=False`, `ALLOWED_HOSTS` ustawione, custom error handlers |
| Spring | `server.error.include-stacktrace=never`, actuator zabezpieczony |
| Node.js | `NODE_ENV=production`, nie ujawniaj stack traces w API |

### Logging — bezpieczne

- Loguj **właściwości bezpieczeństwa**: login, logout, zmiana hasła, błędy autoryzacji
- **NIE loguj**: haseł, tokenów, kluczy API, danych PII, numerów kart
- Centralizuj logi: ELK, Splunk, Graylog — nie tylko lokalne pliki
- Chroń logi przed modyfikacją: osobne konto, append-only, integrity monitoring

## Pentesterskie deep dive

### Mniej znane techniki

- **Spring Boot Actuator gateway routes leak**: `/actuator/gateway/routes` (Spring Cloud Gateway) ujawnia internal microservice URLs i routing rules — pivot do internal-only API.
- **Spring Actuator heapdump → credentials**: pobranie `.hprof` (Eclipse MAT do otwarcia) zawiera hasła, JWT secrets, connection strings z runtime memory. Zazwyczaj > 100MB ale często accessible.
- **Laravel Ignition `execute-solution` RCE**: CVE-2021-3129 — `/_ignition/execute-solution` z konkretnym JSON body wykonuje arbitrary PHP via `MakeViewVariableOptionalSolution`.
- **Werkzeug PIN bypass**: konsola Werkzeug wymaga PIN ale jest deterministycznie generowany z env vars + machine-id — można odzyskać przez Path Traversal lub LFI.
- **Django DEBUG=True via header injection**: nawet gdy DEBUG=False, `Host` header injection na niektórych deploymentach ujawnia stack trace przy `ALLOWED_HOSTS` mismatch (Django zwraca `DisallowedHost` z `request.META`).
- **Rails Marshal deserialization via cookies**: jeśli `secret_key_base` jest ujawnione (przez heap dump / source leak), atakujący sfałszuje session cookie z dowolnym Marshal payload → RCE.

### Common pitfalls

- **`/actuator/health` zwraca 200 mimo zhardenowania**: health endpoint jest zwykle "exposed by design" — nie jest sygnałem misconfig samym w sobie.
- **Reverse proxy 200 z empty body**: niektóre proxy zwracają 200 z empty body dla unknown paths → matchery wymagają body content > X bytes.
- **WAF rule blocking known paths**: Cloudflare blokuje `/actuator/env` na default → bypass przez `/actuator;.css` (matrix params) lub `/actuator/env%00`.
- **Self-signed cert na actuator port**: niektóre instancje serwują actuator na osobnym porcie z self-signed cert; nuclei z `-skip-ssl-verify` wymagany.

### Świeżynki z research

- **Spring4Shell (CVE-2022-22965)** — fingerprint Spring + JDK 9+ + Tomcat = warunki spełnione. https://www.lunasec.io/docs/blog/spring-rce-vulnerabilities/
- **Spring Cloud Function SpEL (CVE-2022-22963)** — RCE przez `spring.cloud.function.routing-expression` header.
- **Laravel CVE-2021-3129** — pełen exploit chain w community: phpggc + Ignition.
- **PortSwigger Web Cache Vulnerabilities Lab** — `/server-status` + cache poisoning = leak full request history.
- **HackTricks Spring Actuators**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/spring-actuators

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Pasywne wykrywanie wersji w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| ActiveScan++ | Rozszerzony aktywny skaner z misconfig checks | [GitHub](https://github.com/PortSwigger/active-scan-plus-plus) |
| Backslash Powered Scanner | Probe-based vulnerability detection | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/02-Test_Application_Platform_Configuration
- OWASP Error Handling Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html
- HackTricks Spring Actuators: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/spring-actuators
- HackTricks Werkzeug: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/werkzeug
- HackTricks Laravel: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/laravel

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.3.1 | Configuration (L2) | Web/application server, framework, application configured securely. |
| V14.3.2 | Configuration (L2) | Removed all default credentials, accounts, sample applications. |
| V13.4.5 | Information Leakage (L2) | Documentation and monitoring endpoints not exposed. |
