# WSTG Curated Payloads

Kompaktowy, kuratorowany wordlist payloadów do testów aplikacji webowych. Pokrywa **WSTG-INPV** (Input Validation Testing) i **WSTG-CLNT** (Client-side Testing) z OWASP Web Security Testing Guide v4.2.

## Filozofia

**Jakość > ilość.** ~711 unikalnych payloadów (po deduplikacji z 748 raw) zamiast 50 000. Każdy payload pokrywa inny wektor, kontekst lub bypass — żadnych 200 wariantów `<script>alert(1)</script>` z różnymi cudzysłowami. Pliki źródłowe (PayloadAllTheThings, SecLists, Jhaddix XSS, FuzzDB, PortSwigger XSS Cheatsheet, własne notatki) zostały **przesiane**, a nie skopiowane.

Każdy payload spełnia przynajmniej jedno kryterium:
- **Reprezentatywny** — typowy wektor w danej kategorii
- **Bypass-owy** — obchodzi konkretny filtr/WAF (komentarz wyjaśnia jaki)
- **Kontekstowy** — działa w specyficznym kontekście (atrybut HTML, JS string, JSON, URL)
- **Polyglot** — wiele kontekstów naraz
- **Detekcyjny** — canary / time-based probe

## Struktura

```
wordlists/
├── all-payloads.txt              # GŁÓWNY plik — 711 unikalnych, bez komentarzy, gotowy do narzędzi
├── all-payloads-annotated.txt    # Ten sam zestaw z komentarzami i sekcjami
├── all-payloads-safe.txt         # Podzbiór 554 payloadów bez wywoływania zewnętrznych requestów (no SSRF/OOB/RFI/redirect/reverse-shell)
├── injection/                    # WSTG-INPV-05..12, 18 (server-side injection)
├── xss/                          # WSTG-INPV-01..02, CLNT-01 (XSS)
├── traversal/                    # WSTG-INPV-11.1 (LFI/RFI/path traversal)
├── ssrf/                         # WSTG-INPV-19 (SSRF)
├── http/                         # WSTG-INPV-03..04, 15, 17 (HTTP-level)
├── client-side/                  # WSTG-CLNT-04..07, 10..11
└── misc/                         # WSTG-INPV-13 + canaries
```

## Mapowanie WSTG → plik

| WSTG ID | Tytuł | Plik |
|---------|-------|------|
| INPV-01 | Reflected XSS | [xss/xss-reflected.txt](xss/xss-reflected.txt), [xss/xss-attribute-context.txt](xss/xss-attribute-context.txt), [xss/xss-js-context.txt](xss/xss-js-context.txt), [xss/xss-filter-bypass.txt](xss/xss-filter-bypass.txt), [xss/xss-polyglot.txt](xss/xss-polyglot.txt) |
| INPV-02 | Stored XSS | (jak wyżej — payloady zazwyczaj te same) |
| INPV-03 | HTTP Verb Tampering | [http/http-verb-tampering.txt](http/http-verb-tampering.txt) |
| INPV-04 | HTTP Parameter Pollution | [http/parameter-pollution.txt](http/parameter-pollution.txt) |
| INPV-05 | SQL Injection | [injection/sqli-generic.txt](injection/sqli-generic.txt) + dialekty |
| INPV-05.x | SQLi: Oracle / MySQL / MSSQL / PostgreSQL / SQLite / NoSQL | `injection/sqli-{oracle,mysql,mssql,postgresql,sqlite}.txt`, [injection/nosql.txt](injection/nosql.txt) |
| INPV-06 | LDAP Injection | [injection/ldap.txt](injection/ldap.txt) |
| INPV-07 | XML / XXE Injection | [injection/xxe.txt](injection/xxe.txt) |
| INPV-08 | SSI Injection | [injection/ssi.txt](injection/ssi.txt) |
| INPV-09 | XPath Injection | [injection/xpath.txt](injection/xpath.txt) |
| INPV-11 | Code Injection (+ LFI/RFI) | [injection/code-injection.txt](injection/code-injection.txt), [traversal/lfi.txt](traversal/lfi.txt), [traversal/rfi.txt](traversal/rfi.txt), [traversal/path-traversal.txt](traversal/path-traversal.txt) |
| INPV-12 | Command Injection | [injection/command-injection.txt](injection/command-injection.txt) |
| INPV-13 | Format String | [misc/format-string.txt](misc/format-string.txt) |
| INPV-15 | HTTP Splitting/Smuggling | [http/crlf-injection.txt](http/crlf-injection.txt) |
| INPV-17 | Host Header Injection | [http/host-header.txt](http/host-header.txt) |
| INPV-18 | SSTI | [injection/ssti.txt](injection/ssti.txt) |
| INPV-19 | SSRF | [ssrf/ssrf-basic.txt](ssrf/ssrf-basic.txt), [ssrf/ssrf-bypass.txt](ssrf/ssrf-bypass.txt), [ssrf/ssrf-cloud-metadata.txt](ssrf/ssrf-cloud-metadata.txt) |
| CLNT-01 | DOM-based XSS | [xss/xss-dom.txt](xss/xss-dom.txt) |
| CLNT-02 | JavaScript Execution | [xss/xss-js-context.txt](xss/xss-js-context.txt) |
| CLNT-03 | HTML Injection | [xss/xss-reflected.txt](xss/xss-reflected.txt) |
| CLNT-04 | Open Redirect | [client-side/open-redirect.txt](client-side/open-redirect.txt) |
| CLNT-05 | CSS Injection | [client-side/css-injection.txt](client-side/css-injection.txt) |
| CLNT-06 | Client-side Resource Manipulation | [client-side/open-redirect.txt](client-side/open-redirect.txt) (URL parsing tricks) |
| CLNT-07 | CORS | [client-side/cors-origins.txt](client-side/cors-origins.txt) |
| CLNT-10 | WebSockets | [client-side/websocket.txt](client-side/websocket.txt) |
| CLNT-11 | Web Messaging (postMessage) | [client-side/postmessage.txt](client-side/postmessage.txt) |
| CLNT-13 | XSSI | (out of scope — to audyt response, nie payload) |
| —       | Detection canaries | [misc/canaries.txt](misc/canaries.txt) |

