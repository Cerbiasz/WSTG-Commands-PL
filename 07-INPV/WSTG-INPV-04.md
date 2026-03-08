# WSTG-INPV-04 — Testing for HTTP Parameter Pollution

## Cele

- Identify the backend and the parsing method used
- Assess injection points and try bypassing input filters using HPP

## KOMENDY

### Podstawowe testy HPP

```bash
curl -s "https://TARGET/search?q=test&q=<script>alert(1)</script>"
curl -s "https://TARGET/action?id=1&id=2"
curl -s "https://TARGET/action?admin=false&admin=true"

```

### HPP w POST

```bash
curl -X POST "https://TARGET/login" -d "username=admin&username=victim&password=pass"
curl -X POST "https://TARGET/transfer" -d "amount=1&amount=1000"

```

### Testowanie parsowania backendow

```bash
# PHP: bierze ostatni parametr
# ASP.NET: laczy parametry przecinkiem
# JSP: bierze pierwszy parametr
curl -s "https://TARGET/page?color=red&color=blue" | grep -i "red\|blue"

```

### HPP bypass WAF

```bash
curl -s "https://TARGET/search?q=safe&q=<script>alert(1)</script>"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings HPP reference

```bash
# Dokumentacja: Desktop/WSTG/PayloadsAllTheThings-master/HTTP Parameter Pollution/README.md

```

### Brak dedykowanych wordlist - test logiczny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj technologie backendu (PHP, ASP.NET, Java)
2. Wyslij zduplikowane parametry i sprawdz ktory jest uzywany
3. Testuj HPP na formularzach logowania, wyszukiwania, transferow
4. Uzyj Burp Repeater do manipulacji parametrami
5. Sprawdz czy HPP pozwala ominac filtrowanie wejscia (WAF bypass)
6. Testuj rozne separatory (&, ;) w roznych kontekstach


---

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backslash Powered Scanner | Wykrywanie nieznanych klas podatnosci injection | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
| Active Scan++ | Rozszerzony skaner aktywny z dodatkowymi checkami | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
