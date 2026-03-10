# WSTG-CLNT-08 — Testing for Cross Site Flashing

## Cele

- Decompile and analyze the application's code
- Assess sinks inputs and unsafe method usages

## KOMENDY

### Wyszukiwanie plikow SWF

```bash
curl -s "https://TARGET/" | grep -i "\.swf"
ffuf -u "https://TARGET/FUZZ" -w Desktop/WSTG/SecLists-master/Discovery/Web-Content/common.txt -e .swf -mc 200 -o output_ffuf_swf.json

```

### UWAGA: Flash jest przestarzaly (EOL 2020)

```bash
# Ten test jest glownie legacy. Jesli znajdziesz SWF:
# - Uzyj JPEXS Free Flash Decompiler do analizy
# - Szukaj: ExternalInterface.call, navigateToURL, loadMovie, getURL
# - Sprawdz czy SWF przyjmuje parametry z URL (flashvars)

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist (legacy technology)

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Sprawdz czy strona uzywa Flash/SWF (przestarzale, ale moze byc nadal obecne)
2. Jesli tak - pobierz SWF i dekompiluj JPEXS
3. Szukaj niebezpiecznych funkcji w zdekompilowanym kodzie
4. Testuj flashvars pod katem injection


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP Testing Guide, ogólne zasady bezpieczenstwa

### Flash/SWF — status (2020+)

- **Flash jest EOL od 31 grudnia 2020** — Adobe zakonczyl wsparcie
- Przegladarki usunely wsparcie Flash — Chrome, Firefox, Edge, Safari
- Testowanie Cross Site Flashing jest **legacy** — ale SWF mogą nadal istniec na serwerach
- Jesli znajdziesz SWF na serwerze: **usun go** — nie ma powodu go utrzymywac

### Jesli SWF nadal istnieje — co sprawdzic

- **ExternalInterface.call()**: moze wywolac JavaScript — potencjalny XSS
- **navigateToURL/getURL**: przekierowanie — potencjalny open redirect
- **loadMovie/loadClip**: ladowanie zewnetrznego SWF — content injection
- **flashvars**: parametry z URL — injection point
- **allowScriptAccess**: `always` = pelny dostep do JS strony hosting

### Obrona

- **Usun wszystkie pliki SWF** z serwera — Flash jest przestarzaly
- Zablokuj MIME type `application/x-shockwave-flash` na serwerze
- Jesli nie mozna usunac: ustaw `allowScriptAccess="never"` i `allowNetworking="none"`

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
