# WSTG-INFO-07 — Map Execution Paths Through Application

## Cele

- Map target application and understand principal workflows
- Identify all functional paths and business logic flows
- Document critical transactions and multi-step processes

## KOMENDY

### Gospider - zaawansowany crawler

```bash
gospider -s https://TARGET -d 5 -c 10 --other-source -o output_gospider/
gospider -s https://TARGET -d 5 -c 10 --include-subs --other-source -o output_gospider_full/

```

### Hakrawler - crawling

```bash
echo https://TARGET | hakrawler -d 5 | tee output_hakrawler.txt
echo https://TARGET | hakrawler -d 5 -plain | tee output_hakrawler_plain.txt

```

### Katana (ProjectDiscovery) - nowoczesny crawler

```bash
katana -u https://TARGET -d 5 -jc -o output_katana.txt
katana -u https://TARGET -d 5 -jc -kf all -o output_katana_full.txt

```

### Wget - mirror strony

```bash
wget --spider --recursive --level=5 --no-verbose https://TARGET 2>&1 | grep "^--" | awk '{print $3}' | tee output_wget_spider.txt

```

### Zbieranie URL-ow z roznych zrodel

```bash
echo TARGET | gau --threads 5 | tee output_gau_all.txt
echo TARGET | waybackurls | tee output_wayback_all.txt

```

### Generowanie mapy URL-ow

```bash
echo TARGET | gau | sort -u | uro | tee output_unique_urls.txt

```

### Wyciaganie sciezek i grupowanie

```bash
echo TARGET | gau | unfurl paths | sort -u | tee output_paths.txt

```

### OWASP ZAP spider w trybie CLI

```bash
zap-cli spider https://TARGET
zap-cli report -o output_zap_spider.html -f html

```

## KOMENDY Z WORDLISTAMI

# Brak dedykowanych wordlist - ten test polega na mapowaniu istniejacych sciezek
# przez crawling i analiza aplikacji, a nie brute-force

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uruchom Burp Suite i przegladaj TARGET recznie - kazdy link, formularz, przycisk
2. W Burp > Target > Site Map - eksportuj pelna mape strony
3. Zidentyfikuj glowne workflows: rejestracja, logowanie, zakup, zmiana hasla
4. Narysuj diagram przeplywu danych dla kazdego workflow
5. Sprawdz wieloetapowe procesy (np. koszyk > dane > platnosc > potwierdzenie)
6. Zidentyfikuj role uzytkownikow i ich rozne sciezki w aplikacji
7. Uzyj ZAP Spider z przegladarke jako proxy - kliknij w kazdy element
8. Dokumentuj kazda znaleziona funkcje i jej entry/exit points
9. Zwroc uwage na przekierowania i lancuchy przekierowan
10. Sprawdz workflow dla roznych stanow sesji (zalogowany vs niezalogowany)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Threat_Modeling_Cheat_Sheet.md

### Mapowanie sciezek — co dokumentowac

| Element | Opis | Przyklad |
|---------|------|---------|
| Workflow | Wieloetapowy proces biznesowy | Rejestracja → weryfikacja email → profil |
| Data flow | Przeplyw danych miedzy komponentami | Frontend → API → baza danych |
| Trust boundaries | Granice zaufania | Publiczny internet → WAF → DMZ → backend |
| Entry/Exit points | Wejscia i wyjscia danych | Formularze, API, webhooks, eksporty |
| Roles | Rozne sciezki dla roznych rol | Admin vs user vs guest |
| State transitions | Zmiany stanu obiektu | Zamowienie: draft → paid → shipped → delivered |

### Krytyczne workflows do mapowania

| Workflow | Dlaczego krytyczny | Na co testowac |
|----------|-------------------|---------------|
| Rejestracja | Tworzenie konta | Enumeration, mass registration, bypass weryfikacji |
| Logowanie | Autentykacja | Brute force, credential stuffing, bypass MFA |
| Reset hasla | Odzyskanie dostepu | Token prediction, email injection, race condition |
| Zakup/platnosc | Transakcja finansowa | Price manipulation, race condition, bypass kroku |
| Zmiana roli/uprawnien | Eskalacja uprawnien | IDOR, mass assignment, privilege escalation |
| Upload plikow | Wgrywanie tresci | RCE, XSS, path traversal |
| Eksport danych | Pobieranie danych | IDOR, information disclosure, injection |

### Techniki mapowania

- **Reczny crawling**: klikaj w kazdy link, przycisk, formularz z wlaczonym Burp
- **Automatyczny spider**: Burp Spider, ZAP Spider, Katana, Gospider
- **Analiza JS**: LinkFinder, JSParser — odkrywanie endpointow ukrytych w JavaScript
- **Historyczne URL**: GAU, Waybackurls — sciezki z archive.org
- **Porownanie rol**: mapuj aplikacje jako admin, user, guest — roznice ujawniaja kontrole dostepu

### State machine — analiza wieloetapowych procesow

1. Zidentyfikuj wszystkie **stany** w procesie (np. koszyk → platnosc → potwierdzenie)
2. Sprawdz czy mozna **pominac krok** (np. przejsc od koszyka do potwierdzenia)
3. Sprawdz czy mozna **cofnac sie** i zmodyfikowac dane po zatwierdzeniu
4. Sprawdz czy stan jest przechowywany **server-side** (bezpieczne) czy **client-side** (niebezpieczne)
5. Testuj **race conditions** — rownoczesne zapytania w krytycznych momentach

### Obrona

- Wymuszaj kolejnosc krokow server-side — nie polegaj na client-side routing
- Uzyj tokenow sesji do sledzenia stanu procesu wieloetapowego
- Implementuj timeout dla niedokonczonych procesow
- Loguj i monitoruj nietypowe sciezki przeplywu (pominiecie kroku, cofanie)

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp DOM Scanner | Rekursywny crawling i skanowanie Single Page Applications | [GitHub](https://github.com/fcavallarin/burp-dom-scanner) |
| JSpector | Pasywne wyciaganie URL-i, endpointow i niebezpiecznych metod z JS | [GitHub](https://github.com/hisxo/JSpector) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.1.1 | Validation and Business Logic Documentation | Verify that the application's documentation defines input validation rules for how to check the validity of data items against an expected structure. This could be common data formats such as credit card numbers, email addresses, telephone numbers, or it could be an internal data format. |