## Statystyki

| Kategoria | Liczba payloadów |
|-----------|------------------|
| XSS (reflected + DOM + attr + JS + bypass + polyglot) | 139 |
| SQLi (generic + 5 dialektów + NoSQL) | 134 |
| Command Injection | 42 |
| LFI / RFI / Path Traversal | 82 |
| SSTI | 48 |
| SSRF (basic + bypass + cloud) | 71 |
| XXE | 13 |
| LDAP / XPath | 44 |
| Open Redirect | 26 |
| CRLF / Host Header / HPP / Verb Tampering | 60 |
| CORS / postMessage / WebSocket / CSS | 32 |
| Format String | 17 |
| SSI / Code injection | 30 |
| Canaries | 10 |
| **TOTAL (raw)** | **748** |
| **TOTAL (unikalne, po dedup)** | **711** |

## Wariant "safe" (`all-payloads-safe.txt`)

Podzbiór **554 payloadów** wyfiltrowany z `all-payloads.txt` — **żaden payload nie wywołuje requestu zewnętrznego ani nie sygnalizuje na zewnątrz**. Przydatne, gdy:
- Testujesz w środowisku bez wyjścia do internetu (air-gapped lab)
- Nie chcesz fałszywych pingów do Burp Collaborator / interactsh
- Robisz pierwszą "cichą" rundę przed użyciem OOB
- Klient zabronił komunikacji wychodzącej w ramach engagementu

**Wykluczone**:
- Cały folder `ssrf/` (z definicji wywołują requesty)
- `traversal/rfi.txt` (pobiera z atakującego)
- `client-side/open-redirect.txt` (przekierowuje do externa)
- Payloady z placeholderami `{{OOB}}`, `{{ATTACKER}}`, `{{TARGET}}`, `{{CALLBACK}}`
- Reverse shells (`/dev/tcp/`, `mkfifo`, `bash -i`, `nc`)
- DNS exfil (`UTL_HTTP`, `UTL_INADDR`, `xp_dirtree`, `dblink`, `nslookup`/`curl` z OOB)
- Cloud metadata IP (`169.254.169.254`, `100.100.100.200`)
- Wrapped schemes do server-side fetch (`gopher://`, `dict://`, `tftp://`, `sftp://`, `ldap://` z hostem)
- Localhost SSRF URL-e (`http://127.0.0.1`, `http://localhost`, IPv6 loopback, decimal/hex IP)
- CSS exfil via `@import` / `@font-face url(//attacker)`

**Zachowane** (lokalne / self-contained):
- Wszystkie XSS z `alert()` / `confirm()` (lokalne wykonanie w przeglądarce testera)
- SQLi error/boolean/UNION/time-based (bez OOB)
- LFI z `file:///` i `php://filter` (lokalny odczyt pliku, bez sieci)
- Path traversal, command injection bez OOB (`;id`, `;sleep 5`)
- LDAP, XPath, NoSQL, SSTI, XXE classic file read
- CRLF, host header (statyczne wartości typu `localhost`), HPP, format string

