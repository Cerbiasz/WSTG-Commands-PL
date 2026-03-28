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

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md

### HTTP Parameter Pollution — mechanizm

- Wysylanie **wielu parametrow o tej samej nazwie** — `?id=1&id=2`
- Rozne technologie parsuja to rozne — co tworzy niespojnosci miedzy komponentami

### Zachowanie backendow — kluczowa tabela

| Technologia | Zachowanie | Przyklad `?id=1&id=2` |
|-------------|------------|----------------------|
| PHP/Apache | Bierze **ostatni** | `id=2` |
| ASP.NET/IIS | Laczy **przecinkiem** | `id=1,2` |
| JSP/Tomcat | Bierze **pierwszy** | `id=1` |
| Python Flask | Bierze **pierwszy** | `id=1` |
| Python Django | Bierze **ostatni** | `id=2` |
| Node.js Express | **Array** | `id=[1,2]` |
| Go net/http | Bierze **pierwszy** | `id=1` |

### Wektory ataku HPP

- **WAF bypass**: WAF waliduje pierwszy parametr (bezpieczny), backend uzywa drugiego (zlosliwego)
- **Logic bypass**: `?admin=false&admin=true` — backend moze wziac `true`
- **Authentication bypass**: `?user=admin&user=victim` — rozne komponenty moga odczytac rozne wartosci
- **Price manipulation**: `?price=100&price=1` — nadpisanie ceny
- HPP w **POST body**: `username=admin&username=victim` — ten sam mechanizm

### Obrona

- Uzywaj **frameworkow ktore odrzucaja duplikaty** parametrow lub explicite definiuj zachowanie
- Waliduj dane po stronie backendu — nie polegaj na WAF/froncie
- Uzyj jednego sposobu parsowania parametrow w calym pipeline (WAF → proxy → backend)
- Loguj i alertuj na zduplikowane parametry — moze wskazywac na probe ataku

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backslash Powered Scanner | Wykrywanie nieznanych klas podatnosci injection | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
| Active Scan++ | Rozszerzony skaner aktywny z dodatkowymi checkami | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.2.1 | Input Validation | Verify that input is validated to enforce business or functional expectations for that input. This should either use positive validation against an allow list of values, patterns, and ranges, or be based on comparing the input to an expected structure and logical limits according to predefined rules. For L1, this can focus on input which is used to make specific business or security decisions. For L2 and up, this should apply to all input. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V15.3.7 | Defensive Coding | Verify that the application has defenses against HTTP parameter pollution attacks, particularly if the application framework makes no distinction about the source of request parameters (query string, body parameters, cookies, or header fields). |


---

## HackTricks Tips

- **PHP/Django/Tornado** używają **ostatniego** duplikatu parametru; **Flask/Go/Ruby** używają **pierwszego** → exploit payment/OTP/API-key flows
- **Server-Side Parameter Pollution**: inject `%26` (encoded `&`) lub `%23` (encoded `#`) w parametrach reflected do wewnętrznych API
- **JSON duplicate keys**: Go `encoding/json` bierze **ostatnią** wartość; Java Jackson bierze **pierwszą** → `{"action":"User","action":"Admin"}`
- **JSON key collision**: `{"role":"administrator\x0d"}`, `{"role":"administrator\ud800"}` — front-end widzi inną wartość niż backend
- **Go case-insensitive**: `{"AcTiOn":"AdminAction"}` matchuje `Action` field
