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

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Timeinator | Testowanie atakow timing-based i race conditions | [GitHub](https://github.com/FSecureLABS/timeinator) |
