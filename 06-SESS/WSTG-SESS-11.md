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


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Kontrola jednoczesnych sesji

- Zdecyduj czy aplikacja pozwala na wiele jednoczesnych sesji per uzytkownik
- **Aplikacje wrazliwe (bankowosc, admin)**: ogranicz do 1 aktywnej sesji — nowe logowanie uniewaznia stare
- **Aplikacje ogolne**: pozwol na wiele sesji, ale INFORMUJ uzytkownika o aktywnych sesjach
- Implementuj widok "aktywne sesje" — uzytkownik widzi liste (IP, UA, czas, lokalizacja)

### Uniewaznianie sesji przy zmianie hasla

- Po zmianie hasla: uniewazni WSZYSTKIE aktywne sesje POZA biezaca
- Chroni przed scenariuszem: wykradzione credentials → atakujacy zalogowany → uzytkownik zmienia haslo → atakujacy nadal zalogowany
- To samo po: resetowaniu hasla, kompromitacji konta, zmianie uprawnien

### "Logout everywhere" / "Wyloguj ze wszystkich urzadzen"

- Implementuj endpoint do uniewaznienia WSZYSTKICH sesji uzytkownika
- Wymaga server-side tracking wszystkich aktywnych sesji (tabela sesji w bazie)
- Przydatne po: zmianie hasla, wykryciu naruszenia, zagubieniu urzadzenia

### Powiadomienia o nowych sesjach

- Wysylaj email/push notification o nowym logowaniu z nieznanego urzadzenia/lokalizacji
- Pozwol uzytkownikowi zakonczyc podejrzana sesje z powiadomienia
- Loguj: timestamp, IP, User-Agent, geolokalizacja — do audytu

### Cookie scope i izolacja

- Ogranicz **Domain** cookie do konkretnej domeny — NIE ustawiaj na domene nadrzedna
- Uzywaj prefiksu `__Host-` — wymusza `Secure`, `Path=/`, brak `Domain` — zapobiega subdomain leakage
- Ogranicz **Path** do minimum wymaganego zakresu aplikacji

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V7.1.2 | Session Management Documentation | Verify that the documentation defines how many concurrent (parallel) sessions are allowed for one account as well as the intended behaviors and actions to be taken when the maximum number of active sessions is reached. |
| V7.1.3 | Session Management Documentation | Verify that all systems that create and manage user sessions as part of a federated identity management ecosystem (such as SSO systems) are documented along with controls to coordinate session lifetimes, termination, and any other conditions that require re-authentication. |
