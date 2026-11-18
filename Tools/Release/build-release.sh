#!/bin/bash
# Cazaminas — © 2026 App-Zilla. Licencia MIT.
#
# Compila Cazaminas en Release (universal: Apple Silicon e Intel), con firma ad hoc,
# y genera en dist/:
#   - Cazaminas-<versión>.dmg  (arrastrar a Aplicaciones)
#   - Cazaminas-<versión>.zip
#   - SHA256SUMS.txt
#
# Uso, desde la raíz del repositorio:
#
#     Tools/Release/build-release.sh
#
# No necesita cuenta de desarrollador de Apple: la app no se notariza, así que la
# primera vez hay que abrirla desde Ajustes del Sistema (ver README).

set -euo pipefail

cd "$(dirname "$0")/../.."

VERSION=$(sed -n 's/^ *MARKETING_VERSION: "\(.*\)"/\1/p' project.yml)
BUILD_DIR="build/Release"
APP="$BUILD_DIR/Build/Products/Release/Cazaminas.app"
DIST="dist"

echo "▸ Cazaminas $VERSION"

# Regenera el proyecto si XcodeGen está instalado (en CI se usa el proyecto ya generado).
if command -v xcodegen >/dev/null 2>&1; then
    xcodegen generate --quiet
fi

echo "▸ Compilando (Release, universal, firma ad hoc)…"
xcodebuild \
    -project Cazaminas.xcodeproj \
    -scheme Cazaminas \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR" \
    -destination "generic/platform=macOS" \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="" \
    clean build \
    | grep -E "error:|warning:|BUILD" || true

if [ ! -d "$APP" ]; then
    echo "✘ No se generó $APP" >&2
    exit 1
fi

echo "▸ Verificando firma y arquitecturas…"
# Xcode ya firma ad hoc con los permisos de la sandbox; aquí solo se comprueba.
codesign --verify --deep --strict "$APP"
codesign -dv "$APP" 2>&1 | grep -E "^(Signature|Identifier)="
lipo -archs "$APP/Contents/MacOS/Cazaminas"

echo "▸ Empaquetando…"
rm -rf "$DIST"
mkdir -p "$DIST"

ditto -c -k --keepParent "$APP" "$DIST/Cazaminas-$VERSION.zip"

STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Aplicaciones"
hdiutil create \
    -volname "Cazaminas $VERSION" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDZO \
    -ov \
    "$DIST/Cazaminas-$VERSION.dmg" >/dev/null

(cd "$DIST" && shasum -a 256 Cazaminas-"$VERSION".* > SHA256SUMS.txt)

echo "✔ Listo:"
ls -lh "$DIST"