## Placeholdery

Używane konsekwentnie we wszystkich plikach. Zamień na właściwe wartości przed użyciem.

| Placeholder | Znaczenie |
|---|---|
| `{{OOB}}` | Domena Burp Collaborator / interactsh / inny OOB callback |
| `{{TARGET}}` | Host atakowanej aplikacji (np. dla XXE SSRF do internal endpointu) |
| `{{ATTACKER}}` | IP/host atakującego (reverse shell, RFI source, redirect target) |
| `{{CALLBACK}}` | Pełny URL callback (np. dla SSRF redirect chain) |

Szybka podmiana w jednym pliku:
```bash
sed -e 's/{{OOB}}/abc.oastify.com/g' \
    -e 's/{{ATTACKER}}/10.10.14.5/g' \
    -e 's/{{TARGET}}/internal.app/g' \
    all-payloads.txt > custom.txt
```

## Jak używać

### Burp Intruder
- Załaduj `all-payloads.txt` jako Simple List w Payloads tab
- Albo plik kategorii (np. `injection/sqli-generic.txt`) dla skupionego ataku
- W razie potrzeby ustaw URL-encoding payloadów

### ffuf
```bash
ffuf -w wordlists/injection/sqli-generic.txt -u 'https://target/api?id=FUZZ' -mc all -fr 'error' -t 20
```

### sqlmap (z kuratorowanymi prefixami/sufiksami)
```bash
# Tamper-friendly — wstrzyknięcie własnych payloadów przez --suffix/--prefix
sqlmap -u 'https://target/?id=1' --prefix="' " --suffix="-- -" --technique=B
```

### wfuzz
```bash
wfuzz -w wordlists/traversal/lfi.txt -u 'https://target/?file=FUZZ' --hc 404
```

### nuclei (jako payloady do template)
W template z `payloads:` block, wskaż na konkretny plik kategorii.

## Out of scope (świadomie pominięte)

- **Pełne dumps SecLists / dotdotpwn** — 21 000+ wariantów `../` to brute force, nie kuracja
- **CVE-specific shellcode** — payloady CVE konkretnego CMS (oprócz top-tier zasad)
- **Binary shellcodes / format-string exploits** — wymagają adresów konkretnej aplikacji
- **SQLMap tamper scripts** — to skrypty Pythona, nie wordlist
- **Encyklopedyczne listy funkcji** (wszystkie 500 funkcji MySQL, kompletna lista parametrów LDAP — tylko znaczące)
- **Clickjacking** (CLNT-09) — to konfiguracja `X-Frame-Options` / CSP, nie payload
- **Browser Storage audit** (CLNT-12) — to audyt JS, nie payload
- **HTTP Incoming Requests** (INPV-16) — metodyka network-level
- **Incubated Vulnerability** (INPV-14) — metodyka, nie payload
- **Cross Site Flashing** (CLNT-08) — deprecated (Flash)
- **XSSI** (CLNT-13) — wymaga audytu cross-origin response, nie wstrzyknięcia

## Źródła i atrybucja

- **PayloadAllTheThings** — MIT License — https://github.com/swisskyrepo/PayloadsAllTheThings
- **SecLists** — MIT License — https://github.com/danielmiessler/SecLists
- **PortSwigger XSS Cheatsheet** — wybrane payloady z https://portswigger.net/web-security/cross-site-scripting/cheat-sheet
- **Jhaddix XSS / LFI lists** — public domain
- **FuzzDB** — New BSD License — https://github.com/fuzzdb-project/fuzzdb
- **OWASP WSTG** — CC BY-SA 4.0
- **Gareth Heyes XSS Polyglot** — https://research.portswigger.net/
- **Brutelogic** — krótki XSS polyglot
- **Własne dodatki** — placeholdery `{{OOB}}` itp., kuracja, komentarze, struktura

## Etyka

> Tylko do **autoryzowanych testów bezpieczeństwa**: pentestów objętych pisemnym scope, programów bug bounty z ważnym in-scope, własnych aplikacji oraz CTF. Użycie tych payloadów wobec systemów bez autoryzacji jest nielegalne w większości jurysdykcji.

## Walidacja

```bash
# Brak duplikatów w all-payloads.txt
sort -u all-payloads.txt | wc -l   # powinno = wc -l all-payloads.txt

# Liczba payloadów per plik
find . -name "*.txt" ! -name "all-*" -exec sh -c 'printf "%-50s %s\n" "$1" "$(grep -cv "^#\\|^$" "$1")"' _ {} \;
```
