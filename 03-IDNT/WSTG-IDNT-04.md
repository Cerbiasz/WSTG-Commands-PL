# WSTG-IDNT-04 — Testing for Account Enumeration and Guessable User Account

## Cel

Wykrycie miejsc gdzie aplikacja zdradza istnienie konta - przez różne komunikaty błędu ("User not found" vs "Wrong password"), różny status code, różny czas odpowiedzi (timing attack), różną długość response. Enumeracja userów = pivot do brute force / credential stuffing / phishing.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-idnt-04-account-enumeration.yaml
```

Szablon pasywnie wykrywa markery enumeracji w response body: "User not found", "Email already taken", username reflection w error.

### Active testing (manual)

```bash
# Burp Intruder z dwoma payloadami: known_user + unknown_user
# Compare: status, response length, response time, body diff

# ffuf differential
ffuf -u https://target/login \
     -X POST \
     -d "username=FUZZ&password=test123" \
     -w usernames.txt \
     -fs <baseline_size_for_unknown_user>
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| Login error markers ("User not found") | ✓ | — |
| Registration "username taken" | ✓ | — |
| Forgot password differential | ✓ | — |
| Username/email reflection w error | ✓ | — |
| Timing attack detection | — | manual statistical analysis |
| Status code differential | — | wymaga active known/unknown user |
| Response length differential | — | wymaga active testing |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (5 kroków)

1. **Passive scan**: nasz Nuclei szablon na zebranych responses.
2. **Active testing — login**: Burp Intruder z znanymi vs nieznanymi usernames, observe status/length/time differences.
3. **Active testing — registration**: try registering known existing email, check error message.
4. **Active testing — forgot password**: enter known vs unknown email, compare response.
5. **Timing analysis**: 100 requests known user + 100 unknown user, compare median latency (>50ms differential = leak).

### Co MUSI być sprawdzone (10 punktów)

- [ ] Login: same message dla unknown user vs wrong password
- [ ] Login: same status code (200 z error in body, nie 404)
- [ ] Login: same response time (dummy hash for unknown user)
- [ ] Login: same response length
- [ ] Registration: generic "verification email sent if available"
- [ ] Forgot password: ZAWSZE "If account exists, reset link sent"
- [ ] Public profile pages: czy ujawniają istnienie konta?
- [ ] API enumeration (`/api/users/{username}` returns 200 vs 404)
- [ ] GraphQL introspection allowed?
- [ ] Rate limiting per username (slow down brute force)

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Authentication_Cheat_Sheet.md

### Enumeracja użytkowników — dlaczego jest groźna

- Atakujący uzyskuje listę istniejących kont → może przeprowadzić: brute force, credential stuffing, phishing
- Enumeracja przez: login, rejestrację, forgot password, publiczne profile, API
- Każdy endpoint który odpowiada INACZEJ dla istniejącego vs nieistniejącego konta ujawnia informacje

### Obrona — generyczne komunikaty

- **Identyczny komunikat** dla istniejącego i nieistniejącego konta: "Invalid username or password"
- **Identyczny kod HTTP** — np. 200 z JSON body (nie 404 vs 200)
- **Identyczny czas odpowiedzi** — wykonaj hash hasła NAWET jeśli konto nie istnieje (timing attack)
- **Identyczna długość odpowiedzi** — unikaj różnic które można wykryć w Burp Intruder

### Typowe wektory enumeracji

- **Login**: "User not found" vs "Wrong password" — różne komunikaty
- **Rejestracja**: "Username already taken" — ujawnia istniejące konta
  - Obrona: "If this email is not registered, we'll send a confirmation"
- **Forgot password**: "Email not found" vs "Reset link sent" — różne komunikaty
  - Obrona: ZAWSZE "If an account exists, a reset link has been sent"
- **Timing**: sprawdzanie hasła trwa dłużej niż sprawdzanie czy user istnieje
  - Obrona: constant-time response — hashuj dummy password jeśli user nie istnieje

### Dodatkowe obrony

- **Rate limiting**: ogranicz próby logowania per IP/konto/globalnie
- **CAPTCHA**: po N nieudanych próbach
- **Account lockout**: po N próbach (z auto-odblokowaniem)
- **Monitoring**: alertuj na masowe próby enumeracji (wiele różnych username z jednego IP)
- **GraphQL introspection**: wyłącz na produkcji — może ujawniać typy i pola użytkowników

## Pentesterskie deep dive

### Mniej znane techniki

- **Timing attack via dummy hash**: aplikacje powinny wykonywać dummy bcrypt nawet dla unknown user → constant time. Jeśli różnica >50ms = leak.
- **Length-based enumeration**: nawet identyczny visible message, różnica w bytes (np. ID w error response) ujawnia.
- **OAuth / SSO enumeration**: niektóre OAuth providers ujawniają "Account not found" gdy user_id nie istnieje (Google was vulnerable historically).
- **GraphQL introspection enumeration**: `?query={users{username}}` ujawnia listę użytkowników jeśli authz nieproperly enforced.
- **Side-channel via 2FA challenge**: po valid username, 2FA challenge vs brak → ujawnia user existence.
- **Email aliasing test**: `user+test@gmail.com` vs `user@gmail.com` → niektóre aplikacje treat differently.

### Common pitfalls

- **"Generic message" but status differs**: "Invalid credentials" message but 200 vs 401 → enumeration via status.
- **Session cookie set on any login attempt**: cookie set → user exists; no cookie → unknown.
- **Response body length includes username echo**: `"Welcome unknown_user"` vs `"Welcome John"` → length diff.

### Świeżynki z research

- **Sam Curry OAuth research**: https://samcurry.net/
- **HackTricks Account Takeover**: https://book.hacktricks.xyz/pentesting-web/account-takeover
- **PortSwigger Authentication labs**: https://portswigger.net/web-security/authentication

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Reflector | Username reflection detection | [GitHub](https://github.com/elkokc/reflector) |
| Turbo Intruder | Timing attack detection (race + analysis) | [GitHub](https://github.com/PortSwigger/turbo-intruder) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/03-Identity_Management_Testing/04-Testing_for_Account_Enumeration_and_Guessable_User_Account
- OWASP Authentication CS: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- HackTricks Account Takeover: https://book.hacktricks.xyz/pentesting-web/account-takeover
- PortSwigger Auth labs: https://portswigger.net/web-security/authentication

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V2.1.10 | Password Security (L1) | Generic error messages for failed authentication. |
| V3.2.2 | Session (L2) | Session ID never disclosed in URL/error/log. |
