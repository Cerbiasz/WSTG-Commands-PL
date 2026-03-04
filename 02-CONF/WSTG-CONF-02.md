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

