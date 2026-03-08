# WSTG-CLNT-06 — Testing for Client-side Resource Manipulation

## Cele

- Identify sinks with weak input validation
- Assess the impact of the resource manipulation

## KOMENDY

### Manipulacja src/href

```bash
curl -s "https://TARGET/page?img=http://evil.com/fake.png"
curl -s "https://TARGET/page?script=http://evil.com/evil.js"
curl -s "https://TARGET/page?link=http://evil.com/style.css"

```

### Testowanie window.postMessage

```bash
# Uzyj DevTools console:
# window.addEventListener('message', function(e){console.log(e)})

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test manualny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Szukaj parametrow kontrolujacych zasoby (src=, href=, action=, data=)
2. Testuj podmiane zrodel skryptow, obrazow, arkuszy CSS
3. Monitoruj postMessage w DevTools console
4. Sprawdz czy event handlery postMessage waliduja origin


---

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
