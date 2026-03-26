# WSTG-CLNT-14 — Testing for Reverse Tabnabbing

## Cele

- Identify links with target=_blank without proper rel attributes

## KOMENDY

### Szukanie linkow z target=_blank

```bash
curl -s "https://TARGET/" | grep -i 'target="_blank"' | grep -iv 'rel="noopener'
curl -s "https://TARGET/" | grep -i 'target="_blank"' | grep -iv 'rel="noreferrer'

```

### Sprawdzenie wielu stron

```bash
# Powtorz dla kazdej istotnej strony aplikacji

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Tabnabbing

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Tabnabbing/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Szukaj wszystkich linkow z target="_blank" w kodzie zrodlowym
2. Sprawdz czy maja rel="noopener noreferrer"
3. Jesli nie - stworz PoC: link prowadzi do strony ktora zmienia window.opener.location
4. Sprawdz czy user-generated content moze zawierac linki z target="_blank"


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — HTML5_Security_Cheat_Sheet.md

### Reverse Tabnabbing — mechanizm ataku

1. Strona A zawiera link `<a href="https://evil.com" target="_blank">` bez `rel="noopener"`
2. Uzytkownik klika link → otwiera sie nowa karta z evil.com
3. Evil.com uzywa `window.opener.location = "https://phishing.com"` → strona A zmienia sie na phishing
4. Uzytkownik wraca do "karty A" → widzi strone phishingowa (np. fake login)

### Podatny kod

```html
<!-- PODATNE -->
<a href="https://external.com" target="_blank">Link</a>

<!-- BEZPIECZNE -->
<a href="https://external.com" target="_blank" rel="noopener noreferrer">Link</a>
```

### Obrona

- **Zawsze** dodawaj `rel="noopener noreferrer"` do linkow z `target="_blank"`
- `noopener`: blokuje dostep do `window.opener` — zapobiega tabnabbingowi
- `noreferrer`: nie wysyla Referer header — dodatkowa prywatnosc
- Nowoczesne przegladarki (Chrome 88+, Firefox 79+) automatycznie dodaja `noopener` — ale nie polegaj na tym
- **CSP**: rozważ `sandbox` na iframe aby ograniczyc mozliwosci zagnieżdzonych stron

### User-generated content — ryzyko

- Jesli uzytkownicy moga wstawiac linki (komentarze, profil, wiadomosci) — **automatycznie** dodawaj `rel="noopener noreferrer"`
- W Markdown rendererach: sprawdz czy linkd z `target="_blank"` maja prawidlowe atrybuty rel
- Frameworki: React automatycznie dodaje `noopener` od v16.x; sprawdz konfiguracje innych

### Testowanie

- Przeszukaj kod zrodlowy: `grep -i 'target="_blank"' | grep -iv 'noopener'`
- Sprawdz user-generated content pod katem linkow bez noopener
- Stworz PoC: strona ktora zmienia `window.opener.location` po otwarciu

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V3.4.8 | Browser Security Mechanism Headers | Verify that all HTTP responses that initiate a document rendering (such as responses with Content-Type text/html), include the Cross‑Origin‑Opener‑Policy header field with the same-origin directive or the same-origin-allow-popups directive as required. This prevents attacks that abuse shared access to Window objects, such as tabnabbing and frame counting. |
