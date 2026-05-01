# WSTG-CONF-11 — Test Cloud Storage

## Cel

Identyfikacja niewłaściwie skonfigurowanych cloud storage buckets (AWS S3, Azure Blob, GCP Storage, DO Spaces) — public read/write/list, błędne ACL, długoterminowe SAS tokens, signed URLs bez expiry. Public bucket z dane = pełen wyciek.

## Automatyzacja Nuclei

### Nasz dedykowany szablon

```bash
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-conf-11-cloud-storage.yaml \
       -proxy http://127.0.0.1:8080 \
       -o results/wstg-conf-11.jsonl
```

Szablon wykrywa: AWS S3 bucket listing (ListBucketResult XML), AWS S3 access denied (signal że bucket istnieje), AWS S3 signature mismatch, Azure Blob listing (EnumerationResults), Azure auth required, GCP Storage JSON listing, GCP errors, DigitalOcean Spaces.

### Dodatkowe oficjalne szablony Nuclei

```bash
# AWS S3 misconfigurations
nuclei -l burp-export.xml -im burp \
       -tags aws,s3,bucket

# Cloud-specific
nuclei -l burp-export.xml -im burp \
       -t resources/nuclei-templates/cloud/

# IMDSv2 / metadata - jeśli SSRF (cross WSTG-INPV-19)
nuclei -l burp-export.xml -im burp \
       -t templates/wstg-inpv-19-ssrf.yaml
```

### Suplementarne narzędzia

```bash
# Cloud_enum - bucket discovery cross-cloud
cloud_enum -k <company-name> -t 10

# S3Scanner - dedicated S3
s3scanner scan --bucket <bucket-name>

# AWSBucketDump - download all readable S3
python3 AWSBucketDump.py -l buckets.txt -d results/

# GrayhatWarfare - public S3 search engine
# https://buckets.grayhatwarfare.com/
```

## Coverage Matrix

| Wymiar | Pokryte | Nie pokryte |
|---|---|---|
| AWS S3 (listing/access denied/signature) | ✓ | ACL granular check (cloud_enum) |
| Azure Blob (listing/auth) | ✓ | SAS token analysis |
| GCP Storage (JSON listing) | ✓ | Service account JSON exfil |
| DigitalOcean Spaces | ✓ | — |
| Cloud metadata via SSRF | — | WSTG-INPV-19 |
| Bucket name enumeration (company-related) | — | cloud_enum, GrayhatWarfare |
| IAM credentials w bucket files | — | manual deep grep |

## Standard pentesterski — jak to robi się wzorowo

### Metodologia (6 kroków)

1. **Identify cloud storage URLs**: z WSTG-INFO-05 (content leakage) — cloud URLs hardcoded w JS/HTML.
2. **Direct probe**: każdy cloud URL → nasz szablon Nuclei.
3. **Bucket enumeration**: `cloud_enum -k <company>` — common naming patterns (`<company>-backup`, `<company>-logs`, `<company>-staging`).
4. **List + download**: dla public buckets, list contents + grep for keys/credentials.
5. **Cross-cloud check**: każdy company name w AWS/Azure/GCP/DO simultaneously.
6. **SSRF pivot**: jeśli aplikacja ma SSRF (z INPV-19), używać do uderzenia w cloud metadata endpoint = IAM credentials.

### Co MUSI być sprawdzone (10 punktów)

- [ ] AWS S3: bucket listing public (`?list-type=2`)
- [ ] AWS S3: write permissions test (`PUT object` na nieistniejący key)
- [ ] AWS S3: ACL public-read on objects
- [ ] Azure Blob: container public access
- [ ] Azure Blob: SAS tokens w URLs (z aplikacji JS) — sprawdzić expiry/scope
- [ ] GCP Storage: bucket public access
- [ ] DigitalOcean Spaces
- [ ] Bucket name enumeration cross-cloud (cloud_enum)
- [ ] Cloud metadata leak via SSRF (cross-ref INPV-19)
- [ ] IAM credentials hardcoded w app (cross-ref INFO-05)

### Per cloud — typowe ścieżki ataku

| Cloud | Ścieżka ataku |
|---|---|
| AWS S3 | Public bucket → list keys → grep secrets/dumps; lub PUT (write) → host malware |
| AWS Lambda | SSRF → metadata → IAM creds → AssumeRole → broader access |
| Azure Blob | Public container → enumerate; SAS token wide-scope w URL |
| GCP Storage | Public bucket → list; service account JSON w bucket = takeover |
| Kubernetes | SSRF → token API server (192.168.x lub 10.x service IP) |

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Docker_Security_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Cloud storage — typowe błędy konfiguracji

| Błąd | Usługa | Konsekwencja |
|------|--------|-------------|
| Public ACL (read) | S3, GCS, Azure Blob | Każdy może czytać pliki — wyciek danych |
| Public ACL (write) | S3, GCS | Każdy może uploadować pliki — malware hosting |
| Public ACL (list) | S3, GCS | Każdy może listować pliki — rekonesans |
| Block Public Access wyłączony | AWS S3 | Buckety mogą być przypadkowo upublicznione |
| SAS token z szerokim scope | Azure Blob | Trwały dostęp do danych |
| Signed URL bez expiry | GCS | Permanentny dostęp do prywatnych zasobów |

### AWS S3 — bezpieczeństwo

- Włącz **S3 Block Public Access** na poziomie konta (Account-level)
- Użyj **bucket policy** zamiast ACL — ACL są legacy
- Włącz **S3 Object Lock** dla krytycznych danych (WORM)
- Włącz **server-side encryption** (SSE-S3, SSE-KMS, lub SSE-C)
- Włącz **versioning** — ochrona przed przypadkowym usunięciem
- Włącz **access logging** do osobnego bucketa
- Użyj **VPC endpoints** zamiast publicznego dostępu

