# Unicode Injection

## `\u` → `%` Substitution

Jeśli backend konwertuje `\u` prefix na `%`, to `\u003c` staje się `%3c` = `<` → inject arbitrary chars

## Emoji Encoding Confusion

`💋img src=x onerror=alert()//💛` — emoji powoduje charset mismatch (Windows-1252 → UTF-8 → ASCII//TRANSLIT) normalizujący do `<`

## Windows Best-Fit

Unicode chars mapped do `/` (0x2F) i `\` (0x5C): https://worst.fit/mapping/ → bypass path traversal blacklists

Fullwidth `"` (U+FF02) → `"` splits arguments w `escapeshellarg`/`subprocess.run`

Warunek: app musi użyć "W" Windows API (Unicode) ale wywoływać "A" API (ANSI) → trigger Best-Fit conversion
