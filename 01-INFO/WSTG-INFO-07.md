# WSTG-INFO-07 — Map Execution Paths Through Application

## Cel

Mapowanie ścieżek wykonania aplikacji — wieloetapowych workflows (rejestracja, zakup, reset hasła), data flow, trust boundaries i state transitions. Bez tej mapy nie można testować logiki biznesowej (BUSL) ani wykryć race conditions czy step-skipping.

> **Test manual-only**: workflow mapping wymaga zrozumienia logiki biznesowej i kontekstu — automatyzacja Nuclei nie ma tu zastosowania. Crawler odkrywa endpointy, ale nie sekwencję ich wywołań.

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (7 kroków)

1. **Identyfikacja krytycznych workflow**: rejestracja, logowanie, password reset, zakup, zmiana roli, upload, eksport, anulowanie subskrypcji.
2. **Sequence diagram per workflow**: zapisz każdy request, response, state change. Burp Logger++ + Burp Repeater grupowanie.
3. **Roles testing**: każdy workflow przejdź jako admin, user, guest, anonymous — różnice ujawniają kontrole dostępu i potencjalne IDORs.
4. **Step skipping test**: spróbuj przejść od step N do step N+2 z pominięciem N+1 (np. od koszyka do confirmation z pominięciem płatności).
5. **State manipulation**: zmodyfikuj client-side state (cookies, localStorage, hidden fields) między krokami i obserwuj czy server akceptuje.
6. **Race condition probing**: wyślij 2 równoczesne requesty w krytycznym momencie (np. dwa razy "redeem voucher" → 2 vouchery zamiast 1). Burp Turbo Intruder.
7. **Backward replay**: powtórz krok N po krokach N+1, N+2 — czy rozwala stan? Czy aplikacja anuluje finalizację?

### Co MUSI być sprawdzone (12 punktów)

- [ ] Workflow rejestracji: każdy krok udokumentowany (request, params, response, state)
- [ ] Workflow logowania: pre-auth state, MFA challenge, post-auth state
- [ ] Workflow password reset: email flow, token format, expiration
- [ ] Workflow zakupu: koszyk → płatność → potwierdzenie → faktura
- [ ] Workflow zmiany hasła (authenticated)
- [ ] Workflow zmiany emaila (verification challenge)
- [ ] Workflow anulowania subskrypcji
- [ ] Workflow upload pliku: pre-validation, validation, storage, retrieval
- [ ] Każdy workflow przejdzony jako admin / user / guest
- [ ] Step skipping test per workflow (np. anonymous → confirmation page)
- [ ] State stored client-side identyfikowane (cookies, localStorage, JWT claims)
- [ ] Race condition windows zidentyfikowane (każdy "atomic operation" w UI)

### Per stack — gdzie szukać state

| Architektura | Storage state | Ryzyko |
|---|---|---|
| Server-rendered (Spring/Django/Rails) | Server session | Najmniejsze - jeśli session secure |
| SPA + REST | JWT w localStorage / cookie | JWT manipulation, XSS → token theft |
| Stateless API + JWT | Klient state w JWT claims | JWT confusion, claim manipulation |
| Server Components (Next.js, Remix) | Server-side state via cookies | Cookie tampering, CSRF |
| Microservices + saga pattern | Distributed state, eventual consistency | Race conditions, partial commits |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Attack_Surface_Analysis_Cheat_Sheet.md, Threat_Modeling_Cheat_Sheet.md

### Mapowanie ścieżek — co dokumentować

| Element | Opis | Przykład |
|---------|------|---------|
| Workflow | Wieloetapowy proces biznesowy | Rejestracja → weryfikacja email → profil |
| Data flow | Przepływ danych między komponentami | Frontend → API → baza danych |
| Trust boundaries | Granice zaufania | Publiczny internet → WAF → DMZ → backend |
| Entry/Exit points | Wejścia i wyjścia danych | Formularze, API, webhooks, eksporty |
| Roles | Różne ścieżki dla różnych ról | Admin vs user vs guest |
| State transitions | Zmiany stanu obiektu | Zamówienie: draft → paid → shipped → delivered |

### Krytyczne workflows do mapowania

| Workflow | Dlaczego krytyczny | Na co testować |
|----------|-------------------|---------------|
| Rejestracja | Tworzenie konta | Enumeration, mass registration, bypass weryfikacji |
| Logowanie | Autentykacja | Brute force, credential stuffing, bypass MFA |
| Reset hasła | Odzyskanie dostępu | Token prediction, email injection, race condition |
| Zakup/płatność | Transakcja finansowa | Price manipulation, race condition, bypass kroku |
| Zmiana roli/uprawnień | Eskalacja uprawnień | IDOR, mass assignment, privilege escalation |
| Upload plików | Wgrywanie treści | RCE, XSS, path traversal |
| Eksport danych | Pobieranie danych | IDOR, information disclosure, injection |

### Techniki mapowania

