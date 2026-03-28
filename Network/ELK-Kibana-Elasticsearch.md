# Elasticsearch i Kibana -- Pentesting Stosu ELK

## 1. Elasticsearch (port 9200)

### Domyslne dane / brak autentykacji
- **Domyslnie Elasticsearch NIE ma wlaczonej autentykacji** -- pelny dostep do wszystkich danych
- Domyslni uzytkownicy (jesli auth wlaczony): `elastic` (superuser), `kibana_system`, `logstash_system`, `beats_system`, `apm_system`
- **Domyslne haslo starszych wersji**: `changeme`

### Weryfikacja autentykacji
```bash
curl -X GET "http://<HOST>:9200/"
# Jesli 401 -> auth wlaczony; jesli JSON z info o klastrze -> brak auth

curl -X GET "http://<HOST>:9200/_xpack/security/user"
# Blad "Security must be explicitly enabled" = brak auth
```

### Krytyczne endpointy API
```bash
# Informacje o klastrze
GET /
GET /_cluster/health
GET /_cluster/stats
GET /_nodes/stats

# Enumeracja uzytkownikow i rol
GET /_security/user
GET /_security/role
GET /_security/api_key

# Lista indeksow (= tabel)
GET /_cat/indices?v

# Informacje o indeksie
GET /<index>

# Dump danych z indeksu
GET /<index>/_search?pretty=true&size=9999

# Dump WSZYSTKICH danych
GET /_search?pretty=true&size=9999

# Wyszukiwanie (regex)
GET /_search?pretty=true&q=password
GET /_search?pretty=true&q=admin
GET /<index>/_search?pretty=true&q=<term>

# Pluginy
GET /_cat/plugins
```

### Sprawdzanie uprawnien zapisu
```bash
curl -X POST 'http://<HOST>:9200/testindex/testtype' \
  -H 'Content-Type: application/json' \
  -d '{"test":"write_check"}'
```

### Automatyzacja
```bash
msf> use auxiliary/scanner/elasticsearch/indices_enum
# Shodan: port:9200 elasticsearch
```

---

## 2. Kibana (port 5601)

### Dostep i autentykacja
- **Kibana dziedziczy autentykacje z Elasticsearch** -- jesli ES nie ma auth, Kibana tez jest otwarta
- Dane logowania moga byc w `/etc/kibana/kibana.yml`
- Jesli uzytkownik w konfiguracji nie jest `kibana_system`, moze miec **szersze uprawnienia**

### Po uzyskaniu dostepu
- **Przegladaj dane** -- logi, metryki, dane biznesowe w indeksach ES
- **Zarzadzanie uzytkownikami**: Stack Management -> Users/Roles/API Keys (tworzenie, edycja, usuwanie)
- **Znane podatnosci**: RCE w wersjach **< 6.6.0** (sprawdz wersje!)

### Brak SSL/TLS
- Jesli Kibana bez HTTPS -> **wszystkie dane i dane logowania przesylane plaintextem**
