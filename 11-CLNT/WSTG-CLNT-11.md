# WSTG-CLNT-11 — Testing Web Messaging (postMessage)

## Cel

Wykrycie vulnerability w `window.postMessage()` API: brak walidacji `event.origin` w handler, użycie `targetOrigin: "*"` przy wysyłaniu, sinki typu innerHTML/eval/location na danych z postMessage.

> **Test mostly manual**: postMessage requires DOM Invader / static analysis JS bundles. Cross-ref WSTG-CLNT-01 markery.

## Automatyzacja Nuclei

```bash
# DOM XSS markers wykrywa postMessage handlers bez origin check
nuclei -l burp-export.xml -im burp -t templates/wstg-clnt-01-dom-xss.yaml
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Find handlers**: `grep -E "addEventListener\\(['\\\"]message['\\\"]" *.js`.
2. **Origin validation check**: w każdym handler sprawdzić `if (event.origin !== ...)`.
3. **Sink trace**: jeśli brak origin check, prześledzić `event.data` do sinks (innerHTML, eval, location).
4. **PoC creation**: stworzyć attacker page → embed iframe target → `frames[0].postMessage(payload, "*")`.
5. **Sender check**: w aplikacji szukać `postMessage(data, "*")` — wycieka data do dowolnej strony.

### Co MUSI być sprawdzone (8 punktów)

- [ ] Wszystkie `addEventListener('message', ...)` handlers
- [ ] Origin validation w handler
- [ ] event.data → innerHTML/outerHTML
- [ ] event.data → eval/Function
- [ ] event.data → location.href / location.assign
- [ ] event.data → JSON.parse + access (potential prototype pollution)
- [ ] `postMessage(data, "*")` calls (data leak risk)
- [ ] Cross-origin postMessage logic (intentional iframe communication)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md

### postMessage — ryzyka

- `window.postMessage()` pozwala na cross-origin komunikację między oknami/iframe
- Jeśli listener nie waliduje `event.origin` — dowolna strona może wysłać wiadomość
- Dane z postMessage mogą trafić do: `innerHTML` (XSS), `eval()`, `location.href` (redirect)

### Obrona — wysyłanie

- **ZAWSZE** używaj explicit `targetOrigin`: `target.postMessage(data, "https://trusted.com")`
- **NIGDY** `targetOrigin: "*"` — wiadomość może być odczytana przez dowolną stronę
- Nie wysyłaj wrażliwych danych (tokenów, PII) przez postMessage jeśli to możliwe

### Obrona — odbieranie

- **ZAWSZE** waliduj `event.origin`: `if (event.origin !== "https://trusted.com") return;`
- **Waliduj format danych**: sprawdź typ, długość, schemat — nie ufaj danym z postMessage
- **Sanityzuj dane** przed użyciem w DOM — nie wstawiaj do `innerHTML`, `eval()`, `location.*`
- Używaj `JSON.parse()` na danych — nie `eval()`

### Typowe podatne wzorce

- `window.addEventListener("message", (e) => { document.body.innerHTML = e.data })` — XSS via postMessage
- `window.addEventListener("message", (e) => { eval(e.data) })` — RCE via postMessage
- `window.addEventListener("message", (e) => { location.href = e.data })` — redirect via postMessage
- Brak walidacji `event.origin` — każda strona może wysłać payload

### Testowanie

- Stwórz PoC HTML: `<iframe src="TARGET"><script>frames[0].postMessage("payload","*")</script>`
- Wstrzyknij HTML/JS payloady przez postMessage
- Szukaj w kodzie JS: `addEventListener("message"` — znajdź handlery i sprawdź walidację

## Pentesterskie deep dive

### Mniej znane techniki

- **postMessage origin check bypass via subdomain takeover**: handler waliduje `*.target.com` ale `wycofana.target.com` jest takeoverable → atakujący ma legitimate origin.
- **Origin spoofing via document.domain**: aplikacja ustawiająca `document.domain = 'target.com'` zmienia origin reporting w postMessage events.
- **Cross-frame data leak**: `postMessage(secret, "*")` w sender → atakujący w iframe receiver dostaje dane.
- **Storage events propagate cross-tab**: `localStorage.setItem` triggers `storage` event w innych tabach tej samej origin → leak data jeśli atakujący ma open tab.
- **MessageChannel side channel**: nowsze API `MessageChannel` ma własne security model — lokalny port communication often pominął origin checks.

### Common pitfalls

- **Origin sprawdzany ale `===` z trusted variable**: jeśli atakujący XSS-uje pomniejszą część aplikacji, może zmienić zmienną `trustedOrigin` → bypass.
- **Indirect sink: data → JSON.parse → access object property**: `JSON.parse(event.data).action` z prototype pollution → trigger gadget.

### Świeżynki z research

- **PortSwigger postMessage Lab**: https://portswigger.net/web-security/dom-based/dom-xss-via-web-messaging
- **HackTricks postMessage**: https://book.hacktricks.xyz/pentesting-web/postmessage-vulnerabilities
- **DOMPurify dla event.data sanitization**: https://github.com/cure53/DOMPurify

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| DOM Invader | postMessage + DOM XSS analysis | Built-in PortSwigger |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/11-Client-side_Testing/11-Testing_Web_Messaging
- OWASP HTML5 Security CS: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html
- PortSwigger DOM XSS Web Messaging: https://portswigger.net/web-security/dom-based/dom-xss-via-web-messaging
- HackTricks postMessage: https://book.hacktricks.xyz/pentesting-web/postmessage-vulnerabilities

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.4.3 | Configuration (L1) | CSP set deny by default + nonce/hash. |
| V13.5.2 | (L2) | Origin validation in cross-origin messaging. |
