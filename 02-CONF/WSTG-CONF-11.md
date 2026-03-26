# WSTG-CONF-11 — Test Cloud Storage

## Cele

- Assess access control for cloud storage services (S3, Azure Blob, GCP)
- Identify publicly accessible storage buckets
- Find sensitive data in misconfigured cloud storage

## KOMENDY

### AWS S3 - sprawdzenie publicznych bucketow

```bash
aws s3 ls s3://TARGET --no-sign-request 2>&1 | tee output_s3_check.txt
aws s3 ls s3://TARGET-backup --no-sign-request 2>&1
aws s3 ls s3://TARGET-dev --no-sign-request 2>&1
aws s3 ls s3://TARGET-staging --no-sign-request 2>&1
aws s3 ls s3://TARGET-assets --no-sign-request 2>&1
aws s3 ls s3://TARGET-uploads --no-sign-request 2>&1
aws s3 ls s3://TARGET-data --no-sign-request 2>&1
aws s3 ls s3://TARGET-static --no-sign-request 2>&1
aws s3 ls s3://TARGET-public --no-sign-request 2>&1

```

### S3 via HTTP

```bash
curl -s https://TARGET.s3.amazonaws.com | tee output_s3_http.txt
curl -s https://s3.amazonaws.com/TARGET | tee output_s3_http2.txt

```

### Azure Blob Storage

```bash
curl -s "https://TARGET.blob.core.windows.net/\$root?restype=container&comp=list" | tee output_azure_blob.txt
curl -s "https://TARGET.blob.core.windows.net/?comp=list" | tee output_azure_blob_list.txt

```

### Google Cloud Storage

```bash
curl -s "https://storage.googleapis.com/TARGET" | tee output_gcs.txt
curl -s "https://www.googleapis.com/storage/v1/b/TARGET/o" | tee output_gcs_objects.txt

```

### cloud_enum - automatyczny skaner cloud storage

```bash
cloud_enum -k TARGET -l output_cloud_enum.txt

```

### S3Scanner

```bash
s3scanner scan --bucket TARGET | tee output_s3scanner.txt

```

### Nuclei - szablony cloud

```bash
nuclei -u https://TARGET -tags cloud -o output_nuclei_cloud.txt
nuclei -u https://TARGET -tags aws -o output_nuclei_aws.txt
nuclei -u https://TARGET -tags s3 -o output_nuclei_s3.txt

```

### Sprawdzenie Azure apps

```bash
curl -s https://TARGET.azurewebsites.net | head -10
curl -s https://TARGET.scm.azurewebsites.net | head -10

```

### GrayhatWarfare - wyszukiwanie otwartych bucketow

```bash
# Sprawdz recznie: https://buckets.grayhatwarfare.com/

```

### Szukanie bucket names w kodzie zrodlowym

```bash
curl -s https://TARGET | grep -oE "[a-zA-Z0-9_-]+\.s3\.amazonaws\.com" | sort -u | tee output_s3_in_source.txt
curl -s https://TARGET | grep -oE "[a-zA-Z0-9_-]+\.blob\.core\.windows\.net" | sort -u | tee output_azure_in_source.txt
curl -s https://TARGET | grep -oE "storage\.googleapis\.com/[a-zA-Z0-9_-]+" | sort -u | tee output_gcs_in_source.txt

```

## KOMENDY Z WORDLISTAMI

### Bug-Bounty-Wordlists EC2

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/ec2.txt -mc 200 -o output_ffuf_ec2.json

```

### Bug-Bounty-Wordlists K8s

```bash
ffuf -u https://TARGET/FUZZ -w Desktop/WSTG/Bug-Bounty-Wordlists-main/k8s.txt -mc 200 -o output_ffuf_k8s.json

```

### Brute-force nazw bucketow z common wordlist

```bash
# Generowanie nazw bucketow do sprawdzenia
for word in backup dev staging test data assets uploads static logs db; do echo "TARGET-$word"; echo "${word}-TARGET"; echo "TARGET${word}"; done > /tmp/bucket_names.txt
cat /tmp/bucket_names.txt | while read bucket; do echo "Sprawdzam: $bucket"; aws s3 ls s3://$bucket --no-sign-request 2>&1 | head -1; done | tee output_bucket_bruteforce.txt

