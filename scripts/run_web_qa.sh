#!/usr/bin/env bash
# =============================================================================
# scripts/run_web_qa.sh
#
# Skrip otomasi QA web untuk proyek Flutter SakuRapi.
#
# Cara menjalankan (dari root proyek):
#   bash scripts/run_web_qa.sh
#
# Skrip ini:
#   1. Memverifikasi root proyek dan file wajib
#   2. flutter clean
#   3. flutter pub get
#   4. dart run build_runner build --delete-conflicting-outputs
#   5. flutter analyze
#   6. flutter test test/          (unit + widget tests, tanpa device)
#   7. flutter test integration_test/web_flow_test.dart -d chrome
#      (dilewati dengan status SKIPPED jika Chrome tidak ditemukan)
#   8. Mencetak ringkasan PASS / FAIL / SKIPPED
#
# Log disimpan ke: reports/web_qa/qa_<timestamp>.log
#
# Exit code:
#   0  = semua langkah penting PASS
#   1  = ada langkah penting yang FAIL
# =============================================================================

set -euo pipefail

# ── Warna output ──────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Pelacak hasil ─────────────────────────────────────────────────────────────
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
FAILED_STEPS=()

# ── Timestamp ─────────────────────────────────────────────────────────────────
TS=$(date +"%Y%m%d_%H%M%S")
REPORT_DIR="reports/web_qa"
LOG_FILE="${REPORT_DIR}/qa_${TS}.log"

# ── Fungsi helper ──────────────────────────────────────────────────────────────

step() {
  echo ""
  echo -e "${BLUE}${BOLD}═══════════════════════════════════════════${RESET}"
  echo -e "${BLUE}${BOLD}  LANGKAH $1: $2${RESET}"
  echo -e "${BLUE}${BOLD}═══════════════════════════════════════════${RESET}"
}

ok() {
  echo -e "${GREEN}  ✓ $1${RESET}"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}  ✗ $1${RESET}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAILED_STEPS+=("$1")
}

skip() {
  echo -e "${YELLOW}  ⊘ $1 [SKIPPED]${RESET}"
  SKIP_COUNT=$((SKIP_COUNT + 1))
}

info() {
  echo -e "  ${BOLD}→${RESET} $1"
}

# Jalankan perintah dan catat ke log. Return 1 jika gagal.
run_cmd() {
  local label="$1"
  shift
  info "Menjalankan: $*"
  if "$@" 2>&1 | tee -a "$LOG_FILE"; then
    ok "$label berhasil"
    return 0
  else
    fail "$label gagal"
    return 1
  fi
}

# ── Mulai ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}SakuRapi — Web QA Automation${RESET}"
echo -e "Timestamp : $TS"
echo -e "Log file  : $LOG_FILE"
echo ""

# Buat direktori laporan
mkdir -p "$REPORT_DIR"
echo "=== SakuRapi Web QA — $TS ===" > "$LOG_FILE"

# ── LANGKAH 1: Verifikasi root proyek ─────────────────────────────────────────

step 1 "Verifikasi root proyek"

if [[ ! -f "pubspec.yaml" ]]; then
  echo -e "${RED}ERROR: pubspec.yaml tidak ditemukan.${RESET}"
  echo "Jalankan skrip ini dari root direktori proyek."
  exit 1
fi
ok "pubspec.yaml ditemukan"

for f in "lib/main.dart" "test/" "integration_test/" "test_driver/integration_test.dart"; do
  if [[ -e "$f" ]]; then
    ok "$f ditemukan"
  else
    fail "$f tidak ditemukan"
  fi
done

# ── LANGKAH 2: flutter clean ──────────────────────────────────────────────────

step 2 "flutter clean"
run_cmd "flutter clean" flutter clean || true
# clean bukan fatal; lanjut

# ── LANGKAH 3: flutter pub get ────────────────────────────────────────────────

step 3 "flutter pub get"
if ! run_cmd "flutter pub get" flutter pub get; then
  echo -e "${RED}FATAL: flutter pub get gagal. Berhenti.${RESET}"
  exit 1
fi

# ── LANGKAH 4: build_runner ───────────────────────────────────────────────────

step 4 "dart run build_runner build"
info "Membangun kode yang di-generate (Drift DAOs, dll.)"
if ! run_cmd "build_runner" dart run build_runner build --delete-conflicting-outputs; then
  echo -e "${RED}FATAL: build_runner gagal. Berhenti.${RESET}"
  exit 1
