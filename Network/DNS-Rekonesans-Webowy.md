# DNS -- Rekonesans Aplikacji Webowych

## Kluczowe techniki enumeracji

### Banner Grabbing
```bash
dig version.bind CHAOS TXT @<DNS_IP>
nmap -sV --script dns-nsid -p 53 <IP>
```

### Transfer Strefy (AXFR) -- pelna mapa domen
```bash
dig axfr @<DNS_IP>
dig axfr @<DNS_IP> <DOMAIN>
fierce --domain <DOMAIN> --dns-servers <DNS_IP>
```

### Enumeracja subdomen (brute-force)
```bash
dnsenum --dnsserver <DNS_IP> --enum -p 0 -s 0 -o subdomains.txt -f <WORDLIST> <DOMAIN>
dnsrecon -D subdomains-1000.txt -d <DOMAIN> -n <DNS_IP>
# Rekursywnie:
dnscan -d <domain> -r -w subdomains-1000.txt
```

### Reverse DNS -- odkrywanie wewnetrznych hostow
```bash
dnsrecon -r 127.0.0.0/24 -n <DNS_IP>
dnsrecon -r <IP_DNS>/24 -n <DNS_IP>
```

### Zapytania specjalne
```bash
dig ANY @<DNS_IP> <DOMAIN>    # wszystkie rekordy
dig TXT @<DNS_IP> <DOMAIN>    # informacje, SPF, weryfikacje
dig MX @<DNS_IP> <DOMAIN>     # serwery pocztowe
dig NS @<DNS_IP> <DOMAIN>     # name servery
```

## Wektory ataku istotne dla web pentestingu

- **Subdomain takeover** -- jesli subdomena wskazuje na nieistniejacy zasob (CNAME dangling), mozna ja przejac
- **Rekursja DNS** -- jesli wlaczona (flaga `ra`), mozliwy amplification DDoS
- **Polityka CAA** -- `dig <DOMAIN> CAA +short` -- zbyt szerokie uprawnienia CA umozliwiaja wystawienie nieautoryzowanych certyfikatow
- **Niski TTL** -- ulatwia szybkie przekierowanie ruchu po uzyskaniu dostepu do DNS
- **Pliki konfiguracyjne** (post-exploitation):
  - `/etc/resolv.conf`, `/etc/bind/named.conf`, `/etc/bind/named.conf.local`
  - Parametry: `allow-transfer`, `allow-recursion`, `allow-query`
