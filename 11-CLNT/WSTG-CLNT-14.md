# WSTG-CLNT-14 — Testing for Reverse Tabnabbing

## Cele

- Identify links with target=_blank without proper rel attributes

## KOMENDY

### Szukanie linkow z target=_blank

```bash
curl -s "https://TARGET/" | grep -i 'target="_blank"' | grep -iv 'rel="noopener'
curl -s "https://TARGET/" | grep -i 'target="_blank"' | grep -iv 'rel="noreferrer'

```

### Sprawdzenie wielu stron

```bash
# Powtorz dla kazdej istotnej strony aplikacji

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings Tabnabbing

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/Tabnabbing/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Szukaj wszystkich linkow z target="_blank" w kodzie zrodlowym
2. Sprawdz czy maja rel="noopener noreferrer"
3. Jesli nie - stworz PoC: link prowadzi do strony ktora zmienia window.opener.location
4. Sprawdz czy user-generated content moze zawierac linki z target="_blank"


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Browser_Extension_Vulnerabilities_Cheat_Sheet.md

- Sprawdz uprawnienia rozszerzenia — czy nie zadaje nadmiernych permissions
- Waliduj komunikacje rozszerzenia z aplikacja webowa
- Sprawdz czy rozszerzenie nie wstrzykuje kodu na strone

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
