#!/usr/bin/env bash
# ============================================================================
# run-wstg-suite.sh - Główny skrypt uruchomieniowy WSTG Nuclei Suite
# ============================================================================
#
# Uruchamia kompleksową suite testów WSTG przeciwko aplikacji webowej.
# Akceptuje Burp export (XML), OpenAPI/Swagger spec, lub URL list.
#
# Bezpieczeństwo:
# - Domyślnie używa proxy http://127.0.0.1:8080 (Burp)
# - Domyślnie -c 5 -rate-limit 50 (zachowawcze)
# - Domyślnie BEZ destrukcyjnych payloads (musisz podać --include-destructive)
# - Auth handling: -V auth_token / -V session_cookie wstrzykiwane przez wrapper
#
# Użycie:
#   ./run-wstg-suite.sh -i burp-export.xml -o results/
#   ./run-wstg-suite.sh -i burp-export.xml -o results/ --category INPV
#   ./run-wstg-suite.sh -i burp-export.xml -o results/ --test WSTG-INPV-05
#   ./run-wstg-suite.sh --openapi spec.yaml -o results/
#   ./run-wstg-suite.sh -i burp.xml -o results/ --auth-token "Bearer eyJ..."
#   ./run-wstg-suite.sh -i burp.xml -o results/ --no-proxy
#   ./run-wstg-suite.sh -i burp.xml -o results/ --include-destructive
# ============================================================================

set -euo pipefail

# =====================
# Defaults
# =====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$REPO_ROOT/templates"
OFFICIAL_TEMPLATES_DIR="$REPO_ROOT/../resources/nuclei-templates"  # adjust per env

INPUT_FILE=""
INPUT_TYPE="burp"  # burp | openapi | list
OUTPUT_DIR="results-$(date +%Y%m%d-%H%M%S)"
PROXY="http://127.0.0.1:8080"
USE_PROXY=1
CONCURRENT=5
RATE_LIMIT=50
AUTH_TOKEN=""
SESSION_COOKIE=""
CATEGORY=""
TEST=""
INCLUDE_DESTRUCTIVE=0
INCLUDE_OFFICIAL=0
TIMEOUT=15
VERBOSE=0

# =====================
# Help
# =====================
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

REQUIRED (one of):
  -i, --input FILE          Burp XML export file
  --openapi FILE            OpenAPI/Swagger spec (yaml/json)
  --list FILE               URL list (one per line)

OPTIONS:
  -o, --output DIR          Output directory (default: results-DATE)
  -c, --concurrent N        Concurrent threads (default: 5)
  --rate-limit N            Requests per second (default: 50)
  --proxy URL               HTTP proxy (default: http://127.0.0.1:8080)
  --no-proxy                Disable proxy (CI/CD mode)

  --category CAT            Run only category (INFO/CONF/IDNT/ATHN/ATHZ/SESS/INPV/ERRH/CRYP/BUSL/CLNT/APIT)
  --test TEST_ID            Run single test (e.g., WSTG-INPV-05)

  --auth-token TOKEN        Authorization header value (e.g., "Bearer eyJ...")
  --session-cookie COOKIE   Session cookie value

  --include-destructive     Allow destructive operations (DELETE, drops, etc.)
  --include-official        Include curated nuclei-templates from official repo
  --timeout N               Request timeout seconds (default: 15)

  -v, --verbose             Verbose output
  -h, --help                Show this help

EXAMPLES:
  $0 -i burp.xml -o results/
  $0 -i burp.xml --category INPV
  $0 -i burp.xml --test WSTG-INPV-05 --auth-token "Bearer eyJ..."
  $0 --openapi spec.yaml --no-proxy
  $0 -i burp.xml --include-destructive --rate-limit 20
EOF
    exit 0
}

