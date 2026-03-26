# WSTG-CONF-02 — Test Application Platform Configuration

## Cele

- Ensure defaults removed, no debug code in production, review logging
- Identify default pages, sample applications, and debug interfaces
- Test for improper error handling and verbose error messages

## KOMENDY

### Nikto - wykrywanie domyslnych stron i konfiguracji

```bash
nikto -h https://TARGET -o output_nikto.txt -Format txt
nikto -h https://TARGET -Tuning 4 -o output_nikto_info_disclosure.txt

```

### Nuclei - szablony misconfiguration

```bash
nuclei -u https://TARGET -tags misconfiguration -o output_nuclei_misconfig.txt
nuclei -u https://TARGET -tags config -o output_nuclei_config.txt
nuclei -u https://TARGET -t misconfiguration/ -o output_nuclei_misconfig2.txt

```

### Sprawdzenie domyslnych stron

```bash
curl -sI https://TARGET/server-status | head -1
curl -sI https://TARGET/server-info | head -1
curl -sI https://TARGET/.htaccess | head -1
curl -sI https://TARGET/web.config | head -1
curl -sI https://TARGET/phpinfo.php | head -1
curl -sI https://TARGET/info.php | head -1
curl -sI https://TARGET/test.php | head -1
curl -sI https://TARGET/elmah.axd | head -1
curl -sI https://TARGET/trace.axd | head -1

```

### Sprawdzenie debug mode

```bash
curl -sI https://TARGET | grep -iE "^(X-Debug|X-Debug-Token|X-Powered-By):"
curl -s https://TARGET/actuator | tee output_actuator.txt
curl -s https://TARGET/actuator/health | tee output_actuator_health.txt
curl -s https://TARGET/actuator/env | tee output_actuator_env.txt
curl -s https://TARGET/_debug | tee output_debug.txt
curl -s https://TARGET/debug | tee output_debug2.txt

```

### Sprawdzenie stron bledow

```bash
curl -s https://TARGET/nonexistent_12345 | tee output_404_page.txt
curl -s "https://TARGET/index.php?id='" | tee output_error_sqli.txt

```

### Sprawdzenie domyslnych aplikacji serwerowych

```bash
# Apache Tomcat
curl -sI https://TARGET:8080/manager/html | head -5
curl -sI https://TARGET/examples/ | head -1
# JBoss
curl -sI https://TARGET/jmx-console/ | head -1
curl -sI https://TARGET/web-console/ | head -1
# WebLogic
curl -sI https://TARGET/console/ | head -1
# IIS
curl -sI https://TARGET/iisstart.htm | head -1

```

### Sprawdzenie logowania

```bash
curl -sI https://TARGET | grep -iE "^(X-Request-ID|X-Correlation-ID|X-Trace):"

```

## KOMENDY Z WORDLISTAMI

### Fuzzowanie domyslnych sciezek

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/default-web-root-directory-linux.txt -mc 200,301,302,403 -o output_ffuf_default_linux.json

ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/default-web-root-directory-windows.txt -mc 200,301,302,403 -o output_ffuf_default_windows.json

```

### Fuzzowanie predictable filepaths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/KitchensinkDirectories.txt -mc 200,301,302,403 -o output_ffuf_kitchensink.json

```

### Apache Tomcat predictable paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/webservers-appservers/ApacheTomcat.txt -mc 200,301,302,403 -o output_ffuf_tomcat.json

```

### JBoss predictable paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/webservers-appservers/JBoss.txt -mc 200,301,302,403 -o output_ffuf_jboss.json

```

### Weblogic predictable paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/webservers-appservers/Weblogic.txt -mc 200,301,302,403 -o output_ffuf_weblogic.json

```

### IIS predictable paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/webservers-appservers/IIS.txt -mc 200,301,302,403 -o output_ffuf_iis.json

```

### Apache predictable paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/webservers-appservers/Apache.txt -mc 200,301,302,403 -o output_ffuf_apache.json