fi

# ── LANGKAH 5: flutter analyze ────────────────────────────────────────────────

step 5 "flutter analyze"
if ! run_cmd "flutter analyze" flutter analyze; then
  fail "flutter analyze melaporkan masalah"
  echo -e "${YELLOW}  Peringatan: analyze gagal, tapi QA dilanjutkan.${RESET}"
fi

# ── LANGKAH 6: flutter test (unit + widget) ───────────────────────────────────

step 6 "flutter test test/"
info "Menjalankan semua unit tests dan widget tests (tanpa device)"

UNIT_LOG="${REPORT_DIR}/unit_widget_${TS}.log"
if flutter test test/ --reporter expanded 2>&1 | tee "$UNIT_LOG" | tee -a "$LOG_FILE"; then
  ok "flutter test test/ PASS"
else
  fail "flutter test test/ FAIL — lihat $UNIT_LOG"
fi

# ── LANGKAH 7: Integration test di Chrome ────────────────────────────────────

step 7 "Integration test di Chrome"

CHROME_AVAILABLE=false

# Deteksi Chrome / Chromium
for cmd in google-chrome google-chrome-stable chromium chromium-browser; do
  if command -v "$cmd" &>/dev/null; then
    CHROME_AVAILABLE=true
    info "Chrome ditemukan: $(command -v "$cmd")"
    break
  fi
done

# Coba juga path default Windows (Git Bash / WSL)
if [[ "$CHROME_AVAILABLE" == "false" ]]; then
  WIN_CHROME_PATHS=(
    "/c/Program Files/Google/Chrome/Application/chrome.exe"
    "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe"
  )
  for p in "${WIN_CHROME_PATHS[@]}"; do
    if [[ -f "$p" ]]; then
      CHROME_AVAILABLE=true
      info "Chrome ditemukan (Windows): $p"
      break
    fi
  done
fi

if [[ "$CHROME_AVAILABLE" == "true" ]]; then
  INT_LOG="${REPORT_DIR}/integration_${TS}.log"
  info "Menjalankan integration tests di Chrome..."
  info "Perintah: flutter test integration_test/web_flow_test.dart -d chrome"

  if flutter test integration_test/web_flow_test.dart -d chrome \
       --reporter expanded 2>&1 | tee "$INT_LOG" | tee -a "$LOG_FILE"; then
    ok "Integration test Chrome PASS"
  else
    fail "Integration test Chrome FAIL — lihat $INT_LOG"
    echo -e "${YELLOW}  Catatan: Beberapa test mungkin gagal karena Firebase/WASM${RESET}"
    echo -e "${YELLOW}  memerlukan web server aktif saat -d chrome dijalankan.${RESET}"
  fi
else
  skip "Integration test Chrome — Chrome tidak ditemukan di PATH"
  info "Untuk menjalankan manual:"
  info "  flutter test integration_test/web_flow_test.dart -d chrome"
fi

# ── LANGKAH 8: Ringkasan ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "${BOLD}  RINGKASAN HASIL WEB QA${RESET}"
echo -e "${BOLD}═══════════════════════════════════════════════${RESET}"
echo -e "  ${GREEN}PASS   : $PASS_COUNT${RESET}"
echo -e "  ${RED}FAIL   : $FAIL_COUNT${RESET}"
echo -e "  ${YELLOW}SKIPPED: $SKIP_COUNT${RESET}"
echo ""

if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
  echo -e "${RED}Langkah yang gagal:${RESET}"
  for s in "${FAILED_STEPS[@]}"; do
    echo -e "  ${RED}✗ $s${RESET}"
  done
  echo ""
fi

echo -e "  Log lengkap: ${BOLD}$LOG_FILE${RESET}"
echo ""

# Tulis ringkasan ke log
{
  echo ""
  echo "=== RINGKASAN ==="
  echo "PASS   : $PASS_COUNT"
  echo "FAIL   : $FAIL_COUNT"
  echo "SKIPPED: $SKIP_COUNT"
  if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
    echo "Gagal :"
    for s in "${FAILED_STEPS[@]}"; do
      echo "  - $s"
    done
  fi
} >> "$LOG_FILE"

# Exit code berdasarkan hasil
if [[ $FAIL_COUNT -gt 0 ]]; then
  echo -e "${RED}${BOLD}HASIL: FAIL${RESET}"
  exit 1
else
  echo -e "${GREEN}${BOLD}HASIL: PASS${RESET}"
  exit 0
fi
