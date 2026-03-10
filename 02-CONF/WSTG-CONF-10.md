# WSTG-CONF-10 — Test for Subdomain Takeover

## Cele

- Enumerate domains and identify forgotten or misconfigured subdomains
- Detect dangling DNS records pointing to unclaimed services
- Test for subdomain takeover vulnerability

## KOMENDY

### Enumeracja subdomen

```bash
subfinder -d TARGET -o output_subfinder.txt
amass enum -passive -d TARGET -o output_amass.txt
assetfinder --subs-only TARGET | tee output_assetfinder.txt

```

### Sprawdzenie CNAME records

```bash
cat output_subfinder.txt | while read sub; do echo "$sub: $(dig CNAME +short $sub)"; done | tee output_cnames.txt

```

### Subjack - automatyczny test subdomain takeover

```bash
subjack -w output_subfinder.txt -t 100 -timeout 30 -ssl -c /usr/share/subjack/fingerprints.json -v -o output_subjack.txt

```

### Nuclei - szablony subdomain takeover

```bash
nuclei -l output_subfinder.txt -t takeovers/ -o output_nuclei_takeover.txt
nuclei -l output_subfinder.txt -tags takeover -o output_nuclei_takeover2.txt

```

### dig CNAME - reczne sprawdzenie

```bash
dig CNAME subdomain.TARGET +short
dig CNAME www.TARGET +short
dig CNAME mail.TARGET +short
dig CNAME blog.TARGET +short
dig CNAME shop.TARGET +short
dig CNAME dev.TARGET +short
dig CNAME staging.TARGET +short

```

### DNSRecon

```bash
dnsrecon -d TARGET -t std -o output_dnsrecon.txt

```

### Sprawdzenie czy CNAME prowadzi do nieistniejacego zasobu

```bash
# Znaki subdomain takeover:
# - NXDOMAIN na CNAME target
# - "There isn't a GitHub Pages site here"
# - "NoSuchBucket" (AWS S3)
# - "The specified bucket does not exist" (AWS S3)
# - "No settings were found for this company" (HelpScout)
# - "Domain is not configured" (Fastly)

```

### Sprawdzenie CNAME i odpowiedzi HTTP

```bash
cat output_subfinder.txt | httpx -follow-redirects -status-code -title -content-length -o output_httpx.txt

```

### can-i-take-over-xyz checks

```bash
# Sprawdz https://github.com/EdOverflow/can-i-take-over-xyz dla aktualnej listy

```

## KOMENDY Z WORDLISTAMI

### SecLists subdomains brute-force

```bash
gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-5000.txt -o output_gobuster_dns_5k.txt

gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-20000.txt -o output_gobuster_dns_20k.txt

gobuster dns -d TARGET -w Desktop/WSTG/SecLists-master/Discovery/DNS/subdomains-top1million-110000.txt -o output_gobuster_dns_110k.txt

```

### Wynik gobuster -> sprawdzenie CNAME

```bash
cat output_gobuster_dns_5k.txt | awk '{print $2}' | while read sub; do cname=$(dig CNAME +short $sub); if [ ! -z "$cname" ]; then echo "$sub -> $cname"; fi; done | tee output_cname_check.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zebierz liste subdomen za pomoca wielu narzedzi
2. Sprawdz CNAME dla kazdej subdomeny - szukaj dangling records
3. Odwiedz kazda subdomene w przegladarce - szukaj stron bledow uslug (GitHub Pages, AWS, Heroku)
4. Sprawdz czy mozesz zarejestrowac/claim usluge wskazywana przez CNAME
5. Zweryfikuj na can-i-take-over-xyz czy dana usluga jest podatna na takeover
6. Sprawdz NS records - czy delegacja DNS prowadzi do kontrolowanego serwera
7. Przetestuj rejestracje na platformach wskazywanych przez CNAME (S3, Heroku, GitHub)
8. Dokumentuj wszystkie znalezione dangling DNS records


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md

### Subdomain takeover — mechanizm

1. Organizacja tworzy CNAME: `blog.target.com → target.herokuapp.com`
2. Organizacja kasuje konto na Heroku, ale **nie usuwa rekordu CNAME**
3. Atakujacy rejestruje `target.herokuapp.com` na swoim koncie Heroku
4. `blog.target.com` teraz serwuje tresc atakujacego — moze krasc cookies, phishing

### Uslugi podatne na subdomain takeover

| Usluga | Sygnatura (error message) | Podatna? |
|--------|--------------------------|----------|
| GitHub Pages | "There isn't a GitHub Pages site here" | Tak |
| AWS S3 | "NoSuchBucket", "The specified bucket does not exist" | Tak |
| Heroku | "No such app" | Tak |
| Azure (App Service) | Domyslna strona Azure | Tak (zalezy od konfiguracji) |
| Shopify | "Sorry, this shop is currently unavailable" | Tak |
| Fastly | "Fastly error: unknown domain" | Tak |
| Pantheon | "404 error unknown site" | Tak |
| Tumblr | "There's nothing here" + Tumblr branding | Tak |
| WordPress.com | "Do you want to register" | Tak |
| Ghost | "The thing you were looking for is no longer here" | Tak |
| Surge.sh | "project not found" | Tak |
| Cloudfront | "Bad Request: ERROR: The request could not be satisfied" | Mozliwa |

### Typy dangling DNS records

| Typ rekordu | Ryzyko |
|-------------|--------|
| CNAME → wycofana usluga | Subdomain takeover — najczestszy |
| A/AAAA → zwolniony IP | IP moze byc przejety przez innego uzytkownika chmury |
| NS → wycofany nameserver | Pelna kontrola nad subdomena (DNS takeover) |
| MX → wycofany mail server | Przechwycenie maili — password reset, weryfikacja |

### Konsekwencje subdomain takeover

- **Cookie stealing**: jesli cookie scope to `.target.com`, atakujacy moze krasc sesje
- **Phishing**: legitymna subdomena target.com z trescia atakujacego
- **CSP bypass**: jesli CSP zezwala na `*.target.com`
- **OAuth/SAML bypass**: jesli redirect_uri akceptuje subdomeny
- **Email spoofing**: jesli SPF zawiera `include:` dla przejętej domeny

### Obrona

- **Usuwaj rekordy DNS** przed usunieciem uslugi/zasobu — nie odwrotnie
- Regularnie skanuj subdomeny i sprawdzaj CNAME pod katem dangling records
- Uzyj **DNS monitoring** do alertowania o zmianach rekordow
- Scope cookies do konkretnej subdomeny (`blog.target.com`), nie `.target.com`
- Zminimalizuj wildcard w CSP i OAuth redirect_uri
- Prowadz **inwentarz subdomen** i ich powiazania z uslugami

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Broken Link Hijacking | Pasywne wykrywanie zepsutych linkow do potencjalnego subdomain takeover | [GitHub](https://github.com/arbazkiraak/BurpBLH) |
| Domain Hunter | Wyszukiwanie powiazanych domen i subdomen | [GitHub](https://github.com/bit4woo/domain_hunter) |
