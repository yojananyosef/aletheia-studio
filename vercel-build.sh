#!/usr/bin/env bash
# Compila Aletheia Studio para Vercel.
#
# Vercel no incluye Flutter en su imagen de build, así que se descarga la
# versión fijada por el proyecto y se compila el bundle web ligero. El catálogo
# completo se sirve desde `aletheia-mods`; aquí solo se empaqueta el núcleo.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"
FLUTTER_ROOT="${FLUTTER_ROOT:-$HOME/flutter}"

if [[ ! -x "$FLUTTER_ROOT/bin/flutter" ]]; then
  archive="$(mktemp -u "${TMPDIR:-/tmp}/flutter-${FLUTTER_VERSION}.XXXXXX.tar.xz")"
  echo "Descargando Flutter ${FLUTTER_VERSION}…"
  curl -fL --retry 3 --retry-delay 3 \
    -o "$archive" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  echo "Extrayendo Flutter…"
  tar -xf "$archive" -C "$(dirname "$FLUTTER_ROOT")"
  rm -f "$archive"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

# El build de Vercel corre como root y el SDK descargado conserva otro
# propietario; Git lo rechaza al consultar la versión de Flutter.
git config --global --add safe.directory "$FLUTTER_ROOT"
flutter config --no-analytics >/dev/null 2>&1 || true

cd "$(dirname "$0")/app"
flutter pub get
ALETHEIA_BASE_HREF=/ bash tool/build_web_release.sh
