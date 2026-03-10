# WSTG-SESS-07 — Testing Session Timeout

## Cele

- Weryfikacja czy istnieje twardy timeout sesji (absolute timeout)
- Sprawdzenie idle timeout (brak aktywnosci)
- Ocena czy timeout jest wystarczajaco krotki

## KOMENDY

### Krok 1: Zaloguj sie i zapisz czas + cookie

```bash
curl -s -c session_cookies.txt -L TARGET/login -d "user=test&pass=test"
echo "Login time: $(date)"
cat session_cookies.txt

```

### Krok 2: Sprawdz sesje po okreslonym czasie bezczynnosci

```bash
# Poczekaj X minut (np. 15, 30, 60)
sleep 900 && curl -s -b session_cookies.txt TARGET/dashboard -o /dev/null -w "Status after 15min: %{http_code}\n"

```

### Krok 3: Test idle timeout - request po dluzszym czasie

```bash
sleep 1800 && curl -s -b session_cookies.txt TARGET/dashboard -o /dev/null -w "Status after 30min: %{http_code}\n"

```

### Krok 4: Test absolute timeout

```bash
# Utrzymuj sesje aktywna (co minute wysylaj request)
# Sprawdz po jakiej dlugosci calkowitej sesja wygasa mimo aktywnosci
for i in $(seq 1 120); do
    sleep 60
    STATUS=$(curl -s -b session_cookies.txt TARGET/dashboard -o /dev/null -w "%{http_code}")
    echo "Minute $i: HTTP $STATUS"
    if [ "$STATUS" != "200" ]; then echo "Session expired at minute $i"; break; fi
done

```

### Sprawdzenie Max-Age / Expires w cookie

```bash
curl -s -I TARGET/login -d "user=test&pass=test" | grep -i "set-cookie" | grep -iE "max-age|expires"

```

### Sprawdzenie naglowkow cache zwiazanych z timeout

```bash
curl -s -I TARGET/dashboard | grep -iE "cache-control|pragma"

```

### Test czy sesja wygasa po zamknieciu przegladarki (sesyjne cookie)

```bash
# Cookie bez Expires/Max-Age powinno wygasnac po zamknieciu przegladarki

```

### Test reakcji serwera na wygasla sesje

```bash
curl -v -b "SESSIONID=EXPIRED_SESSION_VALUE" TARGET/dashboard 2>&1

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na pomiarze czasu wygasniecia sesji.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie i zanotuj czas
2. Nie wykonuj zadnych akcji przez 15/30 minut
3. Sprobuj uzyc aplikacji - czy sesja wygasla? (idle timeout)
4. Zaloguj sie ponownie i uzytkuj aktywnie przez dluzszy czas
5. Sprawdz po jakim calkowitym czasie sesja wygasa (absolute timeout)
6. Sprawdz w DevTools -> Application -> Cookies atrybut Expires
7. Sprawdz czy po wygasnieciu sesji uzytkownik jest przekierowywany na strone logowania
8. Rekomendacja: idle timeout 15-30min, absolute timeout 4-8h


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Idle Timeout (brak aktywnosci)

- **15-30 minut** dla standardowych aplikacji
- **2-5 minut** dla aplikacji wysokiego ryzyka (bankowosc, ochrona zdrowia)
- Po idle timeout: uniewazni sesje server-side + redirect na strone logowania
- Mierz czas od OSTATNIEGO requestu uzytkownika

### Absolute Timeout (calkowity czas sesji)

- **4-8 godzin** — sesja wygasa niezaleznie od aktywnosci
- Zapobiega scenariuszowi: sesja aktywna bez konca przy ciaglym uzyciu
- Wymusza ponowne uwierzytelnienie — ogranicza okno czasowe wykradzionego tokenu
- Krotszy absolute timeout = mniejsze ryzyko

### Re-autentykacja dla operacji wrazliwych

- **Zmiana hasla**, przelew, zmiana adresu email, zmiana ustawien bezpieczenstwa
- Wymagaj podania aktualnego hasla LUB MFA — nawet w trakcie aktywnej sesji
- Chroni przed scenariuszem: uzytkownik zapominal wylogowac sie na publicznym komputerze

### Implementacja timeout

- Timeout po stronie SERWERA — nie po stronie klienta (JavaScript timeout mozna ominac)
- Cookie sesyjne: NIE ustawiaj `Expires`/`Max-Age` — cookie wygasa z zamknieciem przegladarki
- Persistent sessions (Remember Me): osobny token z dluzszym timeout, ALE wymagaj re-auth dla wrazliwych operacji

### Informowanie uzytkownika

- Pokaz ostrzezenie przed wygasnieciem sesji (np. 2 minuty wczesniej)
- Daj mozliwosc przedluzenia sesji — kliknij "Kontynuuj"
- Po wygasnieciu: jasny komunikat "Twoja sesja wygasla" + redirect na login

### Obrona przed session riding

- Krotki timeout OGRANICZA okno ataku — atakujacy ma mniej czasu na wykorzystanie wykradzionej sesji
- Im krotszy timeout — tym bezpieczniej, ALE gorszy UX — balans wymagany

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Timeinator | Testowanie atakow opartych na czasie | [GitHub](https://github.com/FSecureLABS/timeinator) |