```

## WERYFIKACJA MANUALNA (Burp Suite / Przegladarka / DevTools)

1. Szukaj odniesien do cloud storage w kodzie zrodlowym i plikach JS
2. Sprawdz subdomeny wskazujace na cloud storage (CNAME -> s3, blob, storage)
3. Sprobuj listowac zawartosc znalezionych bucketow
4. Sprawdz uprawnienia: read, write, list na znalezionych bucketach
5. Uzyj GrayhatWarfare (buckets.grayhatwarfare.com) do wyszukania publicznych bucketow
6. Sprawdz czy buckety pozwalaja na upload (ACL: public-read-write)
7. Przejrzyj pliki w dostepnych bucketach pod katem wrazliwych danych
8. Sprawdz SSRF do metadata endpoint (169.254.169.254) pod katem AWS credentials


---

## CHEATSHEET OWASP — Kluczowe wskazówki

> Źródło: OWASP CheatSheetSeries — Docker_Security_Cheat_Sheet.md, Attack_Surface_Analysis_Cheat_Sheet.md

### Cloud storage — typowe bledy konfiguracji

| Blad | Usluga | Konsekwencja |
|------|--------|-------------|
| Public ACL (read) | S3, GCS, Azure Blob | Kazdy moze czytac pliki — wyciek danych |
| Public ACL (write) | S3, GCS | Kazdy moze uploadowac pliki — malware hosting |
| Public ACL (list) | S3, GCS | Kazdy moze listowac pliki — rekonesans |
| Block Public Access wylaczony | AWS S3 | Buckety moga byc przypadkowo upublicznione |
| SAS token z szerokim scope | Azure Blob | Trwaly dostep do danych |
| Signed URL bez expiry | GCS | Permanentny dostep do prywatnych zasobow |

### AWS S3 — bezpieczenstwo

- Wlacz **S3 Block Public Access** na poziomie konta (Account-level)
- Uzyj **bucket policy** zamiast ACL — ACL sa legacy
- Wlacz **S3 Object Lock** dla krytycznych danych (WORM)
- Wlacz **server-side encryption** (SSE-S3, SSE-KMS, lub SSE-C)
- Wlacz **versioning** — ochrona przed przypadkowym usunieciem
- Wlacz **access logging** do osobnego bucketa
- Uzyj **VPC endpoints** zamiast publicznego dostepu

### Azure Blob Storage — bezpieczenstwo

- Ustaw **"Allow Blob public access"** na **Disabled** na koncie storage
- Uzyj **Azure AD authentication** zamiast shared keys
- Ogranicz **SAS tokeny**: krótki TTL, minimalny scope, IP restriction
- Wlacz **Soft Delete** i **Blob Versioning**
- Uzyj **Private Endpoints** zamiast publicznego dostepu

### GCP Cloud Storage — bezpieczenstwo

- Wlacz **Uniform Bucket-Level Access** (zamiast ACL per-obiekt)
- Nie nadawaj roli `allUsers` ani `allAuthenticatedUsers`
- Uzyj **VPC Service Controls** do ograniczenia dostepu
- Ustaw **retention policies** na bucketach z wrazliwymi danymi

### SSRF do metadata — kradzież credentials

| Cloud | Metadata endpoint | Co mozna zdobyc |
|-------|------------------|----------------|
| AWS | `http://169.254.169.254/latest/meta-data/iam/security-credentials/` | Temporary AWS credentials |
| Azure | `http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01` | Managed Identity token |
| GCP | `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token` | Service account token |

- AWS: wlacz **IMDSv2** (wymaga tokena PUT) — blokuje wiekszość SSRF
- GCP: wymaga naglowka `Metadata-Flavor: Google` — czesc ochrony
- Azure: wymaga naglowka `Metadata: true`

### Obrona

- Traktuj cloud storage jak publiczny endpoint — nie przechowuj danych wrazliwych bez szyfrowania
- Regularnie skanuj buckety: `aws s3api get-bucket-acl`, `az storage account show`
- Uzyj narzedzi: ScoutSuite, Prowler (AWS), az-security (Azure) do audytu
- Monitoruj CloudTrail/Activity Log pod katem nieautoryzowanego dostepu

## ROZSZERZENIA BURP SUITE

| Rozszerzenie | Opis | Link |
|---|---|---|
| AWS Extender | Testowanie bezpieczenstwa uslug AWS (S3, IAM, EC2) | [GitHub](https://github.com/VirtueSecurity/aws-extender) |
| Burp-AnonymousCloud | Wykrywanie publicznych zasobow chmurowych | [GitHub](https://github.com/initstring/cloud_enum) |

---

## Wskazówki ASVS

Powiązane wymagania z OWASP ASVS 5.0 — dobre praktyki do weryfikacji podczas testu.

### L2 (Standardowy)

| ID | Sekcja | Wymaganie |
|---|---|---|
| V13.3.1 | Secret Management | Verify that a secrets management solution, such as a key vault, is used to securely create, store, control access to, and destroy backend secrets. These could include passwords, key material, integrations with databases and third-party systems, keys and seeds for time-based tokens, other internal secrets, and API keys. Secrets must not be included in application source code or included in build artifacts. For an L3 application, this must involve a hardware-backed solution such as an HSM. |
| V13.3.2 | Secret Management | Verify that access to secret assets adheres to the principle of least privilege. |
