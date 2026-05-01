# WSTG-ATHN-10 — Testing for Weaker Authentication in Alternative Channel

## Cel

Audyt spójności zabezpieczeń między kanałami: web UI vs mobile API vs SSO/OAuth vs legacy API. Atakujący wybierze najsłabszy kanał — np. `/api/v1/login` bez MFA gdy `/login` (web) MFA wymaga.

> **Test mostly manual**: wymaga enumeration alternative channels.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Channel enumeration**: web UI, mobile app API, public REST API, internal API, GraphQL, SSO, legacy endpoints.
2. **Per channel auth flow**: dla każdego, prześledź auth flow - czy MFA wymagana?
3. **Rate limiting consistency**: czy każdy channel ma rate limit? (web zazwyczaj tak, API often nie).
4. **Legacy endpoint discovery**: `/api/v1/`, `/legacy/`, `/old/` - mogą być less protected.
5. **Mobile API analysis**: extract API URLs z app, sprawdź czy mają same auth jak web.

### Co MUSI być sprawdzone (10 punktów)

- [ ] Web vs API MFA consistency
- [ ] Rate limiting na każdym channel
- [ ] Legacy API endpoints (deprecated ale aktywne)
- [ ] Mobile API auth strength (PIN-only NIE wystarczy)
- [ ] OAuth/SSO bypass possibility
- [ ] WebDAV (jeśli włączone) - separate auth
- [ ] SOAP services (legacy enterprise)
- [ ] gRPC endpoints
- [ ] Internal API exposed via subdomain
- [ ] Backup channels (admin via SSH = out-of-scope ale documentation needed)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Multifactor_Authentication_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Spójność zabezpieczeń między kanałami

- **WSZYSTKIE kanały** (web, mobile app, API, SSO, legacy) MUSZĄ mieć równy poziom bezpieczeństwa
- Atakujący użyje NAJSŁABSZEGO kanału — np. stare API bez MFA, mobile app bez rate limiting
- Sprawdź czy stare wersje API (`/api/v1/`) nadal są dostępne i czy mają te same zabezpieczenia

### Typowe obejścia przez alternatywne kanały

- API endpoint bez MFA (web wymaga MFA, ale API nie)
- Mobile API z prostszym uwierzytelnieniem (np. PIN zamiast hasła + MFA)
- SSO/OAuth bypass — redirect na słabszy provider
- Legacy endpoints nadal aktywne po migracji
- Rate limiting na web ale nie na API

### Multi-Factor Authentication — hierarchia siły

- **WebAuthn/FIDO2** (najsilniejsze): hardware key, biometrics — phishing-resistant
- **TOTP** (silne): Google Authenticator, Authy — time-based OTP
- **Push notification** (dobre): approve/deny na telefonie
- **SMS OTP** (słabsze): podatne na SIM swap, SS7 attacks — ale lepsze niż nic
- **Email OTP** (najsłabsze z MFA): jeżeli email jest skompromitowany — MFA też

### Mobile App Considerations

- Mobile app MUSI używać tego samego standardu MFA co web
- Biometria (FaceID, fingerprint) **per device** — nie zastępuje server-side auth
- Token refresh w mobile app: krótki access token (15 min) + dłuższy refresh token z rotation

## Pentesterskie deep dive

### Mniej znane techniki

- **Mobile app token reuse on web**: extracted bearer token z mobile app może działać na web API → MFA bypass.
- **Legacy SOAP service bez MFA**: enterprise apps często mają SOAP `/services/Login` bez MFA jako legacy.
- **GraphQL enumeration via introspection**: GraphQL może mieć less restrictive authz than REST counterparts.
- **gRPC bez auth**: niektóre internal gRPC services rely on network isolation jako auth.

### Common pitfalls

- **"API only used by mobile app, doesn't need MFA"**: false sense of security - API publicly accessible.
- **OAuth provider weak**: enterprise app SSO przez weak provider (e.g., legacy Active Directory bez MFA).

### Świeżynki z research

- **OWASP MFA CS**: https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- **HackTricks Mobile App Pentesting**: https://book.hacktricks.xyz/mobile-pentesting

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis |
|---|---|
| Mobile Assistant | Inspect mobile app traffic |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/04-Authentication_Testing/10-Testing_for_Weaker_Authentication_in_Alternative_Channel
- OWASP MFA CS: https://cheatsheetseries.owasp.org/cheatsheets/Multifactor_Authentication_Cheat_Sheet.html
- HackTricks Mobile: https://book.hacktricks.xyz/mobile-pentesting

### Wskazówki ASVS

| ID | Wymaganie |
|---|---|
| V1.1.4 | Verified architecture and threat modeling. |
| V13.5.3 | All channels use identical authentication. |
