#!/usr/bin/env bash
# ============================================================================
# kali-run-all.sh — bootstrap + uruchomienie WSTG Nuclei Suite na Kali Linux
# ============================================================================
#
# Co robi:
#   1. Instaluje brakujące zależności (nuclei, docker, jq, python3-yaml)
#   2. Aktualizuje nuclei templates (-update-templates)
#   3. Uruchamia podatne aplikacje testowe (docker compose up -d)
#   4. Czeka aż wstaną i odpala tests/run-validation.sh
#   5. (Opcjonalnie) cleanup po zakończeniu
#
# Użycie:
#   sudo ./scripts/kali-run-all.sh                     # pełna walidacja (4 apps)
#   sudo ./scripts/kali-run-all.sh --only juiceshop    # tylko jedna app
#   sudo ./scripts/kali-run-all.sh --target https://example.com  # własny cel
#   sudo ./scripts/kali-run-all.sh --skip-install      # pomiń instalację
#   sudo ./scripts/kali-run-all.sh --keep-running      # nie ubijaj kontenerów
# ============================================================================

set -euo pipefail

# =====================
# Defaults
# =====================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$REPO_ROOT/tests"

ONLY_APP=""
TARGET_URL=""
SKIP_INSTALL=0
KEEP_RUNNING=0
INCLUDE_DESTRUCTIVE=0

# =====================
# Parse args
# =====================
while [[ $# -gt 0 ]]; do
    case "$1" in
        --only) ONLY_APP="$2"; shift 2 ;;
        --target) TARGET_URL="$2"; shift 2 ;;
        --skip-install) SKIP_INSTALL=1; shift ;;
        --keep-running) KEEP_RUNNING=1; shift ;;
        --include-destructive) INCLUDE_DESTRUCTIVE=1; shift ;;
        -h|--help)
            sed -n '2,20p' "$0"; exit 0 ;;
        *) echo "Unknown: $1" >&2; exit 1 ;;
    esac
done

# =====================
# Helpers
# =====================
log()  { echo -e "\033[1;34m[*]\033[0m $*"; }
ok()   { echo -e "\033[1;32m[+]\033[0m $*"; }
warn() { echo -e "\033[1;33m[!]\033[0m $*"; }
err()  { echo -e "\033[1;31m[-]\033[0m $*" >&2; }

need_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Ten krok wymaga sudo (instalacja pakietów)."
        exit 1
    fi
}

