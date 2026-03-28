# Phone Number Injections

## SMS Injection

Gdy numer telefonu jest wstawiany do SMS message body:
- Inject CRLF: `+1234567890%0aYour code is: 1337` → ofiara widzi fałszywy kod
- OTP bypass: manipulacja numerem tak aby SMS poszedł na inny numer

## Caller ID Spoofing

Jeśli aplikacja waliduje tożsamość na podstawie caller ID → spoof z VoIP provider

## Premium Rate

Wstaw premium-rate number → aplikacja dzwoni/SMS → charge

## Normalization Issues

- `+1 (234) 567-8901` vs `12345678901` vs `+12345678901` — różne normalizacje mogą prowadzić do duplicate accounts lub bypass walidacji
