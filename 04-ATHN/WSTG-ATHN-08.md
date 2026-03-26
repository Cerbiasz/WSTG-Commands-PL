# WSTG-ATHN-08 — Testing for Weak Security Question Answer

## Cele

- Determine the complexity and how straight-forward the questions are
- Assess possible user answers and brute force capabilities

## KOMENDY

### Sprawdzenie jakie pytania sa uzywane

```bash
curl -s "https://TARGET/forgot-password" | grep -i "security question\|secret question\|question"
curl -s "https://TARGET/register" | grep -i "security question\|secret question"

```

### Testowanie brute force odpowiedzi

```bash
ffuf -u "https://TARGET/forgot-password" -X POST -d "username=admin&answer=FUZZ" -w Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt -mc 200,302 -o output_ffuf_security_q.json

```

### Testowanie slabych pytan

```bash
# Czy pytania sa zbyt proste? (ulubiony kolor, miasto urodzenia)
# Czy odpowiedzi sa publicznie dostepne? (social media)

```

## KOMENDY Z WORDLISTAMI

### SecLists common passwords (jako potencjalne odpowiedzi)

```bash
# Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/10k-most-common.txt
# Desktop/WSTG/SecLists-master/Passwords/Common-Credentials/common-passwords-win.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz jakie pytania bezpieczenstwa sa dostepne
2. Ocen czy pytania sa zbyt proste lub odpowiedzi publiczne
3. Testuj brute force odpowiedzi z Burp Intruder
4. Sprawdz czy jest lockout po blednych odpowiedziach
5. Testuj czy mozna zmienic pytanie na prostsze


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Choosing_and_Using_Security_Questions_Cheat_Sheet.md

### UWAGA: NIST SP 800-63 — pytania bezpieczenstwa NIE sa akceptowalnym czynnikiem uwierzytelniania

- NIST **odradza** uzywanie pytan bezpieczenstwa jako mechanizmu uwierzytelniania
- Badania Microsoft (2009) i Google (2015) wykazaly slaba skutecznosc pytan bezpieczenstwa
- Jesli juz musisz uzywac — traktuj jako **dodatkowy** czynnik, NIGDY jako jedyny

### Cechy dobrych pytan bezpieczenstwa

- **Memorable**: uzytkownik musi pamietac odpowiedz po latach
- **Consistent**: odpowiedz NIE moze sie zmieniac w czasie (NIE: ulubiony film, kolor)
- **Applicable**: kazdy uzytkownik musi moc odpowiedziec
- **Confidential**: odpowiedz musi byc trudna do uzyskania przez atakujacego (NIE: data urodzenia)
- **Specific**: odpowiedz musi byc jednoznaczna

### Zle pytania (UNIKAJ)

| Pytanie | Problem |
|---------|---------|
| Data urodzenia | Latwo dostepna (social media, publiczne rejestry) |
| Ulubiony film/kolor | Zmienia sie w czasie |
| Nazwisko panienskie matki | Latwo do odnalezienia (social media, genealogia) |
| Pierwszy samochod | Maly zakres mozliwych odpowiedzi |
| Pseudonim | Mozna odgadnac z social media |

### Dobre pytania (przykladowe)

- "Nazwa uczelni do ktorej aplikowales ale nie poszles?"
- "Nazwa pierwszej szkoly ktora pamietas?"
- "Cel najciekawszej wycieczki szkolnej?"
- "Imie instruktora nauki jazdy?"
- Najlepiej: pytania **specyficzne dla kontekstu aplikacji** (mniej prawdopodobne ze te same na innej stronie)

### Przechowywanie odpowiedzi

- Hashuj odpowiedzi **tak jak hasla** (bcrypt, Argon2) — moga zawierac PII i byc reuse miedzy serwisami
- Porownuj odpowiedzi **case-insensitive** — konwertuj do lowercase przed haszowaniem
- Sprawdzaj odpowiedzi na denylist: username, email, haslo, "123", "password"
- Wymuszaj **minimalna dlugosc** odpowiedzi (ale nie za duza — "Li" moze byc poprawna)

### Flow bezpieczenstwa

- Pytania bezpieczenstwa + haslo **NIE stanowia MFA** (oba = "something you know")
- Przy odzyskiwaniu hasla: najpierw zweryfikuj email (link), POTEM pokaz pytania
- Bledna odpowiedz = nieudane logowanie → inkrementuj licznik lockout
- Nie pokazuj roznych pytan po kazdej blednej probie — atakujacy moze sprobowac wszystkich
- Aktualizacja odpowiedzi = **operacja wrazliwa** → wymagaj re-autentykacji (haslo/MFA)

### Wiele pytan

- Uzywaj **wielu pytan jednoczesnie** (np. 3 z 5) — trudniejsze do zlamania
- Mieszaj pytania user-defined z system-defined
- NIE pozwalaj uzytkownikowi pisac wlasnych pytan — ryzyko slabych pytan lub "reminder" hasla

### Testowanie

- Czy pytania sa latwe do odgadniecia (social media OSINT)?
- Czy jest rate limiting na odpowiedzi?
- Czy bledne odpowiedzi powoduja lockout?
- Czy mozna zmienic pytanie na prostsze bez re-autentykacji?
- Czy odpowiedzi sa przechowywane w plaintext (sprawdz w DB/API response)?

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V6.4.2 | Authentication Factor Lifecycle and Recovery | Verify that password hints or knowledge-based authentication (so-called "secret questions") are not present. |
