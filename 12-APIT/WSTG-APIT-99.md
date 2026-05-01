# WSTG-APIT-99 — Testing GraphQL

## Cel

Audyt GraphQL: introspection, query depth limiting, query cost analysis, batch attacks, authorization per field, alias enumeration, GraphiQL/Playground exposure.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp -t templates/wstg-apit-graphql.yaml
```

Wykrywa: GraphQL endpoint discovery, GraphiQL/Playground UI, introspection enabled, field suggestions enabled.

### Suplementarne narzędzia

```bash
# graphw00f - GraphQL fingerprinting (engine type)
graphw00f -t https://target.com/graphql

# InQL Burp extension - introspection + query generator

# Manual introspection
curl -X POST https://target.com/graphql \
     -H "Content-Type: application/json" \
     -d '{"query":"query{__schema{types{name,fields{name,type{name}}}}}"}'
```

## Coverage Matrix

| Wymiar | Pokryte |
|---|---|
| GraphQL endpoint discovery | ✓ |
| GraphiQL/Playground UI exposure | ✓ |
| Introspection enabled | ✓ |
| Field suggestions enabled | ✓ |
| Query depth limit | manual |
| Query cost analysis | manual |
| Batch attack | manual via Burp |
| Per-field authorization | manual |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (8 kroków)

1. **Endpoint discovery**: `/graphql`, `/api/graphql`, `/playground`, `/altair`.
2. **GraphiQL UI exposure**: czy interactive UI dostępne (zazwyczaj tylko dev)?
3. **Introspection check**: pełen schema dump → mapowanie API.
4. **Field suggestions**: `query{nonexistent}` → "Did you mean..." enumeration.
5. **Query depth attack**: `query{user{posts{user{posts{...}}}}}` 100 levels - DoS?
6. **Alias attack**: `query{a:user(id:1),b:user(id:2)...}` - mass enum + rate limit bypass.
7. **Batch query**: array of queries `[{query:...},{query:...}]` - DoS via batch.
8. **Per-field authz**: czy każdy field ma authz check?

### Co MUSI być sprawdzone (12 punktów)

- [ ] Introspection disabled na produkcji
- [ ] Field suggestions disabled
- [ ] GraphiQL/Playground disabled na produkcji
- [ ] Query depth limit enforced (max 10)
- [ ] Query cost analysis (max cost limit)
- [ ] Persisted queries (allowlist hashes)
- [ ] Batch query limit
- [ ] Rate limit per query type (nie tylko per request)
- [ ] Authorization per field
- [ ] No DoS via deep query
- [ ] gRPC reflection (jeśli aplikacja gRPC) - patrz APIT-01
- [ ] HTTP method GET disabled (CSRF risk - GraphQL via GET)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — GraphQL_Cheat_Sheet.md

### GraphQL Security — kluczowe zagrożenia

### Introspection — wyłącz na produkcji

- Introspection ujawnia **cały schemat API** — typy, pola, argumenty, relacje
- Atakujący może zmapować całe API bez dokumentacji
- **Wyłącz introspection** na produkcji — włącz tylko w dev/staging
- Nawet z wyłączoną introspection: testuj **field suggestions** — część implementacji podpowiada nazwy pól

### Query Depth Limiting

- GraphQL pozwala na **nieograniczone zagłębianie** zapytań: `{user{friends{friends{friends...}}}}`
- Ustaw **max depth** (np. 10 levels) — zapobiegaj DoS
- Odrzucaj zapytania przekraczające limit z jasnym błędem

### Query Cost Analysis

- Przypisz **koszty** do pól (np. simple field = 1, list = 10, deep nested = 100)
- Ogranicz **całkowity koszt** zapytania (np. max 1000 points)
- Reject queries powyżej cost limit

### Persisted Queries

- Akceptuj TYLKO **pre-approved query hashes** zamiast arbitrary queries
- Klient wysyła `?queryHash=abc123` zamiast pełnego query
- Eliminuje arbitrary queries — atakujący nie może wysłać własnego

### Per-field Authorization

- Sprawdzaj uprawnienia na **każdym polu** — nie tylko na poziomie endpoint
- Atakujący może użyć wewnętrznego pola do bypass authz: `query{user{adminNotes}}`
- Implementuj middleware który checks per-field

### Batch Attack Prevention

- Ogranicz ilość **operacji w jednym request** (max 1-2 batched queries)
- Atakujący może wysłać 1000 queries w jednym request → DoS lub rate limit bypass
- Implementuj limit + monitoring

### Aliasy — denial of wallet

- GraphQL aliases pozwalają na: `{a:user(id:1),b:user(id:2),c:user(id:3)...}`
- Atakujący może wysłać 10000 aliasów w jednym query — DoS
- Ogranicz **liczbę aliasów** w query (np. max 10)

## Pentesterskie deep dive

### Mniej znane techniki

- **graphw00f fingerprinting**: identyfikuje engine (Apollo/HotChocolate/Hasura/...) - per-engine specific exploits.
- **GraphQL via GET (CSRF)**: niektóre aplikacje akceptują query w GET param → CSRF attack.
- **`__schema` partial query**: nawet z disabled introspection, niektóre aplikacje pozwalają na `query{__type(name:"User"){fields{name}}}`.
- **Field duplication for amplification**: `query{user{name}user{name}user{name}...}` × 1000 → amplification.
- **Mutation in query**: aplikacja zezwala na mutation w query parser - bypass read-only context.
- **Hasura privilege escalation**: Hasura specific - JWT manipulation w `x-hasura-role`.

### Common pitfalls

- **Introspection enabled "for development"**: prod też ma to enabled.
- **GraphiQL on prod path**: leftover from dev deployment.
- **Authz tylko na top-level query**: nested fields bez check.

### Świeżynki z research

- **graphw00f**: https://github.com/dolevf/graphw00f
- **PortSwigger GraphQL Lab**: https://portswigger.net/web-security/graphql
- **HackTricks GraphQL**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/graphql
- **OWASP GraphQL CS**: https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| InQL | GraphQL introspection + queries |
| GraphQL Raider | Manual exploitation |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/12-API_Testing/01-Testing_GraphQL
- OWASP GraphQL CS: https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html
- PortSwigger GraphQL: https://portswigger.net/web-security/graphql
- HackTricks GraphQL: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/graphql
- graphw00f: https://github.com/dolevf/graphw00f
- InQL: https://github.com/doyensec/inql

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V13.4.5 | API documentation not exposed unless intended. |
| V13.2.1 | Documented HTTP methods. |
| V4.1.1 | Access control rules at trusted layer. |
