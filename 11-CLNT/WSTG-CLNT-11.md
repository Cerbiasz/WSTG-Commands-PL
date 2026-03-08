# WSTG-CLNT-11 — Testing Web Messaging

## Cele

- Assess the security of the message's origin
- Validate that it's using safe methods and validating its input

## KOMENDY

### Szukaj postMessage w kodzie JS

```bash
curl -s "https://TARGET/" | grep -i "postMessage\|addEventListener.*message"
# Pobierz JS files i szukaj:
# window.postMessage, addEventListener('message', ...)

```

### PoC HTML do testowania

```bash
# <html><body>
# <iframe src="https://TARGET" id="target"></iframe>
# <script>
# document.getElementById('target').onload = function(){
#   this.contentWindow.postMessage('<img src=x onerror=alert(1)>','*');
# }
# </script>
# </body></html>

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test manualny

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. DevTools Console: monitoruj wiadomosci postMessage
2. Sprawdz czy event listener waliduje event.origin
3. Sprawdz czy dane z message sa sanityzowane przed uzyciem
4. Testuj wstrzykiwanie HTML/JS przez postMessage
5. Szukaj sinkow w handlerach message (innerHTML, eval, location)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md

- Waliduj origin wiadomosci w event.origin przy postMessage
- Uzywaj parametru targetOrigin — nie uzywaj '*' w postMessage
- Nie ufaj danym z postMessage — waliduj format i zawartosc
- Sprawdz czy aplikacja nie nasluchuje na wiadomosci z dowolnego origin

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
