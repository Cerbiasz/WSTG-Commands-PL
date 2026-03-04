# WSTG-ERRH-01 — Testing for Improper Error Handling

## Cele

- Zidentyfikowac istniejace wyjscia bledow (error output)
- Przeanalizowac rozne typy zwracanych odpowiedzi bledow

## KOMENDY

### Wymuszenie bledu 404 (Not Found)

```bash
curl -s -o /dev/null -w "%{http_code}\n" TARGET/nieistniejaca-strona-12345

```

### Wymuszenie bledu 404 z pelna odpowiedzia

```bash
curl -v TARGET/nieistniejaca-strona-12345

```

### Wymuszenie bledu 500 (Internal Server Error) za pomoca nieprawidlowych parametrow

```bash
curl -v "TARGET/search?q=%00%ff%fe"

```

### Wymuszenie bledu 403 (Forbidden)

```bash
curl -v TARGET/.htaccess
curl -v TARGET/admin/
curl -v TARGET/server-status

```

### Wysylanie nieprawidlowego Content-Type

```bash
curl -v -X POST TARGET/login -H "Content-Type: application/xml" -d '<<<invalid'

```

### Wysylanie zdjeformatowanego JSON

```bash
curl -v -X POST TARGET/api/endpoint -H "Content-Type: application/json" -d '{invalid json###'

```

### Wysylanie bardzo dlugiego URL

```bash
curl -v "TARGET/$(python3 -c "print('A'*10000)")"

```

### Wysylanie nieprawidlowej metody HTTP

```bash
curl -v -X PATCH TARGET/
curl -v -X DELETE TARGET/
curl -v -X PROPFIND TARGET/

```

### Wysylanie nieprawidlowych naglowkow

```bash
curl -v -H "Host: " TARGET/
curl -v -H "Content-Length: -1" TARGET/

```

### Testowanie overflow parametrow

```bash
curl -v "TARGET/page?id=99999999999999999999"
curl -v "TARGET/page?id=-1"
curl -v "TARGET/page?id=abc"

```

### Wymuszenie bledow SQL (jezeli istnieje injection)

```bash
curl -v "TARGET/page?id=1'"
curl -v "TARGET/page?id=1%27%20OR%201=1--"

```

### Nmap skanowanie stron bledow

```bash
nmap --script http-errors -p 80,443 TARGET

```

### Nikto skanowanie bledow konfiguracji

```bash
nikto -h TARGET -Tuning 3

```

### Burp Suite - testowanie odpowiedzi na bledy

```bash
# 1. Uruchom Burp Suite -> Proxy -> Intercept
# 2. Przechwytuj request i modyfikuj parametry na nieprawidlowe wartosci
# 3. Obserwuj odpowiedzi serwera pod katem ujawniania informacji

```

## KOMENDY Z WORDLISTAMI

### Fuzzowanie sciezek w celu wymuszenia bledow (fuzzdb disclosure-directory)

```bash
ffuf -u TARGET/FUZZ -w Desktop/WSTG/fuzzdb-master/attack/disclosure-directory/directory-indexing-generic.txt -mc all -fc 200,301,302 -c

```

### Fuzzowanie z payload'ami naughty strings (SecLists)

```bash
ffuf -u "TARGET/search?q=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/big-list-of-naughty-strings.txt -mc all -fc 200 -c

```

### Wfuzz testowanie bledow na roznych endpointach

```bash
wfuzz -c --hc 200,301,302 -w Desktop/WSTG/fuzzdb-master/attack/disclosure-directory/directory-indexing-generic.txt TARGET/FUZZ

```

### Fuzzowanie parametrow wyzwalajacych bledy

```bash
ffuf -u "TARGET/page?FUZZ=test" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/CommonDebugParamNames.txt -mc all -fc 200 -c

```

### Fuzzowanie z debug param names (fuzzdb)

```bash
ffuf -u "TARGET/?FUZZ=true" -w Desktop/WSTG/fuzzdb-master/attack/business-logic/DebugParams.Json.fuzz.txt -mc all -fc 200 -c

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Otworz przegladarke i odwiedz nieistniejace strony - sprawdz czy strony bledow ujawniaja
```bash
   technologie (np. Apache, Nginx, IIS, Tomcat, wersje frameworkow)
```

2. W Burp Suite -> Repeater: wyslij requesty z nieprawidlowymi danymi i analizuj odpowiedzi
3. Sprawdz czy bledy zawieraja sciezki plikow, nazwy bazy danych, stack traces
4. Sprawdz czy rozne kody bledow (400, 403, 404, 405, 500, 502, 503) zwracaja rozne informacje
5. Sprawdz naglowki odpowiedzi pod katem Server, X-Powered-By, X-AspNet-Version
6. Zrob screenshot kazdej unikalnej strony bledu jako dowod