```

### ColdFusion predictable paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/discovery/predictable-filepaths/webservers-appservers/ColdFusion.txt -mc 200,301,302,403 -o output_ffuf_coldfusion.json

```

### Szukanie plikow konfiguracyjnych

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/config.txt -mc 200 -o output_ffuf_config.json

```

### CVE paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/cve-paths.txt -mc 200,301,302 -o output_ffuf_cve.json

```

### Juicy paths

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/juicy-paths.txt -mc 200,301,302 -o output_ffuf_juicy.json

```

### Leaky misconfigs

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/leaky-misconfigs.txt -mc 200 -o output_ffuf_leaky.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz domyslne strony serwera (Apache default, IIS welcome, Tomcat manager)
2. Szukaj stron debug/test/info (phpinfo.php, test.php, info.php)
3. Sprawdz odpowiedzi na bledy - czy ujawniaja sciezki, wersje, stack traces
4. Sprawdz czy Spring Boot Actuator endpoints sa dostepne
5. Zweryfikuj czy sample applications zostaly usuniete
6. Sprawdz logi dostepne przez HTTP (access.log, error.log)
7. Przetestuj verbose error messages wysylajac zle sformatowane dane
8. Sprawdz czy tryb debug jest wylaczony w produkcji


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Error_Handling_Cheat_Sheet.md, Logging_Cheat_Sheet.md

### Konfiguracja platformy aplikacyjnej — checklist

- **Debug mode OFF** na produkcji — Django: `DEBUG=False`, Rails: `config.consider_all_requests_local=false`
- **Verbose errors OFF** — nie pokazuj stack traces, sciezek plikow, zapytan SQL
- Usun **sample apps** i **default pages** (Tomcat: /examples, IIS: /iisstart.htm, Apache: /manual)
- Usun **domyslne konta**: Tomcat manager (admin/admin), Jenkins (admin), phpMyAdmin (root bez hasla)
- Zweryfikuj **error pages**: custom 404/500 bez informacji technicznych

### Konfiguracja per technologia

| Technologia | Kluczowe ustawienia |
|-------------|-------------------|
| Apache | `ServerTokens Prod`, `ServerSignature Off`, usun `/manual`, `/icons` |
| Nginx | `server_tokens off`, usun domyslna strone |
| IIS | Usun default pages, wylacz detailed errors, usun `.aspx` traceback |
| Tomcat | Usun `/manager`, `/host-manager`, `/examples`, zmien domyslne credentials |
| PHP | `display_errors=Off`, `expose_php=Off`, `error_reporting=E_ALL` (do logow) |
| Django | `DEBUG=False`, `ALLOWED_HOSTS` ustawione, custom error handlers |
| Spring | `server.error.include-stacktrace=never`, actuator zabezpieczony |
| Node.js | `NODE_ENV=production`, nie ujawniaj stack traces w API |

### Logging — bezpieczne

- Loguj **wlasciwosci bezpieczenstwa**: login, logout, zmiana hasla, bledy autoryzacji
- **NIE loguj**: hasel, tokenow, kluczy API, danych PII, numerow kart
- Centralizuj logi: ELK, Splunk, Graylog — nie tylko lokalne pliki
- Chron logi przed modyfikacja: osobne konto, append-only, integrity monitoring

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| J2EEScan | Skaner podatnosci specyficznych dla aplikacji J2EE | [GitHub](https://github.com/ilmila/J2EEScan) |
| Software Version Reporter | Pasywne wykrywanie wersji oprogramowania | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.2 | Unintended Information Leakage | Verify that debug modes are disabled for all components in production environments to prevent exposure of debugging features and information leakage. |
| V13.4.3 | Unintended Information Leakage | Verify that web servers do not expose directory listings to clients unless explicitly intended. |
| V15.2.3 | Security Architecture and Dependencies | Verify that the production environment only includes functionality that is required for the application to function, and does not expose extraneous functionality such as test code, sample snippets, and development functionality. |
