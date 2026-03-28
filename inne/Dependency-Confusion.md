# Dependency Confusion

## Technika

1. Enumerate internal package names z: `package.json`, `requirements.txt`, `go.mod`, CI configs, JS bundles
2. Publish do public registry (npm/PyPI/NuGet) z **wyższą wersją** niż internal
3. Resolver wybiera public "best" version

## Execution

- **npm**: `preinstall`/`postinstall` scripts fire automatically
- **Python**: prefer import-time code (wheels nie zawsze run install scripts)
- **Exfil via DNS** jeśli HTTP egress blocked z CI

## Mitigation

- npm: `.npmrc` z `@company:registry=https://internal/`
- pip: `index-url` only internal, `--require-hashes`, NIE używaj `--extra-index-url` mixing trust
