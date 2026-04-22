#!/usr/bin/env bash
set -euo pipefail

# Builds Rust-Backend as an iOS xcframework and places it under ios/TunifyBackendFFI.
#
# Usage:
#   ./scripts/bundle_rust_ios.sh [debug|release]
# Env:
#   RUST_BACKEND_ROOT (default: ../Rust-Backend from repo root)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNIFY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUST_BACKEND_ROOT="${RUST_BACKEND_ROOT:-${TUNIFY_ROOT}/../Rust-Backend}"
BUNDLE_ENV_SOURCE="${BUNDLE_ENV_SOURCE:-${RUST_BACKEND_ROOT}/.env.bundle}"
PROFILE="${1:-release}"

if [[ "${PROFILE}" != "debug" && "${PROFILE}" != "release" ]]; then
  echo "Usage: $0 [debug|release]"
  exit 1
fi

if [[ ! -d "${RUST_BACKEND_ROOT}" ]]; then
  echo "Rust backend not found: ${RUST_BACKEND_ROOT}"
  exit 1
fi

if ! xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
  echo "ERROR: iPhoneOS SDK is unavailable."
  echo "Install full Xcode and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi
if ! xcrun --sdk iphonesimulator --show-sdk-path >/dev/null 2>&1; then
  echo "ERROR: iPhoneSimulator SDK is unavailable."
  echo "Install full Xcode and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

OUT_DIR="${TUNIFY_ROOT}/ios/TunifyBackendFFI"
FRAMEWORK_DIR="${OUT_DIR}/TunifyBackendFFI.xcframework"
HEADERS_DIR="${OUT_DIR}/Headers"
RUNTIME_ENV_DEST="${TUNIFY_ROOT}/assets/bundled_backend/runtime.env"

if [[ ! -f "${BUNDLE_ENV_SOURCE}" ]]; then
  echo "Bundled env file not found: ${BUNDLE_ENV_SOURCE}"
  echo "Create Rust-Backend/.env.bundle (or set BUNDLE_ENV_SOURCE=...)"
  exit 1
fi

mkdir -p "${HEADERS_DIR}"
cp "${RUST_BACKEND_ROOT}/include/tunify_backend_ffi.h" "${HEADERS_DIR}/tunify_backend_ffi.h"
cat > "${HEADERS_DIR}/module.modulemap" <<'EOF'
module TunifyBackendFFI {
  header "tunify_backend_ffi.h"
  export *
}
EOF

RUST_TARGETS=("aarch64-apple-ios" "aarch64-apple-ios-sim")
if [[ "$(uname -m)" == "x86_64" ]]; then
  RUST_TARGETS+=("x86_64-apple-ios")
fi

for target in "${RUST_TARGETS[@]}"; do
  echo "==> Ensuring Rust target ${target} is installed"
  rustup target add "${target}" >/dev/null 2>&1 || rustup target add "${target}"
done

BUILD_FLAG=""
if [[ "${PROFILE}" == "release" ]]; then
  BUILD_FLAG="--release"
fi

for target in "${RUST_TARGETS[@]}"; do
  echo "==> Building ${PROFILE} ${target} in ${RUST_BACKEND_ROOT}"
  (cd "${RUST_BACKEND_ROOT}" && cargo build ${BUILD_FLAG} --target "${target}")
done

LIBS=()
for target in "${RUST_TARGETS[@]}"; do
  LIBS+=("-library" "${RUST_BACKEND_ROOT}/target/${target}/${PROFILE}/libtunify_rust_backend.a" "-headers" "${HEADERS_DIR}")
done

rm -rf "${FRAMEWORK_DIR}"
echo "==> Creating xcframework at ${FRAMEWORK_DIR}"
xcodebuild -create-xcframework "${LIBS[@]}" -output "${FRAMEWORK_DIR}"

mkdir -p "$(dirname "${RUNTIME_ENV_DEST}")"
awk '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  /^[A-Za-z_][A-Za-z0-9_]*=/ {
    sub(/^[[:space:]]+/, "", $0)
    print
  }
' "${BUNDLE_ENV_SOURCE}" > "${RUNTIME_ENV_DEST}"

echo "==> Bundled iOS backend xcframework ready: ${FRAMEWORK_DIR}"
echo "==> Synced bundled runtime env to ${RUNTIME_ENV_DEST} (source=${BUNDLE_ENV_SOURCE})"
