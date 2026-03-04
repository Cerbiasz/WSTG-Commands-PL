# WSTG-INFO-01 — Conduct Search Engine Discovery Reconnaissance for Information Leakage

## Cele

- Identify what sensitive design and configuration information is exposed directly or indirectly
- Discover leaked documents, configuration files, source code via search engines
- Find exposed admin panels, login pages, error messages indexed by crawlers

## KOMENDY

### Google Dorks - podstawowe operatory

```bash
# Wykonaj recznie w przegladarce lub poprzez Google Custom Search API

site:TARGET
site:TARGET filetype:pdf
site:TARGET filetype:doc OR filetype:docx OR filetype:xls OR filetype:xlsx
site:TARGET filetype:sql OR filetype:bak OR filetype:log
site:TARGET filetype:xml OR filetype:conf OR filetype:env
site:TARGET inurl:admin
site:TARGET inurl:login
site:TARGET intitle:"index of"
site:TARGET intitle:"dashboard"
site:TARGET ext:php intitle:"phpinfo()"
site:TARGET inurl:wp-content
site:TARGET inurl:wp-admin
site:TARGET "error" OR "warning" OR "fatal"
cache:TARGET
site:TARGET inurl:api
site:TARGET inurl:config
site:TARGET filetype:json
site:TARGET filetype:yml OR filetype:yaml

```

### theHarvester - zbieranie emaili, subdomen, hostow

```bash
theHarvester -d TARGET -b google -l 500 -f output_theharvester.html
theHarvester -d TARGET -b bing -l 500 -f output_theharvester_bing.html
theHarvester -d TARGET -b all -l 500 -f output_theharvester_all.html

```

### Shodan CLI - wyszukiwanie informacji o infrastrukturze

```bash
shodan search hostname:TARGET
shodan host TARGET_IP
shodan search "ssl.cert.subject.cn:TARGET"
shodan search "http.title:TARGET"

```

### Amass - pasywne zbieranie informacji

```bash
amass enum -passive -d TARGET -o output_amass_passive.txt

```

### Waybackurls - historyczne URL-e z Wayback Machine

```bash
echo TARGET | waybackurls | tee output_waybackurls.txt
echo TARGET | waybackurls | grep -E "\.(js|json|xml|config|sql|bak|old|log|env)$" | tee output_waybackurls_interesting.txt

```

### GAU (Get All URLs)

```bash
echo TARGET | gau --threads 5 | tee output_gau.txt
echo TARGET | gau --threads 5 --blacklist png,jpg,gif,css,woff,svg | tee output_gau_filtered.txt

```

## KOMENDY Z WORDLISTAMI

### Google Dorks z Bug-Bounty-Wordlists

```bash
# Plik zawiera gotowe dorki Google do wyszukiwania wrażliwych informacji
# Uzyj kazdej linii jako zapytanie Google, podmieniajac domene na TARGET
cat Desktop/WSTG/Bug-Bounty-Wordlists-main/allgoogle.txt
cat Desktop/WSTG/Bug-Bounty-Wordlists-main/all-gitdorks.txt
cat Desktop/WSTG/Bug-Bounty-Wordlists-main/shodan-dorks.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz przegladarke i wykonaj Google dorks recznie (site:TARGET filetype:pdf itp.)
2. Sprawdz wyniki Google cache: dla TARGET
3. Sprawdz Bing, DuckDuckGo, Yandex z analogicznymi zapytaniami
4. Uzyj Google Hacking Database (GHDB) na exploit-db.com/google-hacking-database
5. Sprawdz Shodan (shodan.io) i Censys (search.censys.io) dla TARGET
6. Przejrzyj Wayback Machine (web.archive.org) - historyczne wersje strony
7. Sprawdz GitHub/GitLab czy nie ma wyciekow kodu zrodlowego TARGET
8. Zweryfikuj znalezione pliki i strony pod katem wrazliwych danych

