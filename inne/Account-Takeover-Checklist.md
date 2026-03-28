# Account Takeover — Checklist

Skondensowana checklista technik przejęcia konta z perspektywy pentestera.

## Via Password Reset
- Host Header Poisoning → reset link na attacker domain
- Email parameter manipulation (cc/bcc injection, JSON arrays)
- Token w Referer header, response body, wayback
- UUID v1 prediction (Sandwich Attack)
- Username collision (trailing spaces)

## Via Registration
- Email variations (case, dots, +tag, null bytes)
- Classic-Federated merge (pre-register before SSO)
- Trojan Identifier (secondary login path survives password reset)
- Non-Verifying IdP (`email_verified=false`)

## Via OAuth
- Redirect URI bypass → steal authorization code
- Missing/predictable `state` → CSRF login
- Token not bound to client → cross-app replay
- Mutable claims (email change → ATO via SSO)

## Via 2FA Bypass
- Direct navigation to post-2FA endpoint
- Cross-account OTP (not session-bound)
- Password reset disables 2FA
- Brute force (even after lockout, send valid OTP)

## Via Session
- Cookie tossing from controlled subdomain
- Session fixation (no rotation on login)
- JWT algorithm confusion (none/RS256→HS256)
- Cross-service JWT relay

## Via Race Condition
- Simultaneous email verification + change
- OAuth code reuse race
- Registration upsert race
