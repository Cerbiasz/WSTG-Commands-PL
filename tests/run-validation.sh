#!/usr/bin/env bash
# ============================================================================
# tests/run-validation.sh — walidacja WSTG Suite na testowych aplikacjach
# ============================================================================
#
# Uruchamia suite przeciwko testowym aplikacjom w docker-compose.
# Porównuje wykryte findings z expected-findings.yaml → detection rate score.
#
# Wymagania:
# - docker-compose up -d (usługi healthy)
# - python3 + pyyaml (`pip install pyyaml`)
# - nuclei + jq
#
# Użycie:
#   cd tests/
#   docker-compose up -d
#   ./run-validation.sh
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SUITE_SCRIPT="$REPO_ROOT/scripts/run-wstg-suite.sh"
EXPECTED_FILE="$SCRIPT_DIR/expected-findings.yaml"
RESULTS_BASE="$SCRIPT_DIR/validation-results-$(date +%Y%m%d-%H%M%S)"

mkdir -p "$RESULTS_BASE"

# Apps to test
APPS=("juiceshop:http://localhost:3000" "dvwa:http://localhost:8080" "webgoat:http://localhost:8081/WebGoat" "vampi:http://localhost:5000")

echo "================================================================"
echo " WSTG Suite Validation"
echo "================================================================"

for app_def in "${APPS[@]}"; do
    app_name="${app_def%%:*}"
    app_url="${app_def#*:}"

    echo ""
    echo "--- Testing: $app_name ($app_url) ---"

    # Check reachability
    if ! curl -sf -m 5 "$app_url" >/dev/null 2>&1; then
        echo "  SKIP: $app_url not reachable"
        continue
    fi

    # Create URL list
    url_list="$RESULTS_BASE/$app_name-urls.txt"
    echo "$app_url" > "$url_list"

    # Run suite (no proxy for validation)
    "$SUITE_SCRIPT" \
        --list "$url_list" \
        -o "$RESULTS_BASE/$app_name" \
        --no-proxy \
        --rate-limit 100 \
        -c 10 || true

    echo "  Results: $RESULTS_BASE/$app_name"
done

# Compare with expected
if [[ -f "$EXPECTED_FILE" ]] && command -v python3 >/dev/null 2>&1; then
    echo ""
    echo "--- Comparing with expected findings ---"
    python3 - <<EOF
import yaml
import json
import os
from pathlib import Path

results_base = Path("$RESULTS_BASE")
expected_file = Path("$EXPECTED_FILE")

with open(expected_file) as f:
    expected = yaml.safe_load(f)

print(f"\n{'App':<15} {'Expected':>10} {'Detected':>10} {'Rate':>10}")
print("-" * 50)

for app, data in expected.items():
    if app == "metadata" or not isinstance(data, dict):
        continue

    expected_tests = [k for k, v in data.items() if isinstance(v, dict) and v.get("expected")]
    if not expected_tests:
        continue

    detected = set()
    app_dir = results_base / app
    if app_dir.exists():
        for jsonl in app_dir.glob("*.jsonl"):
            with open(jsonl) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        rec = json.loads(line)
                        tags = rec.get("info", {}).get("tags", "")
                        if isinstance(tags, list):
                            tags = ",".join(tags)
                        # Extract WSTG ID
                        for tag in tags.split(","):
                            tag = tag.strip()
                            if tag.startswith("wstg-v42-"):
                                wstg_id = tag.replace("wstg-v42-", "WSTG-").upper()
                                # Normalize  (eg "WSTG-INPV-05" → "WSTG-INPV-05")
                                detected.add(wstg_id)
                    except Exception:
                        pass

    matched = sum(1 for e in expected_tests if e.upper() in {d.upper() for d in detected})
    total = len(expected_tests)
    rate = (matched / total * 100) if total else 0
    status = "✓" if rate >= 80 else "✗"
    print(f"{app:<15} {total:>10} {matched:>10} {rate:>8.0f}% {status}")

print("\nDetailed results in: $RESULTS_BASE")
EOF
else
    echo "WARN: python3 or expected-findings.yaml missing - skipping comparison"
fi

echo ""
echo "================================================================"
echo " Validation complete: $RESULTS_BASE"
echo "================================================================"
