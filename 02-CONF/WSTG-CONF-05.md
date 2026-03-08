# WSTG-CONF-05 — Enumerate Admin Interfaces

## Cele

- Identify hidden administrator interfaces and management panels
- Find login pages and admin dashboards not linked from the main site
- Test access controls on admin interfaces

## KOMENDY

### ffuf - brute-force paneli admina

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -mc 200,301,302,401,403 -o output_ffuf_common.json

```

### gobuster

```bash
gobuster dir -u https://TARGET -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -o output_gobuster_admin.txt

```

### dirb

```bash
dirb https://TARGET Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -o output_dirb.txt

```

### Nuclei - szablony admin paneli

```bash
nuclei -u https://TARGET -tags panel -o output_nuclei_panels.txt
nuclei -u https://TARGET -tags login -o output_nuclei_login.txt
nuclei -u https://TARGET -tags admin -o output_nuclei_admin.txt

```

### Sprawdzenie typowych paneli admina

```bash
curl -sI https://TARGET/admin | head -1
curl -sI https://TARGET/admin/ | head -1
curl -sI https://TARGET/administrator/ | head -1
curl -sI https://TARGET/admin.php | head -1
curl -sI https://TARGET/admin/login | head -1
curl -sI https://TARGET/wp-admin/ | head -1
curl -sI https://TARGET/wp-login.php | head -1
curl -sI https://TARGET/cpanel | head -1
curl -sI https://TARGET/phpmyadmin/ | head -1
curl -sI https://TARGET/adminer.php | head -1
curl -sI https://TARGET/manager/html | head -1
curl -sI https://TARGET/console/ | head -1
curl -sI https://TARGET/jmx-console/ | head -1
curl -sI https://TARGET/_admin | head -1
curl -sI https://TARGET/backend/ | head -1
curl -sI https://TARGET/dashboard/ | head -1
curl -sI https://TARGET/panel/ | head -1
curl -sI https://TARGET/controlpanel/ | head -1
curl -sI https://TARGET/management/ | head -1

```

### Sprawdzenie na niestandardowych portach

```bash
curl -sI https://TARGET:8080/admin | head -1
curl -sI https://TARGET:8443/admin | head -1
curl -sI https://TARGET:9090/ | head -1
curl -sI https://TARGET:3000/ | head -1

```

### Nmap - enumeracja HTTP

```bash
nmap --script http-enum -p 80,443,8080,8443 TARGET -oN output_nmap_enum.txt

```

## KOMENDY Z WORDLISTAMI

### Bug-Bounty-Wordlists admin

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/admin.txt -mc 200,301,302,401,403 -o output_ffuf_bbw_admin.json

```

### Bug-Bounty-Wordlists adminer

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/adminer.txt -mc 200,301,302 -o output_ffuf_bbw_adminer.json

```

### Bug-Bounty-Wordlists phpmyadmin

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/phpmyadmin.txt -mc 200,301,302 -o output_ffuf_bbw_phpmyadmin.json

```

### Bug-Bounty-Wordlists tomcat

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/tomcat.txt -mc 200,301,302,401,403 -o output_ffuf_bbw_tomcat.json

```

### fuzzdb login file locations

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/login-file-locations/Logins.txt -mc 200,301,302,401 -o output_ffuf_fuzzdb_logins.json

ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/login-file-locations/html.txt -mc 200,301,302,401 -o output_ffuf_fuzzdb_logins_html.json

ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/login-file-locations/php.txt -mc 200,301,302,401 -o output_ffuf_fuzzdb_logins_php.json

```

### SecLists Logins.fuzz

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/Logins.fuzz.txt -mc 200,301,302,401 -o output_ffuf_logins_fuzz.json

```

### Duza wordlista directories

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/raft-large-directories.txt -mc 200,301,302,401,403 -o output_ffuf_raft_dirs.json

```

### Quickhits - szybka lista popularnych sciezek

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/quickhits.txt -mc 200,301,302,401,403 -o output_ffuf_quickhits.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz /admin, /administrator, /wp-admin, /cpanel, /dashboard recznie
2. Szukaj linkow do panelu admina w kodzie zrodlowym i plikach JS
3. Sprawdz robots.txt - czesto ukrywa sciezki administracyjne
4. Przetestuj admin na niestandardowych portach (8080, 8443, 9090)
5. Sprawdz subdomeny: admin.TARGET, panel.TARGET, manage.TARGET
6. W Burp Suite: szukaj odniesien do panelu admina w odpowiedziach
7. Sprawdz czy panel admin jest chroniony (401/403) czy po prostu ukryty
8. Testuj domyslne credentiale na znalezionych panelach


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AdminPanelFinder | Enumeracja interfejsow administracyjnych | [GitHub](https://github.com/moeinfatehi/Admin-Panel_Finder) |
