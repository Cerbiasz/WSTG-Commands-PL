# WSTG-Commands-PL — automatyzacja Nuclei dla OWASP WSTG v4.2

Rozbudowana wersja repozytorium [Cerbiasz/WSTG-Commands-PL](https://github.com/Cerbiasz/WSTG-Commands-PL) z automatyzacją Nuclei + pentesterskim deep dive per kategoria WSTG. Cel: na realnej aplikacji testowej uruchomienie suite ma dawać efekt zbliżony do tego, co dałby manual pentest klasy enterprise.

## Co tu jest

- **57 szablonów Nuclei** (`templates/`) pokrywających automatyzowalne testy WSTG v4.2
- **96 plików MD** (po jednym per test WSTG) z:
  - Cel testu
  - Automatyzacja Nuclei (komenda + dodatkowe oficjalne szablony)
  - Coverage Matrix
  - Standard pentesterski (metodologia + checklist + per-stack)
  - **CHEATSHEET OWASP** (zachowany 1:1 z forku Cerbiasz)
  - Pentesterskie deep dive (mniej znane techniki + common pitfalls + świeżynki z research)
  - Rozszerzenia Burp Suite
  - Źródła + ASVS mapping
- **`scripts/run-wstg-suite.sh`** — główny wrapper z safety nets (rate limit, proxy, auth handling)
- **`scripts/generate-report.py`** — JSONL → Markdown + HTML report
- **`tests/`** — środowisko walidacyjne (docker-compose + 4 podatne aplikacje)

## Struktura repo

```
.
├── 01-INFO/        # WSTG-INFO-01..10 (Information Gathering)
├── 02-CONF/        # WSTG-CONF-01..14 (Configuration & Deployment)
├── 03-IDNT/        # WSTG-IDNT-01..05 (Identity Management)
├── 04-ATHN/        # WSTG-ATHN-01..11 (Authentication)
├── 05-ATHZ/        # WSTG-ATHZ-01..05 (Authorization)
├── 06-SESS/        # WSTG-SESS-01..11 (Session Management)
├── 07-INPV/        # WSTG-INPV-01..21 (Input Validation)
├── 08-ERRH/        # WSTG-ERRH-01..02 (Error Handling)
├── 09-CRYP/        # WSTG-CRYP-01..04 (Cryptography)
├── 10-BUSL/        # WSTG-BUSL-01..10 (Business Logic)
├── 11-CLNT/        # WSTG-CLNT-01..15 (Client-side)
├── 12-APIT/        # WSTG-APIT-01..02,99 (API Testing)
├── Network/        # Network-level pentesting notes
├── inne/           # Misc topics (Account Takeover, WAF Bypass, ...)
├── templates/      # Nuclei templates (57 .yaml + README.md)
├── scripts/        # run-wstg-suite.sh, generate-report.py
└── tests/          # docker-compose validation environment
```

## Szybki start

### 1. Wymagania

```bash
# nuclei (>= v3.0)
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest

# Python 3 + pyyaml (do raportów)
pip3 install pyyaml

# Burp Suite (do exportu site map)
```

### 2. Capture site map z Burp

1. Skonfiguruj Burp proxy (127.0.0.1:8080) i przeglądaj target
2. Burp → Site Map → prawym klikiem na host → "Save selected items" → `burp-export.xml`

### 3. Uruchom suite

```bash
# Cała suite
./scripts/run-wstg-suite.sh -i burp-export.xml -o results/

# Konkretna kategoria
./scripts/run-wstg-suite.sh -i burp-export.xml -o results/ --category INPV

# Konkretny test
./scripts/run-wstg-suite.sh -i burp-export.xml -o results/ --test WSTG-INPV-05

# Z auth
./scripts/run-wstg-suite.sh -i burp-export.xml -o results/ \
    --auth-token "Bearer eyJ..." \
    --session-cookie "PHPSESSID=abc"

# Z OpenAPI/Swagger jako input
./scripts/run-wstg-suite.sh --openapi spec.yaml -o results/

# CI/CD mode (bez proxy)
./scripts/run-wstg-suite.sh -i burp.xml -o results/ --no-proxy

# Z destrukcyjnymi (świadoma decyzja)
./scripts/run-wstg-suite.sh -i burp.xml -o results/ --include-destructive
```

### 4. Raport

Skrypt automatycznie generuje `results/report.md` i `results/report.html`. Manual:

```bash
python3 scripts/generate-report.py results/ --output-md report.md --output-html report.html
```

## Bezpieczeństwo

Suite domyślnie:
- Używa proxy 127.0.0.1:8080 (Burp) — możesz inspektować requesty
- Concurrent: 5, Rate limit: 50/s — zachowawcze (nie zatkasz target server)
- BLOKUJE destruktywne metody (DELETE, paths jak `/delete`, `/cancel`) — wymaga `--include-destructive`
- BLOKUJE statyczne zasoby z fuzzingu (.js, .css, obrazy)

## Świadome ograniczenia

### Co Nuclei robi dobrze
- HTTP-level fuzzing (query, body, header, cookie, path)
- Pattern detection (regex matchers, status, headers)
- Multi-request flows (verb tampering, HPP, mass assignment)
- OOB detection przez interactsh (SSRF, blind SQLi, etc.)

### Co wymaga manual / innych narzędzi
- DOM-based XSS (wymaga headless browsera — Burp DOM Invader)
- Multi-step business logic (BUSL — wszystkie testy manual)
- Race conditions (Burp Turbo Intruder)
- TLS analysis (testssl.sh, sslyze)
- Session ID entropy analysis (Burp Sequencer)
- 2-account testing (IDOR, BOLA — Burp Autorize)

Dla każdego manual-only WSTG testu, plik MD zawiera szczegółową metodologię w sekcji "Standard pentesterski".

## Walidacja

```bash
cd tests/
docker-compose up -d   # Juice Shop, DVWA, WebGoat, VAmPI
./run-validation.sh    # mierzy detection rate per app
docker-compose down
```

Target: ≥ 80% expected findings detected per aplikacja.

## Wzajemne wzmacnianie

Każdy test WSTG łączy:
1. **Existing CHEATSHEET** (z forku Cerbiasz) — fundament wiedzy
2. **OWASP CheatSheet Series** — referencja standards
3. **Pentest research** — PortSwigger, HackTricks, researcher community (James Kettle, Sam Curry, Frans Rosén, Orange Tsai)
4. **Konkretne payload sources** — PayloadsAllTheThings, SecLists

Każdy szablon Nuclei ma w komentarzu YAML "Source mapping" — które matchery pochodzą z CHEATSHEETa, które z research.

## Status review szablonów INPV (z poprzedniej iteracji)

20 istniejących szablonów INPV przeszło review wg 6 kryteriów (Coverage Matrix, multi-warstwowe matchery, source comments, safety nets, sweet spot payloadów, component fuzzing 5/5):

- **11 POPRAWIONY**: dodany OOB matcher (`part: interactsh_protocol`) — fix bugu gdzie callback nie był rejestrowany
- **9 ZACHOWANY**: spełniają wszystkie kryteria

Pełne uzasadnienie per szablon w komentarzu YAML każdego pliku INPV.

## Licencja i credits

- **Treści CHEATSHEET**: pochodne z [Cerbiasz/WSTG-Commands-PL](https://github.com/Cerbiasz/WSTG-Commands-PL) — zachowane 1:1
- **Szablony Nuclei**: napisane od zera na potrzeby tego projektu
- **OWASP WSTG**: https://owasp.org/www-project-web-security-testing-guide/
- **OWASP CheatSheet Series**: https://cheatsheetseries.owasp.org/

## Zgłaszanie problemów

Każdy szablon Nuclei jest niezależnie testowalny — można uruchamiać per template przez `--test WSTG-XXX-NN`. Dla zgłaszania bugu w konkretnym szablonie, dołącz:
1. Anonimizowany burp export reproduce
2. Output JSONL (`-jsonl` flag)
3. Wersję nuclei (`nuclei -version`)
