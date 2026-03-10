# WSTG-APIT-99 — Testing GraphQL

## Cele

- Assess that a secure and production-ready configuration is deployed
- Validate all input fields against generic attacks
- Ensure that proper access controls are applied

## KOMENDY

### GraphQL Introspection

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { queryType { name } mutationType { name } types { name kind fields { name type { name kind } } } } }"}'

```

### Sprawdzenie czy introspection jest wlaczona

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { types { name } } }"}'

```

### Enumeracja queries

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { queryType { fields { name description args { name type { name } } } } } }"}'

```

### Enumeracja mutations

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ __schema { mutationType { fields { name args { name type { name } } } } } }"}'

```

### Batching attack

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '[{"query":"{ user(id:1) { email } }"},{"query":"{ user(id:2) { email } }"},{"query":"{ user(id:3) { email } }"}]'

```

### DoS via deep nesting

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ user { friends { friends { friends { friends { name } } } } } }"}'

```

### SQL Injection via GraphQL

```bash
curl -s "https://TARGET/graphql" -X POST -H "Content-Type: application/json" -d '{"query":"{ user(name:\"admin\\\" OR 1=1--\") { id email } }"}'

```

### InQL Burp Extension

```bash
# Zainstaluj InQL w Burp i wskaz endpoint GraphQL

```

### graphql-voyager

```bash
# Uzyj do wizualizacji schematu GraphQL

```

## KOMENDY Z WORDLISTAMI

### PayloadsAllTheThings GraphQL

```bash
# Referencja: Desktop/WSTG/PayloadsAllTheThings-master/GraphQL Injection/README.md

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj endpoint GraphQL (/graphql, /gql, /query)
2. Testuj introspection query
3. Zmapuj caly schemat (queries, mutations, types)
4. Testuj autoryzacje na kazdym query/mutation
5. Testuj injection (SQLi, XSS) w argumentach
6. Sprawdz batching i deep nesting limits
7. Testuj field suggestions (nawet jesli introspection jest wylaczona)
8. Uzyj InQL Burp extension do automatyzacji


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — GraphQL_Cheat_Sheet.md

### GraphQL Security — kluczowe zagrozenia

### Introspection — wylacz na produkcji

- Introspection ujawnia **caly schemat API** — typy, pola, argumenty, relacje
- Atakujacy moze zmapowac cale API bez dokumentacji
- **Wylacz introspection** na produkcji — wlacz tylko w dev/staging
- Nawet z wylaczona introspection: testuj **field suggestions** — czesc implementacji podpowiada nazwy pol

### Query Depth Limiting

- GraphQL pozwala na **nieograniczone zaglezanie** zapytan: `{user{friends{friends{friends...}}}}`
- Ustaw **max depth** (np. 10 levels) — zapobiegaj DoS
- Odrzucaj zapytania przekraczajace limit z jasnym bledem

### Query Cost Analysis

- Przypisz **koszt** do kazdego pola (np. lista = 10, scalar = 1)
- Oblicz calkowity koszt zapytania przed wykonaniem
- Ustaw **max cost** — odrzucaj drogie zapytania
- Alternatywa: **persisted queries** — akceptuj TYLKO pre-approved query hashes

### Batching Attack Prevention

- GraphQL pozwala na **wiele operacji** w jednym request (batch/aliasing)
- 1 request = 100 queries = ominięcie rate limiting (per request)
- Ogranicz ilosc operacji w batch (np. max 10)
- Rate limituj na poziomie **operacji**, nie requestow

### Autoryzacja

- Autoryzacja musi byc na **kazdym polu/typie** — nie tylko na poziomie endpointu
- Jeden endpoint GraphQL = wiele roznych danych = rozne uprawnienia
- Uzyj **field-level authorization** — sprawdzaj uprawnienia na kazdym resolverze
- N+1 problem: sprawdzaj autoryzacje na nested resources, nie tylko root

### Injection w GraphQL

- Argumenty GraphQL trafiaja do resolverow → **waliduj** jak kazdy input
- Testuj SQLi, NoSQLi, LDAP injection w argumentach zapytan
- Testuj XSS w danych zwracanych przez mutations

### gRPC Security

- Uzywaj TLS dla wszystkich kanalow gRPC — nie plain text
- Waliduj wiadomosci protobuf — sprawdzaj typy i zakresy pol
- Implementuj deadline/timeout na requestach
- Uwierzytelniaj przez mTLS lub JWT w metadata

## ROZSZERZENIA BURP SUITE

Brak dedykowanych rozszerzen Burp dla tego testu.
