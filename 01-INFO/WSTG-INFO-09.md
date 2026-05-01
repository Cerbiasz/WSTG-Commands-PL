# WSTG-INFO-09 — Fingerprint Web Application

## Cel

Identyfikacja konkretnej wersji aplikacji webowej (np. WordPress 6.2 vs 6.3.1) i jej zależności (paczki npm, composer, gem). Precyzyjna wersja pozwala na CVE matching i ocenę wieku wdrożenia — fundament pivot do ataków targeted.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-info-09-app-version.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-info-09.jsonl
```

Szablon w 6 grupach: generic version files (CHANGELOG/VERSION/readme/RELEASE_NOTES), package manifests (package.json, composer.json, Gemfile.lock, requirements.txt, pom.xml, build.gradle, go.mod, Cargo.toml), WordPress version (wp-links-opml.php, version.php, feed generator), Drupal CHANGELOG, Joomla manifest XML, Magento RELEASE_NOTES.

### Dodatkowe oficjalne szablony Nuclei

```bash
# Specyficzne CMS detect + version
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/technologies/wordpress-detect.yaml \
       -t resources/nuclei-templates/http/technologies/joomla-detect.yaml \
       -t resources/nuclei-templates/http/technologies/drupal-detect.yaml

# CVE templates - po identyfikacji wersji uruchom CVE checki
nuclei -l burp-export.xml -im burp \
       -tags wordpress,cve

# Exposed package files
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/http/exposures/files/package-json.yaml \
       -t resources/nuclei-templates/http/exposures/files/composer-json.yaml \
       -t resources/nuclei-templates/http/exposures/files/gemfile.yaml
```

### Suplementarne narzędzia

```bash
# WordPress: pełna wersja + wszystkie pluginy + użytkownicy
wpscan --url https://target --enumerate u,vp,vt,cb --api-token <token>

# Drupal
droopescan scan drupal -u https://target

# Joomla
joomscan -u https://target

# Generic CMS
cmseek -u https://target

# JS dependency vulnerabilities
retire --jspath ./js-bundles/
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Generic version files (CHANGELOG/VERSION/readme) | ✓ | — |
| Node package.json + lock | ✓ | — |
| PHP composer.json + lock | ✓ | — |
| Ruby Gemfile + lock | ✓ | — |
| Python requirements/Pipfile/poetry | ✓ | — |
| Java pom.xml / build.gradle | ✓ | — |
| Go go.mod / go.sum | ✓ | — |
| Rust Cargo.toml / lock | ✓ | — |
| WordPress version | ✓ | pluginy/themes — wpscan |
| Drupal version | ✓ | moduły — droopescan |
| Joomla version | ✓ | komponenty — joomscan |
| Magento version | ✓ | extensions — manual |
| Ghost / October / Statamic | — | nuclei tech templates |
| Plugin / theme version detection | — | wpscan, joomscan, droopescan |
| JS library vuln matching | — | Retire.js, Snyk |
| Container layer vuln (Trivy) | — | poza zakresem web |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Generic file pull**: CHANGELOG.txt, VERSION, readme.html, RELEASE_NOTES.txt — często zostają po deploy.
2. **Manifest pull**: package.json (wraz z `dependencies` i wersjami), composer.json/lock, Gemfile.lock, requirements.txt — pełna lista zależności i ich wersji.
3. **CMS-specific paths**: dla WordPress `wp-links-opml.php` + `?feed=rss2` (generator XML); dla Drupal `core/CHANGELOG.txt`; dla Joomla `administrator/manifests/files/joomla.xml`.
4. **Static asset hashing**: hash CSS/JS plików (`/wp-content/plugins/<name>/main.css`) + porównaj z baza znanych wersji. Niektóre pluginy nie mają jawnej wersji, ale assets różnią się.
5. **CMS-specific scanner**: po identyfikacji uruchom dedicated tool (wpscan, joomscan, droopescan).
6. **CVE matching**: gdy wersja precyzyjna, sprawdź NVD, Snyk, Vulners, GitHub Advisories.

### Co MUSI być sprawdzone (12 punktów)

- [ ] CHANGELOG.txt / CHANGELOG.md / CHANGES / VERSION pulled
- [ ] readme.html / README.md pulled
- [ ] package.json / package-lock.json (Node)
- [ ] composer.json / composer.lock (PHP)
- [ ] Gemfile / Gemfile.lock (Ruby)
- [ ] requirements.txt / Pipfile (Python)
- [ ] pom.xml / build.gradle (Java)
- [ ] CMS specific: WP `wp-links-opml.php`, Drupal `core/CHANGELOG.txt`, Joomla `joomla.xml`, Magento `magento_version`
- [ ] Meta `<meta name="generator">` content
- [ ] RSS/Atom `<generator>` element
- [ ] Po identyfikacji: dedicated scanner (wpscan / joomscan / droopescan)
- [ ] CVE matching: NVD / Snyk / GitHub Advisories dla zidentyfikowanej wersji

