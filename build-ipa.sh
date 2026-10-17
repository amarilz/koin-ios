
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="koin"
ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"
OUTPUT_DIR="$(cd "$(dirname "$0")" && pwd)/dist"

# Find the most recent archive for this app.
ARCHIVE="$(
  find "$ARCHIVES_DIR" -type d -name "${APP_NAME}.app" \
    -path "*/Products/Applications/*" -print |
  sed "s|/Products/Applications/${APP_NAME}.app$||" |
  while IFS= read -r path; do
    printf '%s\t%s\n' "$(stat -f '%m' "$path")" "$path"
  done |
  sort -nr |
  head -n 1 |
  cut -f 2-
)"

if [[ -z "$ARCHIVE" ]]; then
  echo "Error: no archive found for ${APP_NAME}"
  exit 1
fi

APP="$ARCHIVE/Products/Applications/${APP_NAME}.app"

echo "Using archive: $ARCHIVE"

# Prepare temporary IPA structure.
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$WORKDIR/Payload" "$OUTPUT_DIR"
ditto "$APP" "$WORKDIR/Payload/${APP_NAME}.app"

# Package the IPA.
(
  cd "$WORKDIR"
  zip -qry "$OUTPUT_DIR/Koin.ipa" Payload
)

echo "IPA created: $OUTPUT_DIR/Koin.ipa"
