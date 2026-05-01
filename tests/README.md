# tests/ — środowisko walidacyjne WSTG Suite

## Cel

Walidacja WSTG Nuclei Suite przeciwko znanym podatnym aplikacjom (Juice Shop, DVWA, WebGoat, VAmPI). Mierzy detection rate per WSTG test ID.

## Wymagania

- Docker + docker-compose
- nuclei (`go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest`)
- python3 + pyyaml (`pip install pyyaml`)
- jq

## Jak uruchomić

```bash
# 1. Uruchom podatne aplikacje
cd tests/
docker-compose up -d

# Poczekaj ~ 1 minutę na health check
docker-compose ps  # wszystkie powinny być healthy / running

# 2. Uruchom validation suite
./run-validation.sh

# 3. Po teście - cleanup
docker-compose down
```

## Aplikacje testowe

| Aplikacja | URL | Login | Notatki |
|---|---|---|---|
| Juice Shop | http://localhost:3000 | rejestracja | Modern SPA, wszystkie OWASP Top 10 |
| DVWA | http://localhost:8080 | admin/password | Klasyk - ustaw security="low" |
| WebGoat | http://localhost:8081/WebGoat | rejestracja | Java vulnerable lessons |
| VAmPI | http://localhost:5000 | rejestracja | Vulnerable REST API |

## Pliki

- `docker-compose.yml` - definicja usług testowych
- `expected-findings.yaml` - oczekiwane podatności per aplikacja
- `run-validation.sh` - skrypt walidacyjny
- `validation-results-DATE/` - generated per uruchomienie

## Detection rate

Po uruchomieniu, skrypt wyświetla tabelę:

```
App             Expected   Detected      Rate
--------------------------------------------------
juiceshop             10          8       80% ✓
dvwa                   7          7      100% ✓
webgoat                4          3       75% ✗
vampi                  4          3       75% ✗
```

Target: **≥ 80% per aplikacja** dla acceptable detection rate.

## Burp export jako alternatywa

`run-validation.sh` używa list URL → Nuclei crawluje basic. Dla pełnego pokrycia generate Burp export:

```bash
# 1. Uruchom Burp Suite
# 2. Skonfiguruj proxy (127.0.0.1:8080)
# 3. Zaloguj się do każdej aplikacji + przejdź typowe flows
# 4. Burp → Site Map → prawym → Save selected items

# 5. Uruchom z Burp export:
../scripts/run-wstg-suite.sh -i burp-juiceshop.xml -o juiceshop-results/ --no-proxy
```

## Troubleshooting

**Container start failures**:
```bash
docker-compose logs juiceshop
docker-compose down -v  # remove volumes
docker-compose up -d
```

**Port conflicts**: Zmień ports w docker-compose.yml jeśli :3000/:8080/:8081/:5000 zajęte.

**Slow validation**: Niektóre testy (np. brute-force, time-based SQLi) wymagają czasu. Suite może trwać 30-60 min total dla wszystkich 4 apps.
