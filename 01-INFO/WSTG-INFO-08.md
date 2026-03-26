# WSTG-INFO-08 — Fingerprint Web Application Framework

## Cele

- Fingerprint components used by the web app (frameworks, libraries)
- Identify CMS, web framework, JavaScript libraries and their versions
- Use identified technology stack to search for known vulnerabilities

## KOMENDY

### WhatWeb - identyfikacja technologii

```bash
whatweb https://TARGET -v -a 3 | tee output_whatweb.txt
whatweb https://TARGET --log-verbose=output_whatweb_verbose.txt

```

### cURL - analiza naglowkow

```bash
curl -sI https://TARGET | tee output_headers.txt
curl -sI https://TARGET | grep -iE "^(X-Powered-By|X-Generator|X-AspNet|X-Drupal|X-Joomla|X-WordPress|Server|Set-Cookie):"

```

### Szukanie tagow META generator

```bash
curl -s https://TARGET | grep -iE "meta.*generator" | tee output_generator.txt

```

### Nmap - skrypty identyfikacji

```bash
nmap --script http-generator -p 80,443 TARGET -oN output_nmap_generator.txt
nmap --script http-headers -p 80,443 TARGET -oN output_nmap_headers.txt
nmap --script http-favicon -p 80,443 TARGET -oN output_nmap_favicon.txt
nmap --script http-enum -p 80,443 TARGET -oN output_nmap_enum.txt

```

### Nuclei - szablony technologii

```bash
nuclei -u https://TARGET -tags tech -o output_nuclei_tech.txt
nuclei -u https://TARGET -t technologies/ -o output_nuclei_technologies.txt

```

### BuiltWith - z linii polecen (jesli dostepny)

```bash
curl -s "https://api.builtwith.com/free1/api.json?KEY=YOUR_API_KEY&LOOKUP=TARGET"

```

### Sprawdzenie typowych sciezek frameworkow

```bash
# WordPress
curl -sI https://TARGET/wp-login.php | head -1
curl -sI https://TARGET/wp-admin/ | head -1
curl -s https://TARGET/wp-includes/js/jquery/jquery.js | head -5

# Joomla
curl -sI https://TARGET/administrator/ | head -1
curl -s https://TARGET/language/en-GB/en-GB.xml | head -10

# Drupal
curl -sI https://TARGET/user/login | head -1
curl -s https://TARGET/CHANGELOG.txt | head -10

# Laravel
curl -sI https://TARGET | grep -i "laravel"

# Django
curl -sI https://TARGET | grep -i "django\|csrftoken"

```

### Analiza cookies

```bash
curl -sI https://TARGET | grep -iE "^Set-Cookie:" | tee output_cookies_analysis.txt
# PHPSESSID = PHP, JSESSIONID = Java, ASP.NET_SessionId = .NET, laravel_session = Laravel

```

### Analiza favicon hash

```bash
curl -s https://TARGET/favicon.ico | md5sum

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - narzedzia maja wbudowane sygnatury
# WhatWeb, Nmap, Nuclei uzywaja wlasnych baz danych technologii

# Opcjonalnie - fuzzowanie sciezek specyficznych dla CMS
```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/cms/wordpress.txt -mc 200,301,302 -o output_ffuf_wordpress.json
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/cms/drupal_plugins.txt -mc 200,301,302 -o output_ffuf_drupal.json
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/cms/joomla_plugins.txt -mc 200,301,302 -o output_ffuf_joomla.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zainstaluj rozszerzenie Wappalyzer w przegladarce - automatyczna detekcja technologii
2. Sprawdz kod zrodlowy strony (Ctrl+U) - szukaj identyfikatorow frameworka
3. Przeanalizuj sciezki URL - czy wskazuja na konkretny framework
4. Sprawdz cookies - nazwy zdradzaja technologie (PHPSESSID, JSESSIONID, etc.)
5. Sprawdz naglowki HTTP w DevTools > Network > wybierz request > Headers
6. Przeanalizuj struktury katalogow (wp-content, sites/default, vendor, etc.)
7. Sprawdz strony bledow - czesto zdradzaja framework i wersje
8. Porownaj domyslne pliki frameworkow z tym co jest na serwerze


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Third_Party_Javascript_Management_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Identyfikacja frameworka — sygnatury

