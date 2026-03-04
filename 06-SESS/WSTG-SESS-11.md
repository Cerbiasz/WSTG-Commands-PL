# WSTG-SESS-11 — Testing for Concurrent Sessions

## Cele

- Ocena obslugi wielu jednoczesnych sesji dla jednego uzytkownika
- Sprawdzenie czy stare sesje sa uniewazniane przy nowym logowaniu
- Ocena limitu jednoczesnych sesji

## KOMENDY

### Krok 1: Logowanie z pierwszej sesji

```bash
curl -s -c session1_cookies.txt -L TARGET/login -d "user=test&pass=test"
echo "Session 1:"
cat session1_cookies.txt

```

### Krok 2: Logowanie z drugiej sesji (nowe cookie)

```bash
curl -s -c session2_cookies.txt -L TARGET/login -d "user=test&pass=test"
echo "Session 2:"
cat session2_cookies.txt

```

### Krok 3: Sprawdz czy pierwsza sesja nadal dziala

```bash
curl -s -b session1_cookies.txt TARGET/dashboard -o /dev/null -w "Session 1 status: %{http_code}\n"

```

### Krok 4: Sprawdz czy druga sesja dziala

```bash
curl -s -b session2_cookies.txt TARGET/dashboard -o /dev/null -w "Session 2 status: %{http_code}\n"

```

### Krok 5: Logowanie z trzeciej sesji

```bash
curl -s -c session3_cookies.txt -L TARGET/login -d "user=test&pass=test"
curl -s -b session1_cookies.txt TARGET/dashboard -o /dev/null -w "Session 1 after 3rd login: %{http_code}\n"
curl -s -b session2_cookies.txt TARGET/dashboard -o /dev/null -w "Session 2 after 3rd login: %{http_code}\n"
curl -s -b session3_cookies.txt TARGET/dashboard -o /dev/null -w "Session 3: %{http_code}\n"

```

### Test z roznych User-Agent (symulacja roznych urzadzen)

```bash
curl -s -c session_mobile.txt -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" TARGET/login -d "user=test&pass=test"
curl -s -c session_desktop.txt -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" TARGET/login -d "user=test&pass=test"

```

### Sprawdz obie sesje

```bash
curl -s -b session_mobile.txt TARGET/dashboard -o /dev/null -w "Mobile session: %{http_code}\n"
curl -s -b session_desktop.txt TARGET/dashboard -o /dev/null -w "Desktop session: %{http_code}\n"

```

### Sprawdz czy uzytkownik jest powiadamiany o nowym logowaniu

```bash
curl -s -b session1_cookies.txt TARGET/dashboard | grep -i "active sessions\|new login\|another device"

```

### Sprawdz czy istnieje endpoint do zarzadzania sesjami

```bash
curl -s -b session1_cookies.txt TARGET/settings/sessions
curl -s -b session1_cookies.txt TARGET/account/active-sessions

```

### Test wylogowania ze wszystkich sesji

```bash
curl -s -b session1_cookies.txt -X POST TARGET/logout-all
curl -s -b session2_cookies.txt TARGET/dashboard -o /dev/null -w "Session 2 after logout-all: %{http_code}\n"
curl -s -b session3_cookies.txt TARGET/dashboard -o /dev/null -w "Session 3 after logout-all: %{http_code}\n"

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na analizie zachowania wielu rownoczesnych sesji.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zaloguj sie w Chrome - zapisz sesje
2. Zaloguj sie w Firefox (lub trybie incognito) - zapisz sesje
3. Sprawdz czy obie sesje dzialaja jednoczesnie
4. Sprawdz czy aplikacja informuje o aktywnych sesjach
5. Sprawdz czy istnieje opcja "wyloguj ze wszystkich urzadzen"
6. Przetestuj limit jednoczesnych sesji (3, 5, 10?)
7. Sprawdz czy po zmianie hasla stare sesje sa uniewazniane
8. Dla kont krytycznych (admin) - powinno byc ograniczenie do 1 sesji

