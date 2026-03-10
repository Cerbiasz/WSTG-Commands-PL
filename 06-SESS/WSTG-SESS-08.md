# WSTG-SESS-08 — Testing for Session Puzzling (Session Variable Overloading)

## Cele

- Identyfikacja zmiennych sesji uzywanych w roznych kontekstach
- Przerwanie logicznego przepływu aplikacji przez nadpisanie zmiennych sesji
- Sprawdzenie czy ta sama zmienna sesji jest uzywana do roznych celow

## KOMENDY

### Krok 1: Zmapuj wszystkie endpointy ktore ustawiaja zmienne sesji

```bash
curl -s -c cookies.txt -L TARGET/login -d "user=test&pass=test" -v 2>&1 | grep -i "set-cookie"
curl -s -b cookies.txt TARGET/profile -v 2>&1 | grep -i "set-cookie"
curl -s -b cookies.txt TARGET/reset-password -v 2>&1 | grep -i "set-cookie"

```

### Krok 2: Sprawdz czy zmienne sesji z jednego flow wplywaja na inny

```bash
# Przyklad: Reset password moze ustawiac zmienna "user" w sesji
# Potem uzycie tej zmiennej w innym kontekscie moze dac nieautoryzowany dostep

# Flow 1: Reset password dla admin
curl -s -c cookies_reset.txt TARGET/reset-password -d "email=admin@target.com"

# Flow 2: Uzyj tej samej sesji do dostepu do panelu
curl -s -b cookies_reset.txt TARGET/admin/dashboard

```

### Krok 3: Testowanie nadpisania zmiennych sesji

```bash
# Zaloguj sie jako normalny uzytkownik
curl -s -c cookies.txt TARGET/login -d "user=normaluser&pass=password"

# Odwiedz endpoint ktory moze nadpisac zmienna sesji
curl -s -b cookies.txt TARGET/forgot-password -d "username=admin"

# Sprawdz czy masz teraz dostep admina
curl -s -b cookies.txt TARGET/admin/panel

```

### Krok 4: Analiza zmiennych sesji w roznych flow

```bash
# W Burp Proxy przechwyc requesty z roznych flow
# Porownaj zmienne sesji ustawiane w kazdym flow

```

### Krok 5: Test race condition na zmiennych sesji

```bash
# Wyslij rownolegle requesty do roznych endpointow z ta sama sesja
curl -s -b cookies.txt TARGET/endpoint1 &
curl -s -b cookies.txt TARGET/endpoint2 &
wait

```

## KOMENDY Z WORDLISTAMI

# Brak specyficznych wordlist dla tego testu.
# Test opiera sie na analizie logiki aplikacji i zmiennych sesji.

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zmapuj wszystkie funkcje ktore ustawiaja/modyfikuja sesje (login, reset, register, etc.)
2. W Burp przeanalizuj zmienne sesji po kazdym flow
3. Sprobuj przeprowadzic flow A, a nastepnie uzyc sesji w kontekscie flow B
4. Sprawdz czy reset hasla nadpisuje zmienne uzywane przy autoryzacji
5. Przetestuj czy rejestracja nowego konta wplywa na istniejaca sesje
6. Szukaj zmiennych sesji o tych samych nazwach w roznych kontekstach
7. Testuj wielokrotne logowanie/wylogowanie z roznymi rolami w jednej sesji


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Session_Management_Cheat_Sheet.md

### Czym jest Session Puzzling

- Ta sama zmienna sesji uzywana w ROZNYCH kontekstach (np. "user" w login i reset password)
- Atakujacy: inicjuje flow A ktory ustawia zmienna → uzywa jej w flow B z innym znaczeniem
- Przyklad: reset password ustawia `$_SESSION['user'] = 'admin'` → atakujacy przechodzi do dashboard

### Izolacja zmiennych sesji

- **Oddzielne namespace** per funkcjonalnosc — nie dziel zmiennych miedzy modulami
- Uzywaj precyzyjnych nazw: `$_SESSION['auth_user']` zamiast `$_SESSION['user']`
- Nie uzywaj tej samej zmiennej do roznych celow (autentykacja, autoryzacja, reset)

### Walidacja stanow sesji

- Implementuj **state machine** — sprawdzaj czy uzytkownik przeszedl WYMAGANE kroki
- Przyklad: nie pozwalaj na dostep do dashboard bez przejscia przez login
- Sprawdzaj ZAWSZE: `$_SESSION['authenticated'] === true` — nie polegaj na istnieniu `$_SESSION['user']`

### Minimalizacja danych w sesji

- Przechowuj MINIMUM informacji w sesji — ID uzytkownika, role, timestamp uwierzytelnienia
- NIE przechowuj danych autoryzacji modyfikowalnych przez uzytkownika w zmiennych sesji
- Dane tymczasowe (np. flow resetowania hasla) przechowuj w oddzielnym mechanizmie z krotkim TTL

### Obrona przed session puzzling

- Regeneruj session ID przy KAZDEJ zmianie kontekstu (login, reset, elevate privileges)
- Czysc WSZYSTKIE zmienne sesji przy zmianie kontekstu — nie zostawiaj smieci z poprzedniego flow
- Waliduj integralnosc sesji — sprawdzaj czy zmienne sesji sa spojne (np. user + role + timestamp)
- Unikaj przechowywania istotnych danych w `$_SESSION` — pobieraj je z bazy przy kazdym request

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
