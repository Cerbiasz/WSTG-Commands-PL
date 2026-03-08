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

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp DOM Scanner | Rekursywny crawling i skanowanie Single Page Applications | [GitHub](https://github.com/fcavallarin/burp-dom-scanner) |
| JSpector | Pasywne wyciaganie URL-i, endpointow i niebezpiecznych metod z JS | [GitHub](https://github.com/hisxo/JSpector) |
