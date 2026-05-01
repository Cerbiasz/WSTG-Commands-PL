# WSTG-CONF-09 — Test File Permission

## Cel

Weryfikacja uprawnień plikowych aplikacji webowej: czy proces serwera (www-data) ma minimalne wymagane prawa, czy upload directory nie jest wykonywalny, czy klucze prywatne i config files są chronione przed dostępem przez HTTP.

> **Test infrastructural / manual**: uprawnienia plikowe testowane są na poziomie systemu plików (ssh + ls -la, find world-writable). Nuclei nie ma tu zastosowania - z perspektywy HTTP możemy tylko sprawdzić czy wrażliwe pliki są dostępne (cross-ref WSTG-CONF-03).

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **HTTP-side check**: cross-reference z WSTG-CONF-03 (file extensions) — czy `.env`, `.git/`, `id_rsa` są dostępne przez HTTP.
2. **Local audit (po uzyskaniu shell)**: `find /var/www -perm -o+w -type f` (world-writable), `find /var/www -perm -o+r -name "*.key" -o -name "*.pem"`.
3. **Process ownership**: `ps aux | grep -E "(apache|nginx|httpd|node|python|ruby)"` — kto uruchamia serwer.
4. **File ownership audit**: czy `chown -R www-data:www-data /var/www/` jest aplikowane consistent (web user = file owner = bypass file permissions completely).
5. **Upload directory test**: czy `/uploads/test.php` z PHP code jest wykonywalne (gdy upload accepted)?

### Co MUSI być sprawdzone (10 punktów - po uzyskaniu shell)

- [ ] World-writable files w webroot (`find /var/www -perm -o+w -type f`)
- [ ] World-readable sensitive files (`*.key`, `*.pem`, `id_rsa`, `.env`)
- [ ] Process user vs file owner (jeśli te same = bypass uprawnień)
- [ ] Upload directory permissions (powinno być 750, nie 777)
- [ ] Upload directory wykonywalność PHP/JSP/ASPX (test przez file upload)
- [ ] `.git/` directory permissions (powinno być chmod 700 dla deployment user)
- [ ] Log files permissions (640, append-only via setattr +a)
- [ ] Config files (640, group www-data dla read)
- [ ] Setuid/setgid files (`find /var/www -perm /6000 -type f`)
- [ ] Symlinks pointing outside webroot

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Docker_Security_Cheat_Sheet.md

### Uprawnienia plików — zasady

| Zasada | Opis |
|--------|------|
| Least Privilege | Pliki webowe: odczyt tylko dla procesu serwera, nie `777` |
| Separation of Duties | Użytkownik serwera web ≠ właściciel plików |
| No Execute on Uploads | Katalog uploadów: brak prawa execute, brak interpretacji skryptów |
| Config Files Protected | `.env`, `config.php`: `640` lub `600`, dostęp tylko dla procesu serwera |
| Log Files | Logi: append-only, niedostępne przez HTTP |

### Typowe uprawnienia Linux — web server

| Zasób | Uprawnienia | Właściciel |
|-------|-------------|------------|
| Pliki PHP/Python/Ruby | `644` (rw-r--r--) | root:www-data |
| Katalogi aplikacji | `755` (rwxr-xr-x) | root:www-data |
| Pliki konfiguracyjne | `640` (rw-r-----) | root:www-data |
| Katalog uploadów | `750` (rwxr-x---) | www-data:www-data |
| Klucze prywatne/SSL | `600` (rw-------) | root:root |
| Logi aplikacji | `640` (rw-r-----) | www-data:adm |

### Pliki wrażliwe — co chronić

- **`.env`** — credentials, klucze API, connection strings
- **`.git/`** — pełne repozytorium kodu (git checkout pozwala odtworzyć pliki)
- **`wp-config.php`**, **`config.php`** — dane do bazy danych
- **`.htpasswd`** — hashe haseł
- **`id_rsa`**, **`*.pem`**, **`*.key`** — klucze prywatne
- **`*.sql`**, **`*.db`** — dumpy baz danych
- **`debug.log`**, **`error.log`** — mogą zawierać tokeny, stack traces

### Konfiguracja serwera — blokowanie dostępu

**Apache:**
```
<FilesMatch "^\.">
    Require all denied
</FilesMatch>
<DirectoryMatch "/\.git">
    Require all denied
</DirectoryMatch>
```

**Nginx:**
```
location ~ /\. { deny all; }
location ~ /\.git { deny all; }
```

### Directory listing — wyłączenie

| Serwer | Konfiguracja |
|--------|-------------|
| Apache | `Options -Indexes` |
| Nginx | `autoindex off;` (domyślnie wyłączony) |
| IIS | Usuń "Directory Browsing" z Feature Delegation |

### Obrona

- Regularnie skanuj webroot: `find /var/www -perm -o+w -type f` (pliki world-writable)
- Ustaw `umask 027` dla procesu serwera web
- Nie przechowuj kluczy, haseł, certyfikatów w katalogu webowym
- Użyj `.gitignore` aby nie commitować `.env`, `*.key`, `*.pem`
- Monitoruj zmiany plików konfiguracyjnych (AIDE, Tripwire, OSSEC)

## Pentesterskie deep dive

### Mniej znane techniki

- **Race condition w upload**: jeśli plik jest weryfikowany po upload, ale przed move do final dir, atakujący może w okno czasowe wykonać go (Time-of-check vs Time-of-use - TOCTOU).
- **Symlink attack**: jeśli upload directory pozwala na symlinki, atakujący uploaduje symlink do `/etc/passwd` → następnie GET na uploaded path zwraca passwd content.
- **PHP `auto_prepend_file` via upload**: Apache + PHP misconfig może wykonać `<?php` z dowolnego pliku w katalogu jako prefix do PHP requestów.
- **SUID web shell**: po RCE dropping suid binary jako www-data → privilege escalation gdy atakujący ma local access.
- **Setgid directory permission inheritance**: katalog z setgid bit nadaje wszystkim plikom group ownership = często użyte do ataku gdzie www-data dziedziczy z innej grupy.

### Common pitfalls

- **777 na uploads "for convenience"**: typowy junior fix gdy upload nie działa. Zostawia executable PHP files possibility.
- **Process running as root**: `ps aux | grep -v grep | grep ^root.*nginx` — root-owned web server = privilege escalation łatwiejsze przy RCE.
- **Container default user = root**: Docker containers domyślnie uruchamiają jako root chyba że `USER` directive w Dockerfile.

### Świeżynki z research

- **Container escape via shared file permissions** — community pattern; jeśli host volume mounted z 777 + container running as root, można pisać na host.
- **Kubernetes RunAsNonRoot bypass** — config error w pod spec.
- **HackTricks Privilege Escalation Linux**: https://book.hacktricks.xyz/linux-hardening/privilege-escalation

## Rozszerzenia Burp Suite

Brak dedykowanych rozszerzeń — test wykonywany lokalnie po RCE.

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/09-Test_File_Permission
- HackTricks Linux Privilege Escalation: https://book.hacktricks.xyz/linux-hardening/privilege-escalation
- OWASP Docker Security: https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html
- Linux Capabilities: https://man7.org/linux/man-pages/man7/capabilities.7.html

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.1.4 | Configuration (L2) | App processes run with least privilege. |
| V12.4.1 | File Upload (L1) | Uploaded files not stored in web root. |
| V14.4.5 | Configuration (L1) | File integrity verification. |
