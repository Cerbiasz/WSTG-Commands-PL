# WSTG-CLNT-08 — Testing for Cross Site Flashing

## Cel

Sprawdzenie czy serwer serwuje pliki SWF (Flash) — Flash Player jest EOL od grudnia 2020. Wszystkie major browsery usunęły wsparcie. Test sprowadza się do: **znajdź SWF na serwerze → usuń**.

> **Test legacy / prawie obsolete**: Flash EOL. Jeśli SWF istnieje, traktować jako misconfig (czysty find, ale nie eksploitowalny w nowoczesnych przeglądarkach). Można skanować `*.swf` files via WSTG-CONF-03 / WSTG-INFO-04.

## Automatyzacja Nuclei

```bash
# Brute-force *.swf files
ffuf -u https://target/FUZZ.swf \
     -w resources/seclists/Discovery/Web-Content/raft-medium-files.txt -mc 200

# WSTG-INFO-04 attack-surface (zawiera search dla legacy assets)
nuclei -l burp-export.xml -im burp -t templates/wstg-info-04-attack-surface.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (3 kroki)

1. **Search SWF files**: brute-force / Wayback Machine / sitemap.
2. **Per SWF found**: Adobe SWF Investigator lub `swfdump` analyze parameters.
3. **Recommendation**: usunięcie SWF z serwera.

### Co MUSI być sprawdzone (5 punktów)

- [ ] `*.swf` files w directory listing
- [ ] Wayback Machine: `gau target.com | grep "\.swf$"`
- [ ] Sitemap.xml
- [ ] HTML embed/object tags z `application/x-shockwave-flash`
- [ ] If found: SWF parameters (flashvars, allowScriptAccess)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP Testing Guide, ogólne zasady bezpieczeństwa

### Flash/SWF — status (2020+)

- **Flash jest EOL od 31 grudnia 2020** — Adobe zakończył wsparcie
- Przeglądarki usunęły wsparcie Flash — Chrome, Firefox, Edge, Safari
- Testowanie Cross Site Flashing jest **legacy** — ale SWF mogą nadal istnieć na serwerach
- Jeśli znajdziesz SWF na serwerze: **usuń go** — nie ma powodu go utrzymywać

### Jeśli SWF nadal istnieje — co sprawdzić

- **ExternalInterface.call()**: może wywołać JavaScript — potencjalny XSS
- **navigateToURL/getURL**: przekierowanie — potencjalny open redirect
- **loadMovie/loadClip**: ładowanie zewnętrznego SWF — content injection
- **flashvars**: parametry z URL — injection point
- **allowScriptAccess**: `always` = pełny dostęp do JS strony hosting

### Obrona

- **Usuń wszystkie pliki SWF** z serwera — Flash jest przestarzały
- Zablokuj MIME type `application/x-shockwave-flash` na serwerze
- Jeśli nie można usunąć: ustaw `allowScriptAccess="never"` i `allowNetworking="none"`

## Pentesterskie deep dive

### Mniej znane techniki

- **SWF history exploitation**: niektóre legacy enterprise apps (banking, government) mają SWF reactivated via Pale Moon/Basilisk browsers. Niche ale istnieje.
- **Ruffle (Flash emulator)**: niektóre stronki używają Ruffle do emulacji SWF — vulnerability w SWF nadal eksploitowalna jeśli atakujący ma user using Ruffle.
- **`crossdomain.xml` legacy**: nawet bez SWF, `crossdomain.xml` może być wciąż serwowany — cross WSTG-CONF-08.

### Common pitfalls

- **SWF nadal w sitemap**: search engines indeksowane stary content — Google cache pokazuje starsze URLs.

### Świeżynki z research

- **Flash EOL announcement**: https://www.adobe.com/products/flashplayer/end-of-life.html
- **HackTricks Old SWF research**: archival reference

## Rozszerzenia Burp Suite

Brak — Flash legacy.

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/08-Testing_for_Cross_Site_Flashing
- Adobe Flash EOL: https://www.adobe.com/products/flashplayer/end-of-life.html

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.2.2 | Dependency (L2) | Removed unneeded features and components. |