### Per stack — gdzie szukać precyzyjnej wersji

| Stack | Najlepsza ścieżka | Format |
|---|---|---|
| WordPress | `?feed=rss2` → `<generator>https://wordpress.org/?v=6.2.2</generator>` | precyzyjne X.Y.Z |
| Drupal | `core/CHANGELOG.txt` (D9+) lub `CHANGELOG.txt` (D7) | "Drupal 9.5.10, 2023-08-16" |
| Joomla | `administrator/manifests/files/joomla.xml` | `<version>4.3.4</version>` |
| Magento | `magento_version` endpoint | "Magento/2.4.6" |
| Spring Boot | `/actuator/info` (jeśli enabled) | JSON z `git.commit.id`, `build.version` |
| Laravel | `/composer.json` jeśli leak (rzadko) | "laravel/framework": "^10.0" |
| Django | `pip freeze` z `requirements.txt` exposure | "Django==4.2.5" |
| Rails | `Gemfile.lock` | "rails (7.0.8)" |
| Express | `package.json` | "express": "^4.18.2" |
| Next.js | `package.json` lub `__NEXT_DATA__` buildId | hash buildId pivot do version |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Vulnerable_Dependency_Management_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Identyfikacja wersji aplikacji — techniki

| Technika | Opis | Niezawodność |
|----------|------|-------------|
| Meta generator tag | `<meta name="generator" content="WordPress 6.2">` | Wysoka (jeśli nie usunięte) |
| Pliki wersji | `/CHANGELOG.txt`, `/VERSION`, `/readme.html` | Wysoka |
| RSS/Atom feed | `<generator>` w feedzie | Średnia |
| Hash plików statycznych | MD5 CSS/JS vs baza referencyjnych hashów | Wysoka |
| Error pages | Stack trace, domyślne strony błędów | Średnia |
| HTTP headers | `X-Generator`, `X-Powered-By` | Średnia (może być sfałszowane) |
| Favicon hash | Hash favicony → identyfikacja technologii | Niska-średnia |
| URL patterns | Struktura URL specyficzna dla aplikacji | Średnia |

### Off-the-shelf vs custom application

| Cecha | Off-the-shelf (CMS, framework) | Custom application |
|-------|-------------------------------|-------------------|
| Identyfikacja | Łatwa — znane sygnatury | Trudna — brak publicznych sygnatur |
| CVE search | Możliwy po ustaleniu wersji | Nie dotyczy |
| Testowanie | Znane podatności + konfiguracja | Pełny pentest wymagany |
| Exploit availability | Publiczne exploity (Metasploit, ExploitDB) | Brak — wymaga własnego development |

### Po identyfikacji wersji — następne kroki

1. **Szukaj CVE**: `searchsploit wordpress 6.2`, NVD, Vulners, Snyk DB
2. **Sprawdź ExploitDB**: `searchsploit -m <exploit_id>` — gotowe exploity
3. **Nuclei templates**: `nuclei -u target -tags cve` — automatyczne testowanie
4. **Porównaj z latest**: czy wersja jest aktualna? ile wersji za najnowszą?
5. **Sprawdź pluginy/moduły**: WPScan, JoomScan — podatności w dodatkach

### Baza wersji — narzędzia

| Narzędzie | Użycie |
|-----------|--------|
| WPScan | `wpscan --url target` — WordPress (wersja, pluginy, tematy, użytkownicy) |
| JoomScan | `joomscan -u target` — Joomla |
| Droopescan | `droopescan scan drupal -u target` — Drupal |
| CMSeek | `cmseek -u target` — uniwersalny CMS scanner |
| retire.js | Podatne wersje bibliotek JS |

### Obrona

- **Aktualizuj regularnie** — większości exploitów dotyczy starych wersji
- Usuń pliki ujawniające wersje: `CHANGELOG.txt`, `readme.html`, `VERSION`
- Usuń lub zmień meta tag `generator`
- Wdróż **patch management process** — testuj i wdrażaj aktualizacje bezpieczeństwa
- Monitoruj advisories bezpieczeństwa dla używanych technologii
- Użyj WAF jako tymczasową ochronę (virtual patching) przed wdrożeniem aktualizacji

## Pentesterskie deep dive

### Mniej znane techniki

