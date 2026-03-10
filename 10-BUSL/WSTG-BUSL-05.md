# WSTG-BUSL-05 — Test Number of Times a Function Can Be Used Limits

## Cele

- Zidentyfikowac funkcje z limitami uzycia
- Przetestowac egzekwowanie limitow

## KOMENDY

### Testowanie ponownego uzycia kuponu

```bash
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50"
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50"
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50"

```

### Testowanie limitu proby logowania

```bash
for i in $(seq 1 20); do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST TARGET/login -d "user=admin&pass=wrong${i}")
    echo "Attempt $i: HTTP $RESPONSE"
done

```

### Testowanie limitu resetowania hasla

```bash
for i in $(seq 1 10); do
    curl -s -X POST TARGET/api/reset-password -d "email=victim@example.com"
    echo "Reset attempt $i"
done

```

### Testowanie limitu glosowan

```bash
for i in $(seq 1 10); do
    curl -s -X POST TARGET/api/vote -d "option=A" -H "Cookie: session=SESSION_TOKEN"
    echo "Vote $i"
done

```

### Testowanie limitu pobrania darmowego contentu

```bash
for i in $(seq 1 15); do
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" TARGET/api/free-download?file=ebook.pdf)
    echo "Download $i: HTTP $RESPONSE"
done

```

### Testowanie obejscia limitu przez zmiane parametrow

```bash
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50"
curl -v -X POST TARGET/api/redeem -d "coupon=discount50"
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50 "
curl -v -X POST TARGET/api/redeem -d "coupon= DISCOUNT50"

```

### Testowanie obejscia limitu przez rozne sesje

```bash
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50" -H "Cookie: session=SESSION1"
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50" -H "Cookie: session=SESSION2"

```

### Testowanie obejscia limitu przez rozne IP (proxy)

```bash
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50" -H "X-Forwarded-For: 1.1.1.1"
curl -v -X POST TARGET/api/redeem -d "coupon=DISCOUNT50" -H "X-Forwarded-For: 2.2.2.2"

```

### Burp Intruder - powtarzanie funkcji

```bash
# 1. Przechwytuj request z limitowana funkcja
# 2. Wyslij do Intruder -> Null Payloads (powtorz N razy)
# 3. Obserwuj odpowiedzi - kiedy limit zostanie osiagniety?

```

## KOMENDY Z WORDLISTAMI

### Brak dedykowanych wordlist - test oparty na logice limitu

```bash

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Zidentyfikuj funkcje z limitami: kupony, darmowe proby, glosowania, resetowanie hasla
2. W Burp Suite -> Intruder: powtarzaj request i monitoruj kiedy limit zadziala
3. Testuj obejscia: zmiana wielkosci liter, dodanie spacji, encoding
4. Testuj z roznych sesji/kont uzytkownikow
5. Testuj z roznych IP (naglosek X-Forwarded-For)
6. Sprawdz czy limit jest po stronie serwera (nie tylko frontend/cookie)
7. Testuj race condition na limitach (wiele requestow jednoczesnie)


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Abuse_Case_Cheat_Sheet.md, Authentication_Cheat_Sheet.md

### Limity uzycia — co ograniczac

- **Kupony/rabaty**: jednorazowe — per uzytkownik, per konto, per sesje
- **Darmowe proby**: trial period, free downloads — limit per konto/IP/urzadzenie
- **Glosowania**: jedna osoba = jeden glos — weryfikacja tozsamosci
- **Reset hasla**: max. X requestow na godzine — zapobiegaj email bombing
- **Logowanie**: lockout po N blednych probach
- **API calls**: rate limiting per API key/user/IP

### Techniki obejscia limitow — co testowac

| Technika | Opis |
|----------|------|
| Case manipulation | `COUPON50` vs `coupon50` vs `Coupon50` |
| Spacje | `" COUPON50"`, `"COUPON50 "`, `"COUPON 50"` |
| Encoding | `%43OUPON50` (URL encoded C) |
| Rozne sesje | Uzyj kuponu z sesji A, potem z sesji B |
| Rozne konta | Uzyj kuponu na koncie A, potem na koncie B |
| IP spoofing | `X-Forwarded-For: 1.1.1.1` — obejscie IP-based limitow |
| Race condition | Wiele requestow jednoczesnie — limit nie zdazyworkowac |
| Unicode confusables | `СOUPON50` (cyrylica C) vs `COUPON50` (lacinskie C) |

### Obrona

- Limity po stronie **serwera** — nie w cookie/localStorage
- Normalizuj dane przed sprawdzeniem: lowercase, trim, strip encoding
- Uzyj **atomic operations**: `UPDATE coupons SET used = true WHERE code = X AND used = false`
- Rate limiting per uzytkownik + per IP + per endpoint — warstwowo
- Loguj i alertuj na przekroczenie limitow — moze wskazywac na atak

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| Turbo Intruder | Masowe wysylanie requestow do testowania limitow | [BApp Store](https://portswigger.net/bappstore/9abfe09175d74b16842a3bbb0aa6a42c) |