- **Ręczny crawling**: klikaj w każdy link, przycisk, formularz z włączonym Burp
- **Automatyczny spider**: Burp Spider, ZAP Spider, Katana, Gospider
- **Analiza JS**: LinkFinder, JSParser — odkrywanie endpointów ukrytych w JavaScript
- **Historyczne URL**: GAU, Waybackurls — ścieżki z archive.org
- **Porównanie ról**: mapuj aplikację jako admin, user, guest — różnice ujawniają kontrole dostępu

### State machine — analiza wieloetapowych procesów

1. Zidentyfikuj wszystkie **stany** w procesie (np. koszyk → płatność → potwierdzenie)
2. Sprawdź czy można **pominąć krok** (np. przejść od koszyka do potwierdzenia)
3. Sprawdź czy można **cofnąć się** i zmodyfikować dane po zatwierdzeniu
4. Sprawdź czy stan jest przechowywany **server-side** (bezpieczne) czy **client-side** (niebezpieczne)
5. Testuj **race conditions** — równoczesne zapytania w krytycznych momentach

### Obrona

- Wymuszaj kolejność kroków server-side — nie polegaj na client-side routing
- Użyj tokenów sesji do śledzenia stanu procesu wieloetapowego
- Implementuj timeout dla niedokończonych procesów
- Loguj i monitoruj nietypowe ścieżki przepływu (pominięcie kroku, cofanie)

## Pentesterskie deep dive

### Mniej znane techniki

- **Single packet attack** (James Kettle, PortSwigger): wysłanie wielu requestów w jednym pakiecie HTTP/2 → minimalna różnica w timing → race condition na poziomie pojedynczego "tick" serwera. Standard dla collision detection w nowoczesnym pentestingu.
- **Step skipping przez direct URL**: niektóre aplikacje renderują strony confirmacji bez weryfikacji że poprzedni krok został zatwierdzony. `/checkout/confirmation/<order_id>` może być dostępny bez `/checkout/payment`.
- **Session fixation w workflow**: jeśli session ID nie jest regenerowany przy step transition (np. anonymous → registered), atakujący może podać victim swój session ID przed login.
- **Workflow restart attack**: zaczynam workflow A (np. password reset) ale w środku robię workflow B (np. login z innym kontem) — czy kontekst się myli? Często race między dwoma sesjami.
- **Idempotency key abuse**: API z `Idempotency-Key` header — wysyłka dwóch różnych body z tym samym key → który wygrywa? Stripe-style idempotency.

### Common pitfalls

- **Burp Spider ignoruje POST workflows**: spider klika linki ale nie wypełnia formularzy. Manual + Site Map jest niezastąpiony.
- **Crawler nie zna semantyki**: spider wejdzie w "logout" i zniszczy sesję — Burp Spider scope musi wykluczać destrukcyjne URL.
- **Single Page Apps i state**: SPA może przechowywać critical state w Redux store, który Burp nie widzi. DevTools Redux Inspector + manual capture.
- **Ignorowanie WebSocket flow**: dla aplikacji real-time (chat, trading), WebSocket jest głównym kanałem — Burp WebSockets History musi być przejrzana w pełni.
- **Server-Sent Events (SSE)**: niektóre workflows używają SSE do push notifications po zakończonym kroku. Skanery często ignorują.

### Świeżynki z research

- **Single-packet race conditions** (James Kettle, 2023): https://portswigger.net/research/smashing-the-state-machine - paradigmatyczna technika.
- **Browser-Powered Desync Attacks**: https://portswigger.net/research/browser-powered-desync-attacks
- **Saga pattern attacks** — community research; w microservices saga compensation logic może być eksploitowana (np. przelew udany, kompensacja nigdy nie wykonana).
- **JWT replay across services** — community pattern; w microservices JWT może być akceptowany przez nieprzewidziane serwisy.
- **HackTricks Race Conditions**: https://book.hacktricks.xyz/pentesting-web/race-condition

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| Burp DOM Scanner | Rekursywny crawl SPA z headless | [GitHub](https://github.com/fcavallarin/burp-dom-scanner) |
| Logger++ | Zaawansowane logowanie + filtering per workflow | [GitHub](https://github.com/PortSwigger/logger-plus-plus) |
| Turbo Intruder | High-performance fuzzing dla race conditions | [GitHub](https://github.com/PortSwigger/turbo-intruder) |
| Stepper | Sekwencyjne wykonywanie wieloetapowych workflow | [GitHub](https://github.com/CoreyD97/Stepper) |
| HTTP Request Smuggler | Detekcja smugglingu = ujawnia hidden state | [GitHub](https://github.com/PortSwigger/http-request-smuggler) |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/01-Information_Gathering/07-Map_Execution_Paths_Through_Application
- OWASP Threat Modeling Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
- HackTricks Race Conditions: https://book.hacktricks.xyz/pentesting-web/race-condition
- PortSwigger — Smashing the State Machine: https://portswigger.net/research/smashing-the-state-machine
- PortSwigger Web Security Academy — Race conditions: https://portswigger.net/web-security/race-conditions

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V11.1.1 | Business Logic Flow Security (L1) | Application processes business logic flows in sequential order. |
| V11.1.2 | Business Logic Flow Security (L1) | Application processes business logic flows with all steps performed. |
| V11.1.4 | Business Logic Flow Security (L1) | Anti-automation controls protect against excessive function calls. |