# =====================
# Parse args
# =====================
while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--input) INPUT_FILE="$2"; INPUT_TYPE="burp"; shift 2 ;;
        --openapi) INPUT_FILE="$2"; INPUT_TYPE="openapi"; shift 2 ;;
        --list) INPUT_FILE="$2"; INPUT_TYPE="list"; shift 2 ;;
        -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
        -c|--concurrent) CONCURRENT="$2"; shift 2 ;;
        --rate-limit) RATE_LIMIT="$2"; shift 2 ;;
        --proxy) PROXY="$2"; USE_PROXY=1; shift 2 ;;
        --no-proxy) USE_PROXY=0; shift ;;
        --category) CATEGORY="$2"; shift 2 ;;
        --test) TEST="$2"; shift 2 ;;
        --auth-token) AUTH_TOKEN="$2"; shift 2 ;;
        --session-cookie) SESSION_COOKIE="$2"; shift 2 ;;
        --include-destructive) INCLUDE_DESTRUCTIVE=1; shift ;;
        --include-official) INCLUDE_OFFICIAL=1; shift ;;
        --timeout) TIMEOUT="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
done

# =====================
# Validation
# =====================
if [[ -z "$INPUT_FILE" ]]; then
    echo "ERROR: No input file specified. Use -i, --openapi, or --list" >&2
    usage
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "ERROR: Input file not found: $INPUT_FILE" >&2
    exit 1
fi

if ! command -v nuclei >/dev/null 2>&1; then
    echo "ERROR: nuclei not found. Install: go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest" >&2
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# =====================
# Build nuclei base args
# =====================
NUCLEI_ARGS=(
    "-c" "$CONCURRENT"
    "-rate-limit" "$RATE_LIMIT"
    "-timeout" "$TIMEOUT"
    "-stats"
    "-jsonl"
)

# Input mode
case "$INPUT_TYPE" in
    burp)
        NUCLEI_ARGS+=("-l" "$INPUT_FILE" "-im" "burp")
        ;;
    openapi)
        NUCLEI_ARGS+=("-l" "$INPUT_FILE" "-im" "openapi")
        ;;
    list)
        NUCLEI_ARGS+=("-l" "$INPUT_FILE")
        ;;
esac

# Proxy
if [[ "$USE_PROXY" -eq 1 ]]; then
    NUCLEI_ARGS+=("-proxy" "$PROXY")
fi

# Auth variables
if [[ -n "$AUTH_TOKEN" ]]; then
    NUCLEI_ARGS+=("-V" "auth_token=$AUTH_TOKEN" "-H" "Authorization: $AUTH_TOKEN")
fi
if [[ -n "$SESSION_COOKIE" ]]; then
    NUCLEI_ARGS+=("-V" "session_cookie=$SESSION_COOKIE" "-H" "Cookie: $SESSION_COOKIE")
fi

# Verbose
if [[ "$VERBOSE" -eq 1 ]]; then
    NUCLEI_ARGS+=("-v")
fi

# =====================
# Determine templates
# =====================
TEMPLATES=()

if [[ -n "$TEST" ]]; then
    # Single test - find matching template (case-insensitive)
    test_lower=$(echo "$TEST" | tr '[:upper:]' '[:lower:]' | sed 's/wstg-//')
    matched=$(find "$TEMPLATES_DIR" -name "wstg-${test_lower}*.yaml" -type f 2>/dev/null)
    if [[ -z "$matched" ]]; then
        echo "ERROR: No template found for test: $TEST" >&2
        echo "Available templates:" >&2
        ls "$TEMPLATES_DIR"/wstg-*.yaml | xargs -n1 basename >&2
        exit 1
    fi
    while IFS= read -r line; do TEMPLATES+=("$line"); done <<< "$matched"
elif [[ -n "$CATEGORY" ]]; then
    # Single category
    cat_lower=$(echo "$CATEGORY" | tr '[:upper:]' '[:lower:]')
    matched=$(find "$TEMPLATES_DIR" -name "wstg-${cat_lower}-*.yaml" -type f 2>/dev/null | sort)
    if [[ -z "$matched" ]]; then
        echo "ERROR: No templates found for category: $CATEGORY" >&2
        exit 1
    fi
    while IFS= read -r line; do TEMPLATES+=("$line"); done <<< "$matched"
