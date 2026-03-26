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

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — DOM_based_XSS_Prevention_Cheat_Sheet.md

### Client-side Resource Manipulation — mechanizm

- Atakujacy kontroluje **URL zasobu** ladowanego przez strone (src, href, action, data)
- Skutek: ladowanie zlosliwego skryptu, CSS, obrazka, formularza z kontrolowanego serwera
- Roznica vs XSS: nie wstrzykuje kodu, ale **zmienia zrodlo** zasobu

### Niebezpieczne atrybuty/sinki

| Atrybut/Sink | Ryzyko |
|-------------|--------|
| `<script src=X>` | Ladowanie zlosliwego JS — pelne RCE w kontekscie strony |
| `<link href=X>` | Ladowanie zlosliwego CSS — exfiltracja danych, UI redress |
| `<img src=X>` | Tracking pixel, SSRF (jesli server-side fetch) |
| `<iframe src=X>` | Ladowanie strony atakujacego — phishing |
| `<form action=X>` | Przekierowanie formularza na serwer atakujacego — credential theft |
| `<object data=X>` | Ladowanie zlosliwego contentu |

### Obrona

- **Nigdy** nie uzywaj danych uzytkownika bezposrednio w atrybutach src/href/action
- Waliduj URL-e: allowlist dozwolonych domen, sprawdz schemat (https://)
- Uzyj **CSP**: `script-src 'self'`, `style-src 'self'` — blokuj zewnetrzne zasoby
- **Subresource Integrity (SRI)**: `integrity="sha384-..."` na `<script>` i `<link>` — weryfikuj hash zasobu
- Sanityzuj URL-e: odrzucaj `javascript:`, `data:`, `blob:` schematy

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.6.1 | External Resource Integrity | Verify that client-side assets, such as JavaScript libraries, CSS, or web fonts, are only hosted externally (e.g., on a Content Delivery Network) if the resource is static and versioned and Subresource Integrity (SRI) is used to validate the integrity of the asset. If this is not possible, there should be a documented security decision to justify this for each resource. |
