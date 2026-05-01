# WSTG-APIT-01 — API Reconnaissance

## Cel

Discovery i mapping API: REST endpoints, GraphQL schema (przez introspection lub field suggestions), SOAP WSDL, OpenAPI/Swagger spec, gRPC reflection. Bez kompletnego mapowania nie można testować API authz/input validation.

## Automatyzacja Nuclei

### Nasze szablony

```bash
# GraphQL specific recon
nuclei -l burp-export.xml -im burp -t templates/wstg-apit-graphql.yaml

# API discovery (Swagger/OpenAPI/GraphQL)
nuclei -l burp-export.xml -im burp -t templates/wstg-info-04-attack-surface.yaml
```

### Suplementarne narzędzia

```bash
# Pull OpenAPI spec
curl -s https://target.com/api/swagger.json | jq

# GraphQL introspection (manual)
curl -X POST https://target.com/graphql \
     -H "Content-Type: application/json" \
     -d '{"query":"query{__schema{types{name}}}"}'

# graphw00f - GraphQL fingerprinting
graphw00f -t https://target.com/graphql

# Postman OpenAPI import
```

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **API discovery**: szukaj `/api`, `/api/v1`, `/swagger`, `/openapi.json`, `/graphql`, `/graphiql`, `/playground`.
2. **OpenAPI/Swagger pull**: jeśli dostępny, kompletna lista endpointów + schemas.
3. **GraphQL introspection**: `__schema` query → pełen schema.
4. **Mobile app reverse**: extract API endpoints z mobile binary.
5. **Wayback enumeration**: historyczne API endpoints.
6. **Doc/README check**: jeśli aplikacja ma `/docs`, `/api-docs`.

### Co MUSI być sprawdzone (10 punktów)

- [ ] `/swagger.json`, `/openapi.json`, `/api-docs` discovery
- [ ] `/graphql`, `/graphiql`, `/playground` accessible?
- [ ] GraphQL introspection enabled?
- [ ] GraphQL field suggestions enabled?
- [ ] gRPC reflection enabled (`/grpc.reflection.v1alpha.ServerReflection`)?
- [ ] WSDL exposed (`?wsdl`)?
- [ ] API versioning (`/api/v1`, `/api/v2`)
- [ ] Mobile app API endpoints (cross WSTG-INFO-08)
- [ ] Internal API endpoints (different subdomain)
- [ ] Hidden parameters via Param Miner

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — GraphQL_Cheat_Sheet.md, REST_Security_Cheat_Sheet.md

### GraphQL Security

- **Wyłącz introspection** na produkcji — nie ujawniaj całego schematu API atakującemu
- **Query depth limiting**: ogranicz zagnieżdżenie zapytań (np. max 10 levels) — zapobiegaj DoS
- **Query cost analysis**: przypisz koszty do pól i ogranicz całkowity koszt zapytania
- **Persisted queries**: akceptuj TYLKO pre-approved query hashes — eliminuje arbitrary queries
- **Autoryzacja per field/type** — nie tylko na poziomie endpointu, ale na każdym polu
- **Batch attack prevention**: ogranicz ilość operacji w jednym batch request
- **Rate limiting** na poziomie zapytań, nie requestów (1 request GraphQL = wiele operacji)

### REST API Security

- **Autentykacja**: OAuth 2.0 + JWT, API keys (TYLKO jako identyfikator, NIE jako jedyna auth)
- **Autoryzacja**: sprawdzaj uprawnienia na KAŻDYM endpoincie, KAŻDEJ metodzie HTTP
- **Input validation**: waliduj wszystkie parametry — typ, długość, format, zakres
- **Rate limiting**: ogranicz requesty per API key/IP/user — zapobiegaj abuse
- **OpenAPI documentation**: utrzymuj aktualne — opisz expected request/response

### gRPC Security

- **Reflection**: wyłącz na produkcji (jak GraphQL introspection)
- **mTLS**: wzajemna autentykacja klient-serwer
- **Authentication**: per-method, nie per-service

## Pentesterskie deep dive

### Mniej znane techniki

- **GraphQL aliasing for rate limit bypass**: `query{a:user(id:1),b:user(id:2),c:user(id:3)...}` - tysiące queries w jednym request.
- **GraphQL field suggestions enumeration**: nawet z introspection disabled, server podpowiada `Cannot query field "x" on type "Y". Did you mean "Z"?` → enumeruje fields.
- **gRPC reflection via grpcurl**: `grpcurl -plaintext target:50051 list` enumerates services.
- **OpenAPI/Swagger version with hidden endpoints**: `swagger.json` może mieć endpoints not exposed in UI.
- **REST API enumeration via Wayback**: `gau target.com | grep "/api/"` historical endpoints.

### Common pitfalls

- **GraphQL introspection enabled "for dev convenience"**: prod bez disable.
- **OpenAPI spec aktualne ale różne od kodu**: actual implementation odbiega od dokumentacji.
- **gRPC reflection forgotten on prod**: cluster Kubernetes z reflection.

### Świeżynki z research

- **graphw00f**: https://github.com/dolevf/graphw00f - GraphQL fingerprinting
- **PortSwigger GraphQL**: https://portswigger.net/web-security/graphql
- **HackTricks GraphQL**: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/graphql
- **OWASP API Top 10**: https://owasp.org/API-Security/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| InQL | GraphQL introspection + queries generator |
| Param Miner | Hidden API parameter discovery |
| OpenAPI Parser | Auto-import API endpoints |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/12-API_Testing/01-Testing_GraphQL
- OWASP GraphQL CS: https://cheatsheetseries.owasp.org/cheatsheets/GraphQL_Cheat_Sheet.html
- OWASP REST Security CS: https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html
- OWASP API Top 10: https://owasp.org/API-Security/
- HackTricks GraphQL: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/graphql
- PortSwigger GraphQL: https://portswigger.net/web-security/graphql

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V13.4.5 | API documentation not exposed unless intended. |
| V13.2.1 | Documented HTTP methods. |
| V13.4.2 | API endpoint authz checks. |
