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

### postMessage — ryzyka

- `window.postMessage()` pozwala na cross-origin komunikacje miedzy oknami/iframe
- Jesli listener nie waliduje `event.origin` — dowolna strona moze wyslac wiadomosc
- Dane z postMessage moga trafic do: `innerHTML` (XSS), `eval()`, `location.href` (redirect)

### Obrona — wysylanie

- **ZAWSZE** uzywaj explicit `targetOrigin`: `target.postMessage(data, "https://trusted.com")`
- **NIGDY** `targetOrigin: "*"` — wiadomosc moze byc odczytana przez dowolna strone
- Nie wysylaj wrazliwych danych (tokenow, PII) przez postMessage jesli to mozliwe

### Obrona — odbieranie

- **ZAWSZE** waliduj `event.origin`: `if (event.origin !== "https://trusted.com") return;`
- **Waliduj format danych**: sprawdz typ, dlugosc, schemat — nie ufaj danym z postMessage
- **Sanityzuj dane** przed uzyciem w DOM — nie wstawiaj do `innerHTML`, `eval()`, `location.*`
- Uzywaj `JSON.parse()` na danych — nie `eval()`

### Typowe podatne wzorce

- `window.addEventListener("message", (e) => { document.body.innerHTML = e.data })` — XSS via postMessage
- `window.addEventListener("message", (e) => { eval(e.data) })` — RCE via postMessage
- `window.addEventListener("message", (e) => { location.href = e.data })` — redirect via postMessage
- Brak walidacji `event.origin` — kazda strona moze wyslac payload

### Testowanie

- Stworz PoC HTML: `<iframe src="TARGET"><script>frames[0].postMessage("payload","*")</script>`
- Wstrzyknij HTML/JS payloady przez postMessage
- Szukaj w kodzie JS: `addEventListener("message"` — znajdz handlery i sprawdz walidacje

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.5.5 | Browser Origin Separation | Verify that messages received by the postMessage interface are discarded if the origin of the message is not trusted, or if the syntax of the message is invalid. |


---

## HackTricks Tips

- **Enumerate listeners**: DevTools → `getEventListeners(window)` lub szukaj `window.addEventListener("message"`
- **Origin check bypass — `indexOf`/`search`**: `evil.com?trusted.com` passes `indexOf("trusted.com")`
- **Wildcard targetOrigin leak**: jeśli page framable i wysyła postMessages z `*` → zmień iframe origin
- **`null == null` bypass**: sandboxed iframe bez `allow-popups-to-escape-sandbox` → `null` origin obu stron → `e.origin === window.origin` = true
- **Force `e.source` null**: create iframe → postMessage → delete iframe → `e.source` = null
- **Trusted relay gadget**: znajdź "relay" page na trusted origin forwarding URL params via postMessage