# =====================
# 1. Install deps (Kali / Debian)
# =====================
install_deps() {
    log "Sprawdzanie zależności..."
    local missing=()
    for cmd in nuclei docker jq python3 curl; do
        command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    python3 -c "import yaml" 2>/dev/null || missing+=("python3-yaml")

    if [[ ${#missing[@]} -eq 0 ]]; then
        ok "Wszystkie zależności obecne."
        return
    fi

    warn "Brakuje: ${missing[*]}"
    need_root

    log "apt update..."
    apt-get update -qq

    # docker.io + compose-plugin (Kali ma w repo)
    if [[ " ${missing[*]} " == *" docker "* ]]; then
        log "Instalowanie docker.io + docker-compose-plugin..."
        apt-get install -y -qq docker.io docker-compose-plugin
        systemctl enable --now docker
        # Dodaj wywołującego usera do grupy docker (jeśli SUDO_USER ustawione)
        if [[ -n "${SUDO_USER:-}" ]] && ! groups "$SUDO_USER" | grep -q docker; then
            usermod -aG docker "$SUDO_USER"
            warn "Dodano $SUDO_USER do grupy 'docker'. Wyloguj się i zaloguj ponownie aby zadziałało bez sudo."
        fi
    fi

    for pkg in jq python3 curl; do
        if [[ " ${missing[*]} " == *" $pkg "* ]]; then
            log "Instalowanie $pkg..."
            apt-get install -y -qq "$pkg"
        fi
    done

    if [[ " ${missing[*]} " == *" python3-yaml "* ]]; then
        log "Instalowanie python3-yaml..."
        apt-get install -y -qq python3-yaml
    fi

    if [[ " ${missing[*]} " == *" nuclei "* ]]; then
        log "Instalowanie nuclei..."
        # Kali ma nuclei w repo
        if apt-get install -y -qq nuclei 2>/dev/null; then
            ok "Nuclei zainstalowany z apt."
        else
            warn "apt nie znalazł nuclei. Pobieranie binarki..."
            local arch tag url tmp
            arch=$(uname -m); [[ "$arch" == "x86_64" ]] && arch="amd64"
            tag=$(curl -sf https://api.github.com/repos/projectdiscovery/nuclei/releases/latest | jq -r .tag_name)
            url="https://github.com/projectdiscovery/nuclei/releases/download/${tag}/nuclei_${tag#v}_linux_${arch}.zip"
            tmp=$(mktemp -d)
            curl -sfL "$url" -o "$tmp/nuclei.zip"
            unzip -q "$tmp/nuclei.zip" -d "$tmp"
            install -m 0755 "$tmp/nuclei" /usr/local/bin/nuclei
            rm -rf "$tmp"
            ok "Nuclei: $(/usr/local/bin/nuclei -version 2>&1 | head -1)"
        fi
    fi

    ok "Zależności gotowe."
}

[[ $SKIP_INSTALL -eq 0 ]] && install_deps

# =====================
# 2. Update nuclei templates
# =====================
log "Aktualizacja nuclei templates..."
nuclei -update-templates -silent 2>/dev/null || warn "Update templates nie powiódł się (nieblokujące)."

# =====================
# 3. Tryb: własny target
# =====================
if [[ -n "$TARGET_URL" ]]; then
    log "Skanowanie własnego celu: $TARGET_URL"
    OUT="$REPO_ROOT/results-custom-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$OUT"
    URL_LIST="$OUT/urls.txt"
    echo "$TARGET_URL" > "$URL_LIST"

    EXTRA=()
    [[ $INCLUDE_DESTRUCTIVE -eq 1 ]] && EXTRA+=(--include-destructive)

    "$SCRIPT_DIR/run-wstg-suite.sh" \
        --list "$URL_LIST" \
        -o "$OUT" \
        --no-proxy \
        --rate-limit 100 \
        -c 10 \
        "${EXTRA[@]}"

    ok "Wyniki: $OUT"
    exit 0
fi

# =====================
# 4. Tryb: validation suite (docker compose)
# =====================
log "Sprawdzanie docker daemon..."
if ! docker info >/dev/null 2>&1; then
    err "Docker daemon nie działa. Uruchom: sudo systemctl start docker"
    exit 1
fi

cd "$TESTS_DIR"

if [[ -n "$ONLY_APP" ]]; then
    log "Uruchamianie tylko: $ONLY_APP"
    docker compose up -d "$ONLY_APP"
else
    log "Uruchamianie wszystkich podatnych aplikacji..."
    docker compose up -d
fi

# Wait for healthchecks
log "Czekam aż aplikacje wstaną (max 120s)..."
for i in {1..24}; do
    sleep 5
    running=$(docker compose ps --status running 2>/dev/null | tail -n +2 | wc -l)
    expected=$(docker compose ps 2>/dev/null | tail -n +2 | wc -l)
    log "  ($((i*5))s) running: $running/$expected"
    [[ "$running" -gt 0 ]] && [[ "$running" -eq "$expected" ]] && break
done

docker compose ps

# =====================
# 5. Run validation
# =====================
log "Uruchamiam tests/run-validation.sh..."
"$TESTS_DIR/run-validation.sh"

# =====================
# 6. Cleanup
# =====================
if [[ $KEEP_RUNNING -eq 0 ]]; then
    log "Cleanup: docker compose down..."
    docker compose down
else
    warn "Kontenery pozostawione (--keep-running). Ubij ręcznie: cd tests/ && docker compose down"
fi

ok "Gotowe."
