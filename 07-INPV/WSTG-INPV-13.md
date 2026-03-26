# WSTG-INPV-13 — Testing for Buffer Overflow

## Cele

- Test for buffer overflow vulnerabilities

## KOMENDY

### Wysylanie dlugich stringow

```bash
python3 -c "print('A'*5000)" | xargs -I {} curl -s "https://TARGET/page?input={}" -o /dev/null -w "%{http_code}\n"
python3 -c "print('A'*10000)" | xargs -I {} curl -s "https://TARGET/page?input={}" -o /dev/null -w "%{http_code}\n"
python3 -c "print('A'*100000)" | xargs -I {} curl -s "https://TARGET/page?input={}" -o /dev/null -w "%{http_code}\n"

```

### Format string testing

```bash
curl -s "https://TARGET/page?input=%s%s%s%s%s%s%s%s%s%s"
curl -s "https://TARGET/page?input=%x%x%x%x%x%x%x%x%x%x"
curl -s "https://TARGET/page?input=%n%n%n%n%n%n"

```

### Integer overflow

```bash
curl -s "https://TARGET/page?id=2147483647"
curl -s "https://TARGET/page?id=2147483648"
curl -s "https://TARGET/page?id=-1"
curl -s "https://TARGET/page?id=99999999999999999999"

```

## KOMENDY Z WORDLISTAMI

### SecLists naughty strings

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/big-list-of-naughty-strings.txt -mc all -o output_ffuf_naughty.json

```

### SecLists format strings

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/FormatString-Jhaddix.txt -mc all -o output_ffuf_formatstr.json

```

### fuzzdb integer overflow

```bash
ffuf -u "https://TARGET/page?id=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/integer-overflow/integer-overflow.txt -mc all -o output_ffuf_intoverflow.json

```

### fuzzdb format strings

```bash
ffuf -u "https://TARGET/page?input=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/format-strings/format-strings.txt -mc all -o output_ffuf_fuzzdb_fmt.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Wyslij bardzo dlugie stringi (1000, 5000, 10000, 100000 znakow) do kazdego pola
2. Sprawdz czy aplikacja sie zawiesi lub zwroci 500
3. Testuj format string specifiers (%s, %x, %n)
4. Testuj wartosci graniczne integer (MAX_INT, MIN_INT, 0, -1)
5. Monitoruj zuzycie pamieci i CPU serwera jesli to mozliwe


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, C_Based_Toolchain_Hardening_Cheat_Sheet.md

### Buffer Overflow — czy nadal relevantne w web?

- Nowoczesne jezyki (Java, Python, C#, JS, Go, Rust) maja **wbudowana ochrone** przed buffer overflow
- Buffer overflow nadal moze wystapic w:
  - Komponentach natywnych (C/C++) — np. modul Apache, biblioteka przetwarzajaca obrazy
  - Parsowaniu plikow (ImageMagick, FFmpeg, libxml)
  - Custom natywnych rozszerzeniach (PHP extensions w C, Python C extensions)
  - CGI binaries
- Web aplikacje: focus na **integer overflow** i **format string** — te sa bardziej relevantne

### Integer Overflow — wazne w web

- `MAX_INT (2147483647) + 1` = `-2147483648` (32-bit signed) — zmiana znaku
- Moze powodowac: bledne obliczenia cen, ominięcie limitow, ujemne wartosci
- Testuj graniczne wartosci: `0`, `-1`, `2147483647`, `2147483648`, `9999999999999999`
- Jezyki z fixed-size integer (C, Java, Go) — podatne; Python ma arbitrary precision

### Format String — ataki

- Specifiers `%s`, `%x`, `%n` — moga czytac/zapisywac pamiec w programach C/C++
- W web: niebezpieczne jesli dane uzytkownika trafiaja bezposrednio do `printf()` lub `sprintf()`
- `%x` — odczyt wartosci ze stosu (memory disclosure)
- `%n` — zapis do pamieci (code execution)
- W nowoczesnych jezykach: format string nie jest exploitowalny (Python, Java maja bezpieczne formatowanie)

### Obrona

- **Input validation**: ogranicz dlugosc danych wejsciowych na KAZDYM endpoincie
- **Max content length**: ustaw limity na serwerze (`client_max_body_size` nginx, `LimitRequestBody` Apache)
- **Uzywaj bezpiecznych jezykow**: Java, C#, Go, Rust — zamiast C/C++ dla web komponentow
- Jesli C/C++: uzyj `-fstack-protector-strong`, ASLR, DEP/NX, `-D_FORTIFY_SOURCE=2`
- **WAF**: wykrywaj format string payloads w parametrach
- Testuj zuzycie pamieci i CPU przy dlugich inputach — obrona przed DoS

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.4.1 | Memory, String, and Unmanaged Code | Verify that the application uses memory-safe string, safer memory copy and pointer arithmetic to detect or prevent stack, buffer, or heap overflows. |
| V1.4.2 | Memory, String, and Unmanaged Code | Verify that sign, range, and input validation techniques are used to prevent integer overflows. |
| V1.4.3 | Memory, String, and Unmanaged Code | Verify that dynamically allocated memory and resources are released, and that references or pointers to freed memory are removed or set to null to prevent dangling pointers and use-after-free vulnerabilities. |
