#!/usr/bin/env bash
# =============================================================================
# inject_web_client_id.sh
# Inject Google Web Client ID ke web/index.html sebelum flutter run/build web.
#
# Cara pakai:
#   GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com bash scripts/inject_web_client_id.sh
#
# Atau dengan argument langsung:
#   bash scripts/inject_web_client_id.sh "xxx.apps.googleusercontent.com"
#
# Dapatkan nilai dari:
#   Firebase Console → sakurapi-aa6ac → Project Settings → Web App → Web Client ID
#   ATAU: Google Cloud Console → APIs & Services → Credentials → Web client (auto created by Google Service)
#
# CATATAN: Web Client ID adalah public client config, BUKAN secret.
# Nilai ini akan terlihat di source HTML yang dikirim ke browser setelah inject.
# Tujuan skrip ini adalah menjaga kebersihan source yang di-commit (placeholder),
# bukan menyembunyikan nilai.
#
# JANGAN commit web/index.html setelah inject (gunakan: git checkout web/index.html
# untuk mengembalikan placeholder setelah selesai, atau --assume-unchanged).
# =============================================================================

set -euo pipefail

PLACEHOLDER="YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com"
TARGET="web/index.html"

# Ambil nilai dari argument atau environment variable
WEB_CLIENT_ID="${1:-${GOOGLE_WEB_CLIENT_ID:-}}"

if [ -z "$WEB_CLIENT_ID" ]; then
  echo "Error: Web Client ID tidak diberikan."
  echo ""
  echo "Cara pakai:"
  echo "  GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com bash $0"
  echo "  bash $0 \"xxx.apps.googleusercontent.com\""
  echo ""
  echo "Dapatkan nilai dari Firebase Console → sakurapi-aa6ac → Project Settings → Web App"
  exit 1
fi

# Validasi format dasar (harus diakhiri .apps.googleusercontent.com)
if [[ "$WEB_CLIENT_ID" != *".apps.googleusercontent.com" ]]; then
  echo "Warning: Nilai '$WEB_CLIENT_ID' tidak terlihat seperti OAuth Client ID yang valid."
  echo "Format yang diharapkan: <nomor>-<hash>.apps.googleusercontent.com"
  echo "Lanjutkan? (y/N)"
  read -r confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Dibatalkan."
    exit 1
  fi
fi

# Cek apakah target file ada
if [ ! -f "$TARGET" ]; then
  echo "Error: $TARGET tidak ditemukan. Jalankan skrip dari root direktori proyek."
  exit 1
fi

# Cek apakah placeholder ada di file
if ! grep -q "$PLACEHOLDER" "$TARGET"; then
  # Cek apakah file sudah berisi nilai yang bukan placeholder
  if grep -q "google-signin-client_id" "$TARGET"; then
    echo "Info: Placeholder '$PLACEHOLDER' tidak ditemukan di $TARGET."
    echo "File mungkin sudah berisi nilai nyata atau placeholder sudah diganti."
    echo "Tidak ada perubahan yang dilakukan."
    exit 0
  else
    echo "Warning: Tag meta google-signin-client_id tidak ditemukan di $TARGET."
    exit 1
  fi
fi

# Lakukan substitusi (kompatibel dengan GNU sed dan macOS BSD sed)
if sed --version >/dev/null 2>&1; then
  # GNU sed (Linux, Git Bash on Windows)
  sed -i "s|$PLACEHOLDER|$WEB_CLIENT_ID|g" "$TARGET"
else
  # BSD sed (macOS)
  sed -i '' "s|$PLACEHOLDER|$WEB_CLIENT_ID|g" "$TARGET"
fi

echo "✓ Web Client ID berhasil diinjeksi ke $TARGET"
echo ""
echo "Langkah selanjutnya:"
echo "  flutter run -d chrome --web-hostname localhost --web-port 7357"
echo ""
echo "Untuk mengembalikan placeholder setelah selesai:"
echo "  git checkout web/index.html"
