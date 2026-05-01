# WSTG-BUSL-04 — Test for Process Timing

## Cel

Wykrycie race conditions (TOCTOU): podwójne realizacje kuponów, double charging, double voting, dwie rejestracje z tym samym username, podwójna rezerwacja produktu.

> **Test manual-only**: race conditions wymagają precise timing - Burp Turbo Intruder lub Single Packet Attack (James Kettle).

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Identify atomic operations**: każda operacja "redeem coupon", "transfer money", "register user", "purchase".
2. **Single Packet Attack**: wyślij 50 simultaneous requests w jednym TCP packet → race window.
3. **Burp Turbo Intruder**: high-performance race condition tester.
4. **Result observation**: czy aplikacja allows multiple successful operations (np. coupon reused 50 razy)?
5. **Defense check**: czy aplikacja używa DB transactions z `SELECT FOR UPDATE` lub idempotency keys?

### Co MUSI być sprawdzone (10 punktów)

- [ ] Coupon redemption race
- [ ] Money transfer double-spending
- [ ] Voting (2 votes from same user)
- [ ] Username registration race (2 accounts same name)
- [ ] Product purchase race (2 buyers same item)
- [ ] Like/follow race (multiple likes)
- [ ] Withdrawal race (overdrafting)
- [ ] Single Packet Attack (50 simultaneous)
- [ ] Burp Turbo Intruder testing
- [ ] DB transaction isolation level review (with dev team)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md, Transaction_Authorization_Cheat_Sheet.md

### Race Condition — mechanizm

- **TOCTOU** (Time of Check to Time of Use): warunek sprawdzany w czasie T1, operacja wykonywana w T2
- Między T1 a T2 stan może się zmienić — np. saldo sprawdzone, ale zmienione przed przelewem
- Skutek: podwójne wykorzystanie kuponów, podwójna płatność, przekroczenie limitów

### Typowe scenariusze race condition w web

| Scenariusz | Skutek |
|------------|--------|
| Realizacja kuponu | Wielokrotne użycie jednorazowego kodu |
| Transfer środków | Podwójne obciążenie / double spending |
| Głosowanie | Wielokrotne głosy na tę samą opcję |
| Rejestracja unikalnego username | Dwa konta z tą samą nazwą |
| Rezerwacja / zakup | Dwa zamówienia na ten sam przedmiot |
| Like / follow | Wielokrotne polubienia |

### Obrona przed race conditions

- **Transakcje bazodanowe**: `SELECT ... FOR UPDATE` z `SERIALIZABLE` isolation level
- **Distributed locks**: Redis SETNX, database advisory locks
- **Optimistic locking**: version column w DB - update fails jeśli version changed
- **Idempotency keys**: unique key per operation - duplicate ignored
- **Atomic operations**: `INSERT ... ON CONFLICT DO NOTHING` (PostgreSQL), `INSERT IGNORE` (MySQL)
- **Single-flight pattern**: deduplicate concurrent requests dla same key

## Pentesterskie deep dive

### Mniej znane techniki

- **Single Packet Attack** (James Kettle, PortSwigger 2023): https://portswigger.net/research/smashing-the-state-machine - send 50+ HTTP/2 requests w jednym TCP packet, all arriving at server with sub-millisecond timing.
- **Compensation logic abuse**: w microservices saga pattern, atakujący może exploit window przed compensation.
- **Distributed cache race**: Redis cache invalidation race - stale data ważne briefly post-update.
- **JWT race**: token issued in one node, validated in another bez sync.

### Common pitfalls

- **Single-instance lock for distributed system**: mutex lokalny nie działa cross-server.
- **Eventual consistency w distributed DB**: reads from replica show stale data.

### Świeżynki z research

- **PortSwigger Race Conditions Lab**: https://portswigger.net/web-security/race-conditions
- **Smashing the State Machine** (James Kettle): https://portswigger.net/research/smashing-the-state-machine
- **HackTricks Race Conditions**: https://book.hacktricks.xyz/pentesting-web/race-condition

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Turbo Intruder | High-performance race testing |
| Race the Web | Burp built-in race tester |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/10-Business_Logic_Testing/04-Test_for_Process_Timing
- PortSwigger Smashing the State Machine: https://portswigger.net/research/smashing-the-state-machine
- HackTricks Race Conditions: https://book.hacktricks.xyz/pentesting-web/race-condition

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V11.1.6 | Application protects against race conditions. |
| V11.1.4 | Anti-automation controls. |
