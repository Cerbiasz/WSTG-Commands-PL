# WSTG-INFO-06 — Identify Application Entry Points

## Cele

- Identify entry/injection points via request/response analysis
- Map all parameters, headers, cookies that accept user input
- Understand data flow and identify potential injection vectors

## KOMENDY

### Hakrawler - crawling i zbieranie URL-ow

```bash
echo https://TARGET | hakrawler -d 3 | tee output_hakrawler.txt
echo https://TARGET | hakrawler -d 3 -subs | tee output_hakrawler_subs.txt

```

### ParamSpider - odkrywanie parametrow

```bash
paramspider -d TARGET -o output_paramspider.txt
paramspider -d TARGET --level high -o output_paramspider_high.txt

```

### Arjun - wykrywanie ukrytych parametrow HTTP

```bash
arjun -u https://TARGET -oT output_arjun.txt
arjun -u https://TARGET -m POST -oT output_arjun_post.txt
arjun -u https://TARGET -m JSON -oT output_arjun_json.txt
arjun -u https://TARGET --headers "Cookie: session=TOKEN" -oT output_arjun_auth.txt

```

### GAU - zbieranie historycznych URL-ow z parametrami

```bash
echo TARGET | gau --threads 5 | grep "=" | tee output_gau_params.txt
echo TARGET | gau --threads 5 | grep "=" | uro | tee output_gau_params_unique.txt

```

### Waybackurls - historyczne URL-e

```bash
echo TARGET | waybackurls | grep "=" | tee output_wayback_params.txt

```

### Gospider - crawler

```bash
gospider -s https://TARGET -d 3 -c 10 -o output_gospider/
gospider -s https://TARGET -d 3 --other-source --include-subs -o output_gospider_full/

```

### OWASP ZAP w trybie CLI

```bash
zap-cli quick-scan -s all -r https://TARGET -o output_zap.html

```

### Zbieranie formularzy

```bash
curl -s https://TARGET | grep -iE "<form|<input|<select|<textarea" | tee output_forms.txt

```

### Zbieranie naglowkow i cookies

```bash
curl -sI https://TARGET -c output_cookies.txt | tee output_response_headers.txt

```

## KOMENDY Z WORDLISTAMI

### Brute-force ukrytych parametrow z SecLists

```bash
arjun -u https://TARGET -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/burp-parameter-names.txt -oT output_arjun_seclist.txt

```

### ffuf do fuzzowania parametrow GET

```bash
ffuf -u "https://TARGET/?FUZZ=test" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/burp-parameter-names.txt -mc 200 -fs 0 -o output_ffuf_params.json

```

### ffuf do fuzzowania parametrow POST

```bash
ffuf -u https://TARGET -X POST -d "FUZZ=test" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/burp-parameter-names.txt -mc 200 -fs 0 -o output_ffuf_params_post.json

```

### Fuzzowanie parametrow z Bug-Bounty-Wordlists

```bash
ffuf -u "https://TARGET/?FUZZ=test" -w Desktop/WSTG/Bug-Bounty-Wordlists-main/fuzz.txt -mc 200 -fs 0 -o output_ffuf_params_bbw.json

```

### Fuzzowanie sciezek URL z parametrami

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -mc 200,301,302 -o output_ffuf_paths.json

```

### Szukanie endpointow API

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api.txt -mc 200,301,302,401,403 -o output_ffuf_api_endpoints.json
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/api_seen_in_wild.txt -mc 200,301,302,401,403 -o output_ffuf_api_wild.json

```

### URL parameters z popularnych aplikacji