- **JS dependency tree leak via package-lock.json**: `package-lock.json` zawiera pełne drzewo zależności z transitive deps i wersjami. Dla każdego znalezionego deps można sprawdzić CVE — często znajdują się stare wersje deep-nested z lukami.
- **Git commit hash via `__NEXT_DATA__`**: Next.js `buildId` jest deterministycznym hash. Przy odpowiednim mapowaniu z public Next.js examples → konkretna wersja Next.js + node + commit timing.
- **Static asset versioning**: `/wp-content/plugins/akismet/_inc/akismet.js?ver=4.2.1` — query string `?ver=` z wersją plugina (klasyczny WP wzorzec).
- **CHANGELOG.txt with dates**: `Drupal 9.5.10, 2023-08-16` — jeśli wiek wdrożenia > 90 dni, prawdopodobnie wszystkie znane CVE z tego okresu są niepatched.
- **`/wp-cron.php` POSIX time leak**: WordPress `wp-cron` zwraca timing data — można pivotować do server timing fingerprint.
- **Composer audit chain**: `composer.lock` jest publicly serwowany w `/composer.lock` (Apache/Nginx default mime). Lock pliki mają hashe per package + version.

### Common pitfalls

- **Hardening usuwa typowe wersje**: dobrze zhardenowany WP nie zwraca generator meta ani wp-links-opml. Pivot przez static asset hashing lub plugin enumeration.
- **Beta/RC wersje nie mają CVE**: `WordPress 6.4-RC1` może być vulnerable na lukę z 6.3, ale CVE database nie zawiera RC tagów. Manual checking.
- **Deps z aliasami**: `package.json` może deklarować `"my-foo": "npm:foo@1.2.3"` — alias sprawia że standardowe scanner mogą nie sprawdzić właściwego pakietu.
- **WAF flagujący `/CHANGELOG.txt`**: Cloudflare i AWS WAF mają reguły blokujące popularne version files. Bypass przez encoding (`/CHANGELOG.txt%00`, `/CHANGELOG.txt?cb=1`).
- **Reverse-proxy stripping `?ver=` query param**: niektóre CDN strip query strings → ?ver= disappear z public URLs ale wciąż serwowane przez backend bezpośrednio.

### Świeżynki z research

- **Software supply chain attacks** (community pattern) — wykrycie podatnej wersji deps może pivotować do całego account compromise jeśli deps są re-published z malicious version (Sonatype Nexus reports).
- **`buildId` hash collision attacks** — patterns z research; różne wersje Next.js mogą mieć ten sam buildId hash (rare ale możliwe).
- **Plugin/theme version `Trust on First Use`** — community pattern; gdy WP plugin nie ma jawnej wersji w manifest, atakujący zgaduje przez asset hashes.
- **Composer.lock SHA256 mismatch** — weryfikacja czy lock pliki nie zostały sfałszowane (security pattern).
- **PortSwigger Web Security Academy — known vulnerabilities labs**: https://portswigger.net/web-security
- **HackTricks per-CMS sections**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| CMS Scanner | Wykrywanie podatności w popularnych CMS-ach | [BApp Store](https://portswigger.net/bappstore/1bf95d0be40c447b94981f5696b1a18e) |
| Detect Dynamic JS | Porównywanie plików JS w celu wykrycia dynamicznej zawartości | [BApp Store](https://portswigger.net/bappstore/4a657674ebe3410b92280613aa512304) |
| Software Version Reporter | Pasywne wykrywanie wersji w odpowiedziach | [GitHub](https://github.com/augustd/burp-suite-software-version-checks) |
| Burp Retire JS | Identyfikacja podatnych wersji bibliotek JS | [GitHub](https://github.com/h3xstream/burp-retire-js) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/09-Fingerprint_Web_Application
- OWASP Vulnerable Dependency Management: https://cheatsheetseries.owasp.org/cheatsheets/Vulnerable_Dependency_Management_Cheat_Sheet.html
- WPScan: https://wpscan.com/
- JoomScan: https://github.com/OWASP/joomscan
- Droopescan: https://github.com/SamJoan/droopescan
- CMSeek: https://github.com/Tuhinshubhra/CMSeeK
- Retire.js: https://retirejs.github.io/retire.js/
- NVD: https://nvd.nist.gov/
- Snyk Vulnerability DB: https://security.snyk.io/
- GitHub Advisory Database: https://github.com/advisories

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.4.6 | Information Leakage (L3) | No detailed version information of backend components. |
| V14.2.1 | Dependency (L1) | All components are up to date with version, patches, and known vulnerabilities. |
| V14.2.2 | Dependency (L2) | Removed unneeded features, components, dependencies. |