else
    # All templates
    while IFS= read -r line; do TEMPLATES+=("$line"); done < <(find "$TEMPLATES_DIR" -name "wstg-*.yaml" -type f | sort)
fi

# =====================
# Run per-test
# =====================
echo "================================================================"
echo " WSTG Nuclei Suite"
echo "================================================================"
echo " Input:        $INPUT_FILE ($INPUT_TYPE)"
echo " Output:       $OUTPUT_DIR"
echo " Templates:    ${#TEMPLATES[@]}"
echo " Concurrent:   $CONCURRENT"
echo " Rate limit:   $RATE_LIMIT/s"
echo " Proxy:        $([ "$USE_PROXY" -eq 1 ] && echo "$PROXY" || echo "DISABLED")"
echo " Destructive:  $([ "$INCLUDE_DESTRUCTIVE" -eq 1 ] && echo "ENABLED" || echo "disabled")"
echo "================================================================"

START_TIME=$(date +%s)
TOTAL_FINDINGS=0

for tmpl in "${TEMPLATES[@]}"; do
    test_id=$(basename "$tmpl" .yaml | sed 's/^wstg-//;s/-.*//' | tr '[:lower:]' '[:upper:]')
    test_name=$(basename "$tmpl" .yaml)
    output_file="$OUTPUT_DIR/${test_name}.jsonl"

    # Add allow_destructive variable if requested
    extra_args=()
    if [[ "$INCLUDE_DESTRUCTIVE" -eq 1 ]]; then
        extra_args+=("-V" "allow_destructive=true")
    fi

    echo ""
    echo "[$(date +%H:%M:%S)] Running: $test_name"

    # Run nuclei
    if nuclei "${NUCLEI_ARGS[@]}" -t "$tmpl" -o "$output_file" "${extra_args[@]}" 2>&1 | tail -5; then
        if [[ -s "$output_file" ]]; then
            count=$(wc -l < "$output_file")
            TOTAL_FINDINGS=$((TOTAL_FINDINGS + count))
            echo "  → $count findings"
        else
            echo "  → 0 findings"
            rm -f "$output_file"
        fi
    else
        echo "  → ERROR running template"
    fi
done

# =====================
# Optional: official templates
# =====================
if [[ "$INCLUDE_OFFICIAL" -eq 1 ]] && [[ -d "$OFFICIAL_TEMPLATES_DIR" ]]; then
    echo ""
    echo "================================================================"
    echo " Running curated official nuclei-templates"
    echo "================================================================"
    nuclei "${NUCLEI_ARGS[@]}" \
        -t "$OFFICIAL_TEMPLATES_DIR/http/exposures/" \
        -t "$OFFICIAL_TEMPLATES_DIR/http/misconfiguration/" \
        -t "$OFFICIAL_TEMPLATES_DIR/http/exposed-panels/" \
        -t "$OFFICIAL_TEMPLATES_DIR/http/default-logins/" \
        -tags wstg \
        -o "$OUTPUT_DIR/official-templates.jsonl" || true
fi

# =====================
# Summary
# =====================
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "================================================================"
echo " RESULTS SUMMARY"
echo "================================================================"
echo " Total findings:    $TOTAL_FINDINGS"
echo " Duration:          ${DURATION}s"
echo " Output directory:  $OUTPUT_DIR"
echo "================================================================"

# Generate report if generate-report.py exists
REPORT_SCRIPT="$SCRIPT_DIR/generate-report.py"
if [[ -f "$REPORT_SCRIPT" ]] && command -v python3 >/dev/null 2>&1; then
    echo ""
    echo "Generating report..."
    python3 "$REPORT_SCRIPT" "$OUTPUT_DIR" --output-md "$OUTPUT_DIR/report.md" --output-html "$OUTPUT_DIR/report.html" || true
    echo " Report (MD):       $OUTPUT_DIR/report.md"
    echo " Report (HTML):     $OUTPUT_DIR/report.html"
fi

exit 0