| Framework/CMS | Sygnatury |
|--------------|-----------|
| WordPress | Cookie: `wordpress_`, sciezka `/wp-content/`, `/wp-includes/`, meta generator |
| Joomla | Cookie: `joomla_`, sciezka `/administrator/`, `/components/` |
| Drupal | Naglowek `X-Drupal-Cache`, `/sites/default/files/`, `Drupal.settings` w JS |
| Laravel | Cookie: `laravel_session`, `XSRF-TOKEN`, naglowek `X-Powered-By: PHP` |
| Django | Cookie: `csrftoken`, `sessionid`, strona admin `/admin/` |
| Spring Boot | Sciezki `/actuator/`, cookie `JSESSIONID` |
| ASP.NET | Cookie: `ASP.NET_SessionId`, naglowek `X-AspNet-Version`, ViewState |
| Express.js | Naglowek `X-Powered-By: Express` (jesli nie wylaczony) |
| Ruby on Rails | Cookie: `_session_id`, naglowek `X-Runtime` |
| Next.js | Naglowek `X-Powered-By: Next.js`, sciezka `/_next/` |

### Cookie names → technologia

| Cookie | Technologia |
|--------|------------|
| `PHPSESSID` | PHP |
| `JSESSIONID` | Java (Tomcat, JBoss, Jetty) |
| `ASP.NET_SessionId` | ASP.NET |
| `connect.sid` | Node.js (Express) |
| `laravel_session` | Laravel (PHP) |
| `csrftoken` + `sessionid` | Django (Python) |
| `_rails_session` | Ruby on Rails |
| `CFID` + `CFTOKEN` | ColdFusion |

### JavaScript libraries — wykrywanie wersji

- Sprawdz w DevTools Console: `jQuery.fn.jquery`, `angular.version`, `React.version`
- Retire.js: automatyczne wykrywanie podatnych wersji bibliotek JS
- SRI (Subresource Integrity): sprawdz czy `<script>` uzywa atrybutu `integrity`
- Znane podatne wersje: jQuery < 3.5.0 (XSS), Angular.js 1.x (sandbox escape), Lodash < 4.17.21 (prototype pollution)

### CMS version detection — techniki

| CMS | Jak sprawdzic wersje |
|-----|---------------------|
| WordPress | `/wp-links-opml.php`, `/feed/`, meta generator, `/readme.html` |
| Joomla | `/language/en-GB/en-GB.xml`, `/administrator/manifests/files/joomla.xml` |
| Drupal | `/CHANGELOG.txt`, `/core/install.php`, naglowek `X-Generator` |
| Magento | `/magento_version`, `/RELEASE_NOTES.txt` |

### Obrona

- Usun meta tagi `generator` ujawniajace CMS i wersje
- Aktualizuj framework i wszystkie biblioteki JS do najnowszych wersji
- Uzyj SRI (Subresource Integrity) dla zewnetrznych skryptow JS
- Monitoruj CVE dla uzywanych technologii (Snyk, Dependabot, npm audit)
- Usun domyslne pliki frameworka ujawniajace wersje (CHANGELOG, README, VERSION)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Software Version Reporter | Pasywne wykrywanie wersji oprogramowania serwera | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Burp Retire JS | Identyfikacja podatnych wersji bibliotek JavaScript | [GitHub](https://github.com/h3xstream/burp-retire-js) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V15.2.3 | Security Architecture and Dependencies | Verify that the production environment only includes functionality that is required for the application to function, and does not expose extraneous functionality such as test code, sample snippets, and development functionality. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Unintended Information Leakage | Verify that the application does not expose detailed version information of backend components. |