### Azure Blob Storage — bezpieczeństwo

- Ustaw **"Allow Blob public access"** na **Disabled** na koncie storage
- Użyj **Azure AD authentication** zamiast shared keys
- Ogranicz **SAS tokeny**: krótki TTL, minimalny scope, IP restriction
- Włącz **Soft Delete** i **Blob Versioning**
- Użyj **Private Endpoints** zamiast publicznego dostępu

### GCP Cloud Storage — bezpieczeństwo

- Włącz **Uniform Bucket-Level Access** (zamiast ACL per-obiekt)
- Nie nadawaj roli `allUsers` ani `allAuthenticatedUsers`
- Użyj **VPC Service Controls** do ograniczenia dostępu
- Ustaw **retention policies** na bucketach z wrażliwymi danymi

### SSRF do metadata — kradzież credentials

| Cloud | Metadata endpoint | Co można zdobyć |
|-------|------------------|----------------|
| AWS | `http://169.254.169.254/latest/meta-data/iam/security-credentials/` | Temporary AWS credentials |
| Azure | `http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01` | Managed Identity token |
| GCP | `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token` | Service account token |

- AWS: włącz **IMDSv2** (wymaga tokena PUT) — blokuje większość SSRF
- GCP: wymaga nagłówka `Metadata-Flavor: Google` — część ochrony
- Azure: wymaga nagłówka `Metadata: true`

### Obrona

- Traktuj cloud storage jak publiczny endpoint — nie przechowuj danych wrażliwych bez szyfrowania
- Regularnie skanuj buckety: `aws s3api get-bucket-acl`, `az storage account show`
- Użyj narzędzi: ScoutSuite, Prowler (AWS), az-security (Azure) do audytu
- Monitoruj CloudTrail/Activity Log pod kątem nieautoryzowanego dostępu

## Pentesterskie deep dive

### Mniej znane techniki

- **S3 bucket takeover via NoSuchBucket**: aplikacja CDN-style serwuje content z bucket; jeśli bucket usunięty, atakujący tworzy nowy z tą samą nazwą = przejmuje cały content delivery.
- **Cross-account S3 ACL abuse**: bucket grants access to specific AWS account IDs. Jeśli atakujący zna ID, może przybić jako trusted account (rare ale istnieje).
- **Pre-signed URL replay**: pre-signed URLs (S3/GCS) z długim expiry (>1h) wycieknięte w logs / referrer headers = persistent access.
- **Lambda environment variables w response**: jeśli aplikacja Lambda ma SSRF lub error przekraczający granice → env variables (zawierają IAM tokens via temporary creds) leak w response.
- **GCP service account JSON in bucket**: częsty błąd — admin uploaduje `service-account.json` do bucket dla "łatwego dostępu" → public bucket = takeover całego service account.
- **Azure Storage Explorer abuse via SAS**: SAS token z `?sig=` może być replay'owany z innej IP gdy ip-restriction nie ustawiony.

### Common pitfalls

- **Path-style vs virtual-host-style**: `https://s3.amazonaws.com/bucket/key` vs `https://bucket.s3.amazonaws.com/key` — różne backendy mogą reagować różnie. Test obu.
- **Bucket names case-sensitive**: AWS S3 bucket names muszą być lowercase; Azure tolerantny. Brute force potrzebuje casing-aware wordlist.
- **CloudFront przed S3 maskuje origin**: bucket jest privatny ale CloudFront pozwala public read. CDN cache shadowing.
- **Region-specific endpoints**: `s3.us-west-2.amazonaws.com` vs `s3-eu-west-1.amazonaws.com` — testuj kilka regionów.

### Świeżynki z research

- **AWS Lambda SSRF → IAM keys** — community pattern na bug bounty.
- **GitHub workflow secrets exfil via S3** — community research.
- **HackingTheCloud (collaborative project)**: https://hackingthe.cloud/
- **HackTricks AWS Pentesting**: https://cloud.hacktricks.xyz/pentesting-cloud/aws-pentesting
- **GrayhatWarfare** (public S3 search): https://buckets.grayhatwarfare.com/

## Rozszerzenia Burp Suite

| Rozszerzenie | Opis | Link |
|---|---|---|
| AWS Signer | Sign requests dla AWS API | community ext |

## Źródła

- WSTG: https://owasp.org/www-project-web-security-testing-guide/v42/4-Web_Application_Security_Testing/02-Configuration_and_Deployment_Management_Testing/11-Test_Cloud_Storage
- HackingTheCloud: https://hackingthe.cloud/
- HackTricks AWS Pentesting: https://cloud.hacktricks.xyz/pentesting-cloud/aws-pentesting
- HackTricks Buckets: https://book.hacktricks.xyz/network-services-pentesting/pentesting-web/buckets
- cloud_enum: https://github.com/initstring/cloud_enum
- S3Scanner: https://github.com/sa7mon/S3Scanner
- GrayhatWarfare: https://buckets.grayhatwarfare.com/
- ScoutSuite (multi-cloud audit): https://github.com/nccgroup/ScoutSuite

### Wskazówki ASVS

| ID | Sekcja | Wymaganie |
|---|---|---|
| V14.1.5 | Configuration (L2) | Build pipeline removes development artifacts. |
| V8.3.4 | Sensitive Data (L1) | Encrypt sensitive data at rest. |
| V13.4.5 | Information Leakage (L2) | Documentation/monitoring endpoints not exposed. |