```bash
ffuf -u "https://TARGET/?FUZZ=test" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/url-params_from-top-55-most-popular-apps.txt -mc 200 -fs 0 -o output_ffuf_popular_params.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uruchom Burp Suite Spider na TARGET - automatyczne mapowanie entry points
2. W Burp Suite > Target > Site Map - przejrzyj wszystkie endpointy i parametry
3. Uzyj Burp Intruder do fuzzowania odkrytych parametrow
4. Sprawdz kazdy formularz - pola ukryte (type="hidden"), tokeny CSRF
5. W DevTools > Network - analizuj wszystkie zapytania AJAX/XHR
6. Sprawdz zapytania JavaScript (fetch, XMLHttpRequest) w kodzie zrodlowym
7. Zwroc uwage na parametry w URL, ciasteczka, naglowki niestandardowe
8. Przeanalizuj mechanizm autentykacji i sesji
9. Sprawdz API endpoints - metody GET, POST, PUT, DELETE


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Entry points — kategoryzacja

| Typ entry point | Przyklady | Potencjalne ataki |
|----------------|-----------|------------------|
| URL parametry (GET) | `?id=1&search=test` | SQLi, XSS, IDOR, LFI |
| Body parametry (POST) | Formularze, JSON, XML | SQLi, XSS, XXE, command injection |
| HTTP naglowki | `Cookie`, `Referer`, `User-Agent`, `X-Forwarded-For` | Header injection, log injection, SSRF |
| Cookies | Session ID, preferencje | Session hijacking, parameter tampering |
| Pliki (upload) | Obrazy, dokumenty, archiwa | RCE, XSS, path traversal |
| URL sciezka | `/api/users/123` | IDOR, path traversal |
| WebSocket | Wiadomosci WS | Injection, CSWSH |

### Ukryte parametry — jak je znalezc

- **Arjun**: automatyczne odkrywanie ukrytych parametrow HTTP (GET, POST, JSON)
- **ParamSpider**: zbieranie parametrow z historycznych URL-ow (Wayback Machine)
- **Burp Intruder**: fuzzowanie parametrow z wordlista `burp-parameter-names.txt`
- **Analiza JS**: LinkFinder, JSParser — endpointy i parametry w kodzie JavaScript
- **Hidden fields**: `<input type="hidden">` w formularzach — czesto brak walidacji server-side

### Mapowanie parametrow — checklist

Dla kazdego entry point dokumentuj:
1. **Nazwa parametru** i lokalizacja (GET, POST, cookie, header)
2. **Typ danych** — string, integer, boolean, date, file
3. **Ograniczenia** — dlugosc, dozwolone znaki, zakres wartosci
4. **Walidacja** — client-side only? server-side?
5. **Wplyw** — co kontroluje ten parametr (logika biznesowa, dostep, wyswietlanie)
6. **Encoding** — URL encoding, Base64, JSON, XML

### Analiza request/response — na co zwrocic uwage

- **Parametry w URL** ktore kontroluja dostep: `role=`, `admin=`, `debug=`
- **Hidden fields** z wartosciami ktore mozna manipulowac: `price`, `discount`, `user_id`
- **Cookies** bez flag Secure/HttpOnly — potential hijacking
- **Custom headers** akceptowane przez aplikacje: `X-Custom-Auth`, `X-User-Role`
- **Rozne odpowiedzi** na rozne wartosci tego samego parametru — wskazuja na logike

### Obrona

- Waliduj WSZYSTKIE dane wejsciowe server-side — nigdy nie ufaj client-side validation
- Uzyj allowlist (whitelist) zamiast denylist (blacklist) dla walidacji
- Implementuj walidacje na granicy systemu: API gateway, controller, middleware
- Nie akceptuj nieznanych parametrow — strict parameter binding
- Loguj niestandardowe parametry w requestach — moga wskazywac na probe ataku

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| GAP-Burp-Extension | Automatyczne wyciaganie parametrow, endpointow i slow z odpowiedzi | [GitHub](https://github.com/xnl-h4ck3r/GAP-Burp-Extension) |
| Attack Surface Detector | Identyfikacja endpointow przez statyczna analize kodu | [GitHub](https://github.com/secdec/attack-surface-detector-burp) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.1.1 | Configuration Documentation | Verify that all communication needs for the application are documented. This must include external services which the application relies upon and cases where an end user might be able to provide an external location to which the application will then connect. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V4.1.4 | Generic Web Service Security | Verify that only HTTP methods that are explicitly supported by the application or its API (including OPTIONS during preflight requests) can be used and that unused methods are blocked. |
