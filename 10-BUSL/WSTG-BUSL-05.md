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

