# WSTG-CONF-06 — Test HTTP Methods

## Cel

Sprawdzenie czy serwer akceptuje nadmiarowe metody HTTP zwiększające powierzchnię ataku: TRACE/TRACK (Cross-Site Tracing), PUT/DELETE (file ops), CONNECT (proxy), WebDAV (PROPFIND/MKCOL/MOVE). Test również Method Override przez X-HTTP-Method-Override.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-06-http-methods.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-06.jsonl
```

Szablon w 6 grupach: OPTIONS (lista dozwolonych metod + DAV header + MS-Author-Via), TRACE (XST verification z echo header), PUT (test obecności na nieistniejący path), DELETE (test na nieistniejący), X-HTTP-Method-Override (POST → DELETE override), WebDAV PROPFIND.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Method-related misconfigurations
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/misconfiguration/http-trace.yaml \
       -t resources/nuclei-templates/http/misconfiguration/options-method.yaml

# WebDAV detection
nuclei -l burp-export.xml -im burp \
       -tags webdav
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| OPTIONS allowed methods | ✓ | — |
| TRACE/TRACK (XST) | ✓ | — |
| PUT (presence test, nie destrukcyjny) | ✓ | — |
| DELETE (presence test, nieistniejący path) | ✓ | — |
| WebDAV (PROPFIND, DAV header) | ✓ | full WebDAV chain (MKCOL/COPY) → manual |
| X-HTTP-Method-Override | ✓ | — |
| `_method=` body parameter override | częściowe | manual (Rails/Laravel) |
| CONNECT (proxy method) | częściowo | przez OPTIONS, brak active test |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **OPTIONS sweep**: `OPTIONS /` na każdym endpoincie — pełna lista metod + DAV markers.
2. **TRACE verification**: aktywny TRACE z custom header → echo confirmation = XST possible.
3. **PUT/DELETE testing**: na nieistniejący path (bezpieczne); 200/201/204 = możliwy upload.
4. **Method Override**: POST z `X-HTTP-Method-Override: DELETE` na endpoincie który normalnie odrzuca DELETE → response 200/204 = override honored.
5. **WebDAV chain**: jeśli PROPFIND zwraca 207 Multi-Status, próbować MKCOL (create collection), PUT, MOVE — pełen takeover potential.

### Co MUSI być sprawdzone (10 punktów)

- [ ] OPTIONS na `/` — wszystkie zwrócone metody
- [ ] TRACE na `/` — aktywne XST (echo custom header)
- [ ] PUT na nieistniejący path
- [ ] DELETE na nieistniejący path
- [ ] X-HTTP-Method-Override: DELETE (przez POST)
- [ ] X-HTTP-Method-Override: PUT
- [ ] `_method=DELETE` jako form/JSON parameter
- [ ] PROPFIND z DAV: header
- [ ] MKCOL (jeśli WebDAV aktywny)
- [ ] CONNECT method (proxy abuse)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — REST_Security_Cheat_Sheet.md

### Metody HTTP — bezpieczeństwo

- Zezwalaj TYLKO na potrzebne metody — typowo GET i POST, opcjonalnie PUT/PATCH/DELETE dla REST API
- **TRACE**: wyłącz — umożliwia Cross-Site Tracing (XST), ujawnia cookies i auth headers
- **PUT/DELETE**: zezwalaj TYLKO na autoryzowanych endpointach API — nie na statycznych zasobach
- **OPTIONS**: może ujawniać dozwolone metody — rozważ ograniczenie (ale potrzebne dla CORS preflight)
- **CONNECT**: wyłącz — może być użyty do tunelowania
- Niestandardowe metody (FOO, JEFF): serwer powinien zwracać 405 — nie akceptować jako GET

### Konfiguracja per serwer

| Serwer | Jak ograniczyć metody |
|--------|---------------------|
| Apache | `<LimitExcept GET POST>Require all denied</LimitExcept>` |
| Nginx | `if ($request_method !~ ^(GET\|POST)$) { return 405; }` |
| IIS | Web.config: `<security><requestFiltering><verbs>` |
| Tomcat | `<security-constraint>` w web.xml |

### Method Override — zagrożenie

- Headery: `X-HTTP-Method-Override`, `X-Method-Override`, `X-HTTP-Method`
- Parametr: `_method=PUT` w body (Rails, Laravel, Django)
- Atakujący może użyć POST z override header aby wykonać PUT/DELETE
- Obrona: nie akceptuj method override headers z niezaufanych źródeł

## Pentesterskie deep dive

### Mniej znane techniki

- **JBoss HEAD bypass auth**: niektóre wersje JBoss z `<auth-constraint>` na GET ale BEZ na HEAD — atakujący sprawdza zawartość przez HEAD bez auth.
- **Tomcat method override via servlet mapping**: jeśli servlet używa `doGet()` ale framework akceptuje POST jako `_method=GET` → bypass auth na GET-only routes.
- **WebDAV MOVE for code execution**: jeśli WebDAV PUT pozwala upload `.jsp` na statyczny dir, MOVE może przenieść do `/WEB-INF/` lub innej executable lokalizacji.
- **CONNECT method abuse**: jeśli serwer jako proxy akceptuje CONNECT, atakujący może użyć go jako proxy do internal services (rzadkie ale istnieje).
- **HTTP method case sensitivity**: `get` vs `GET` — niektóre frameworki traktują różnie. Bypass auth filtra który tylko sprawdza uppercase.

### Common pitfalls

- **TRACE blokowany przez WAF, ale TRACK przepuszczany**: TRACK to Microsoft IIS odpowiednik TRACE — często pominięty w blocklistach.
- **PUT 200 nie zawsze oznacza upload**: niektóre serwery zwracają 200 z error message. Verify przez GET na uploaded path.
- **Method Override silent ignored**: header X-HTTP-Method-Override może być przyjęty ale wewnętrznie ignorowany — różne odpowiedzi to nie zawsze sukces.

### Świeżynki z research

- **HTTP/2 method smuggling** (PortSwigger Research) — różne metody w HTTP/2 frame vs HTTP/1 conversion = backend confusion.
- **HackTricks PUT method WebDAV**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/put-method-webdav

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| HTTP Request Smuggler | Detekcja smugglingu i method-related issues | [GitHub](https://github.com/PortSwigger/http-request-smuggler) |
| Authz | Testowanie authorization na różnych metodach | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/06-Test_HTTP_Methods
- HackTricks PUT WebDAV: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/put-method-webdav
- RFC 9110 (HTTP semantics): https://datatracker.ietf.org/doc/html/rfc9110
- RFC 4918 (WebDAV): https://datatracker.ietf.org/doc/html/rfc4918

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.2.1 | RESTful (L1) | Enabled HTTP methods documented and appropriate. |
| V13.2.2 | RESTful (L2) | JSON requests verify Content-Type as application/json. |
| V14.4.1 | Configuration (L1) | Disabled directory browsing, banner disclosure. |
