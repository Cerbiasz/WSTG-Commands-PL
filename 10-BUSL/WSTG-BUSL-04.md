# WSTG-BUSL-04 — Test for Process Timing

## Cele

- Przetestowac funkcjonalnosc wrazliwa na czas (timing)
- Wykryc race conditions (wyscigi)

## KOMENDY

### Testowanie race condition z curl (rownolegle requesty)

```bash
# Wyslij 10 rownoczesnych requestow:
for i in $(seq 1 10); do
    curl -s -X POST TARGET/api/redeem-coupon -d "code=COUPON123" &
done
wait

```

### Testowanie race condition z GNU parallel

```bash
seq 1 20 | parallel -j20 "curl -s -X POST TARGET/api/transfer -d 'amount=100&to=attacker'"

```

### Testowanie TOCTOU (Time of Check Time of Use)

```bash
# Krok 1: Sprawdz saldo
curl -v TARGET/api/balance
# Krok 2: Natychmiastowo wyslij dwa przelewy:
curl -s -X POST TARGET/api/transfer -d "amount=1000&to=user1" &
curl -s -X POST TARGET/api/transfer -d "amount=1000&to=user2" &
wait

```

### Burp Turbo Intruder - race condition

```bash
# 1. Przechwytuj request w Burp Suite
# 2. Wyslij do Turbo Intruder (Extensions -> Turbo Intruder)
# 3. Uzyj skryptu race condition:
# def queueRequests(target, wordlists):
#     engine = RequestEngine(endpoint=target.endpoint,
#                            concurrentConnections=30,
#                            requestsPerConnection=100,
#                            pipeline=False)
#     for i in range(30):
#         engine.queue(target.req, target.baseInput)
#
# def handleResponse(req, interesting):
#     table.add(req)

```

### Pomiar czasu odpowiedzi (timing attack)

```bash
for i in $(seq 1 10); do
    TIME=$(curl -s -o /dev/null -w "%{time_total}" -X POST TARGET/api/login -d "user=admin&pass=wrong_${i}")
    echo "Attempt $i: ${TIME}s"
done

```

### Testowanie race condition na glosowaniu

```bash
seq 1 50 | parallel -j50 "curl -s -X POST TARGET/api/vote -d 'option=A' -H 'Cookie: session=SESSION_TOKEN'"

```

### Testowanie race condition na rejestracji

```bash
seq 1 5 | parallel -j5 "curl -s -X POST TARGET/api/register -d 'username=testuser&email=test@test.com'"

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice czasowej

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Uzyj Burp Suite -> Turbo Intruder do wysylania wielu requestow jednoczesnie
2. Testuj race conditions na: realizacji kuponow, transferach srodkow, glosowaniach
3. Zmierz czasy odpowiedzi dla roznych danych - roznice moga wskazac timing leaks
4. Sprawdz czy operacje krytyczne sa atomowe (transakcje bazodanowe)
5. Testuj TOCTOU: sprawdz wartosc -> zmien wartosc w innym urzadzeniu -> kontynuuj
6. Sprawdz czy limity sa egzekwowane poprawnie przy rownoczesnych requestach
7. Testuj race condition na procesie platnosci (double spending)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md, Transaction_Authorization_Cheat_Sheet.md

### Race Condition — mechanizm

- **TOCTOU** (Time of Check to Time of Use): warunek sprawdzany w czasie T1, operacja wykonywana w T2
- Miedzy T1 a T2 stan moze sie zmienic — np. saldo sprawdzone, ale zmienione przed przelewem
- Skutek: podwojne wykorzystanie kuponow, podwojna platnosc, przekroczenie limitow

### Typowe scenariusze race condition w web

| Scenariusz | Skutek |
|------------|--------|
| Realizacja kuponu | Wielokrotne uzycie jednorazowego kodu |
| Transfer srodkow | Podwojne obciazenie / double spending |
| Glosowanie | Wielokrotne glosy na te sama opcje |
| Rejestracja unikalnego username | Dwa konta z tą samą nazwą |
| Rezerwacja / zakup | Dwa zamowienia na ten sam przedmiot |
| Like / follow | Wielokrotne polubienia |

### Obrona przed race conditions

- **Transakcje bazodanowe**: `SELECT ... FOR UPDATE` z `SERIALIZABLE` isolation level
- **Distributed locks**: Redis SETNX, database advisory locks
- **Idempotency keys**: unikalny klucz per operacja — powtorzony request = ignorowany
- **Optimistic locking**: version counter w rekordzie — UPDATE WHERE version = N
- **Atomic operations**: `UPDATE balance SET amount = amount - 100 WHERE amount >= 100`

### Timing Attacks

- **Timing leak**: rozny czas odpowiedzi ujawnia informacje (np. czy username istnieje)
- Porownywanie hasel/tokenow musi byc **constant-time** — `hmac.compare_digest()`, `crypto.timingSafeEqual()`
- Roznica 50ms miedzy "user exists" a "user doesn't exist" pozwala na enumeracje

### Testowanie

- Uzyj **Burp Turbo Intruder** z `concurrentConnections=30+` do race condition
- `GNU parallel -j50` do rownoczesnych requestow z terminala
- Zmierz czas odpowiedzi dla 100+ requestow — szukaj roznic wskazujacych na timing leak
- Testuj na operacjach krytycznych: platnosci, kupony, limity, glosowania

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Timeinator | Testowanie atakow timing-based i race conditions | [GitHub](https://github.com/FSecureLABS/timeinator) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L1 (Podstawowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.3.1 | Business Logic Security | Verify that the application will only process business logic flows for the same user in the expected sequential step order and without skipping steps. |

### L3 (Zaawansowany)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.4.2 | Anti-automation | Verify that business logic flows require realistic human timing, preventing excessively rapid transaction submissions. |


---

## HackTricks Tips

### Race Conditions

- **HTTP/2 single-packet attack**: wszystkie request frames na jednym TCP connection, wstrzymaj last byte, flush jednocześnie → sub-1ms window. Burp Turbo Intruder z `Engine.BURP2` + `gate`
- **HTTP/1.1 last-byte sync**: pre-send 20-30 requests minus final byte, disable TCP_NODELAY, flush razem
- **PHP session locking**: użyj różnych session tokens per request

### Hidden Substates

- Email verification + change: wyślij oba jednocześnie → verification token dla nowego emaila na stary
- 2FA bypass: brief window zanim `enforce_mfa` ustawione
- OAuth race na `authorization_code`: generuj multiple AT/RT pairs — niektóre przetrwają revoke

### Timing Attacks

- **Hidden parameter discovery**: ~5ms timing difference → Param Miner w Burp
- **Scoped SSRF discovery**: timing difference między allowed vs blocked domains
