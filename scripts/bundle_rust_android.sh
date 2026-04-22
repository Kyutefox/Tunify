#!/usr/bin/env bash
set -euo pipefail

# Builds Tunify Rust backend for Android and copies it into Flutter assets
# (assets/bundled_backend/tunify_rust_backend). Used by the root Makefile.
#
# Usage:
#   ./scripts/bundle_rust_android.sh [debug|release]
# Env:
#   RUST_BACKEND_ROOT         (default: ../Rust-Backend from repo root)
#   ANDROID_RUST_TARGET       (default: aarch64-linux-android)
#   RUST_BACKEND_BINARY       Optional: skip cargo; copy this file into assets
#   ANDROID_NDK_HOME          NDK root (e.g. .../ndk/26.1.10909125). Auto-detected from SDK if unset.
#   ANDROID_NDK_VERSION       If set, pick .../ndk/<this> instead of newest under sdk/ndk
#   ANDROID_SDK_ROOT / ANDROID_HOME
#   ANDROID_NATIVE_API_LEVEL  Clang API suffix (default: 24)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNIFY_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DEST="${TUNIFY_ROOT}/assets/bundled_backend/tunify_rust_backend"
RUNTIME_ENV_DEST="${TUNIFY_ROOT}/assets/bundled_backend/runtime.env"
RUST_BACKEND_ROOT="${RUST_BACKEND_ROOT:-${TUNIFY_ROOT}/../Rust-Backend}"
BUNDLE_ENV_SOURCE="${BUNDLE_ENV_SOURCE:-${RUST_BACKEND_ROOT}/.env.bundle}"
ANDROID_RUST_TARGET="${ANDROID_RUST_TARGET:-aarch64-linux-android}"
PROFILE="${1:-release}"
ANDROID_NATIVE_API_LEVEL="${ANDROID_NATIVE_API_LEVEL:-24}"

if [[ "${PROFILE}" != "debug" && "${PROFILE}" != "release" ]]; then
  echo "Usage: $0 [debug|release]"
  exit 1
fi

resolve_android_sdk() {
  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    echo "${ANDROID_SDK_ROOT%/}"
    return
  fi
  if [[ -n "${ANDROID_HOME:-}" ]]; then
    echo "${ANDROID_HOME%/}"
    return
  fi
  if [[ -d "${HOME}/Library/Android/sdk" ]]; then
    echo "${HOME}/Library/Android/sdk"
    return
  fi
  return 1
}

resolve_ndk_home() {
  if [[ -n "${ANDROID_NDK_HOME:-}" && -d "${ANDROID_NDK_HOME}" ]]; then
    echo "${ANDROID_NDK_HOME%/}"
    return
  fi
  local sdk
  if ! sdk="$(resolve_android_sdk)"; then
    return 1
  fi
  local ndk_root="${sdk}/ndk"
  if [[ ! -d "${ndk_root}" ]]; then
    return 1
  fi
  if [[ -n "${ANDROID_NDK_VERSION:-}" && -d "${ndk_root}/${ANDROID_NDK_VERSION}" ]]; then
    echo "${ndk_root}/${ANDROID_NDK_VERSION}"
    return
  fi
  local best
  best="$(ls -1 "${ndk_root}" 2>/dev/null | sort -V | tail -n1 || true)"
  if [[ -z "${best}" ]]; then
    return 1
  fi
  echo "${ndk_root}/${best}"
}

resolve_ndk_host_tag() {
  local ndk="$1"
  local prebuilt="${ndk}/toolchains/llvm/prebuilt"
  if [[ ! -d "${prebuilt}" ]]; then
    return 1
  fi
  # Prefer native prebuilt when present; many NDKs ship darwin-x86_64 only (Rosetta on Apple Silicon).
  local host_os host_arch
  host_os="$(uname -s)"
  host_arch="$(uname -m)"
  if [[ "${host_os}" == Darwin ]]; then
    if [[ "${host_arch}" == arm64 ]] && [[ -d "${prebuilt}/darwin-aarch64" ]]; then
      echo "darwin-aarch64"
      return
    fi
    if [[ -d "${prebuilt}/darwin-x86_64" ]]; then
      echo "darwin-x86_64"
      return
    fi
  elif [[ "${host_os}" == Linux ]]; then
    if [[ "${host_arch}" == aarch64 ]] && [[ -d "${prebuilt}/linux-aarch64" ]]; then
      echo "linux-aarch64"
      return
    fi
    if [[ -d "${prebuilt}/linux-x86_64" ]]; then
      echo "linux-x86_64"
      return
    fi
  fi
  local one
  one="$(ls -1 "${prebuilt}" 2>/dev/null | head -n1)"
  if [[ -n "${one}" ]]; then
    echo "${one}"
    return
  fi
  return 1
}

export_android_ndk_toolchain() {
  local ndk host_tag toolbin api
  api="${ANDROID_NATIVE_API_LEVEL}"
  if ! ndk="$(resolve_ndk_home)"; then
    echo ""
    echo "ERROR: Android NDK not found (need clang for ring / native deps)."
    echo "Fix one of:"
    echo "  - Android Studio → Settings → Android SDK → SDK Tools → NDK (Side by side)"
    echo "  - export ANDROID_NDK_HOME=/path/to/ndk/<version>"
    echo "  - export ANDROID_SDK_ROOT=...   (we pick newest .../ndk/*)"
    return 1
  fi
  if ! host_tag="$(resolve_ndk_host_tag "${ndk}")"; then
    echo "ERROR: Unsupported host for NDK cross-compile (uname: $(uname -s) $(uname -m))"
    return 1
  fi
  toolbin="${ndk}/toolchains/llvm/prebuilt/${host_tag}/bin"
  if [[ ! -d "${toolbin}" ]]; then
    echo "ERROR: Missing NDK LLVM toolchain: ${toolbin}"
    echo "Check ANDROID_NDK_HOME=${ndk} and host prebuilt folder name."
    return 1
  fi

  export PATH="${toolbin}:${PATH}"

  local cc_bin=""
  case "${ANDROID_RUST_TARGET}" in
    aarch64-linux-android)
      export CC_aarch64_linux_android="${toolbin}/aarch64-linux-android${api}-clang"
      export CXX_aarch64_linux_android="${toolbin}/aarch64-linux-android${api}-clang++"
      export AR_aarch64_linux_android="${toolbin}/llvm-ar"
      export RANLIB_aarch64_linux_android="${toolbin}/llvm-ranlib"
      export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="${CC_aarch64_linux_android}"
      cc_bin="${CC_aarch64_linux_android}"
      ;;
    x86_64-linux-android)
      export CC_x86_64_linux_android="${toolbin}/x86_64-linux-android${api}-clang"
      export CXX_x86_64_linux_android="${toolbin}/x86_64-linux-android${api}-clang++"
      export AR_x86_64_linux_android="${toolbin}/llvm-ar"
      export RANLIB_x86_64_linux_android="${toolbin}/llvm-ranlib"
      export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="${CC_x86_64_linux_android}"
      cc_bin="${CC_x86_64_linux_android}"
      ;;
    armv7-linux-androideabi)
      export CC_armv7_linux_androideabi="${toolbin}/armv7a-linux-androideabi${api}-clang"
      export CXX_armv7_linux_androideabi="${toolbin}/armv7a-linux-androideabi${api}-clang++"
      export AR_armv7_linux_androideabi="${toolbin}/llvm-ar"
      export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="${CC_armv7_linux_androideabi}"
      cc_bin="${CC_armv7_linux_androideabi}"
      ;;
    *)
      echo "ERROR: Unsupported ANDROID_RUST_TARGET=${ANDROID_RUST_TARGET}"
      echo "Add a clang mapping in scripts/bundle_rust_android.sh or set RUST_BACKEND_BINARY."
      return 1
      ;;
  esac

  if [[ ! -x "${cc_bin}" ]]; then
    echo "ERROR: Android clang missing or not executable: ${cc_bin}"
    echo "Try ANDROID_NATIVE_API_LEVEL=26 or install a full NDK (Side by side)."
    return 1
  fi

  echo "==> NDK: ${ndk}"
  echo "==> Toolchain: ${toolbin} (API ${api})"
}

RUST_BIN="${RUST_BACKEND_BINARY:-}"

if [[ -z "${RUST_BIN}" ]]; then
  if [[ ! -d "${RUST_BACKEND_ROOT}" ]]; then
    echo "Rust backend not found: ${RUST_BACKEND_ROOT}"
    echo "Set RUST_BACKEND_ROOT or RUST_BACKEND_BINARY=/path/to/tunify-rust-backend"
    exit 1
  fi

  export_android_ndk_toolchain || exit 1

  echo "==> Ensuring Rust target ${ANDROID_RUST_TARGET} is installed"
  rustup target add "${ANDROID_RUST_TARGET}" >/dev/null 2>&1 || rustup target add "${ANDROID_RUST_TARGET}"

  echo "==> Building ${PROFILE} ${ANDROID_RUST_TARGET} in ${RUST_BACKEND_ROOT}"
  if [[ "${PROFILE}" == "release" ]]; then
    (cd "${RUST_BACKEND_ROOT}" && cargo build --release --target "${ANDROID_RUST_TARGET}")
  else
    (cd "${RUST_BACKEND_ROOT}" && cargo build --target "${ANDROID_RUST_TARGET}")
  fi

  RUST_BIN="${RUST_BACKEND_ROOT}/target/${ANDROID_RUST_TARGET}/${PROFILE}/tunify-rust-backend"
fi

if [[ ! -f "${RUST_BIN}" ]]; then
  echo "Binary not found: ${RUST_BIN}"
  exit 1
fi

if [[ ! -f "${BUNDLE_ENV_SOURCE}" ]]; then
  echo "Bundled env file not found: ${BUNDLE_ENV_SOURCE}"
  echo "Create Rust-Backend/.env.bundle (or set BUNDLE_ENV_SOURCE=...)"
  exit 1
fi

mkdir -p "$(dirname "${DEST}")"
cp "${RUST_BIN}" "${DEST}"
chmod +x "${DEST}"
awk '
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  /^[A-Za-z_][A-Za-z0-9_]*=/ {
    sub(/^[[:space:]]+/, "", $0)
    print
  }
' "${BUNDLE_ENV_SOURCE}" > "${RUNTIME_ENV_DEST}"
echo "==> Copied bundled backend to ${DEST} (target=${ANDROID_RUST_TARGET} profile=${PROFILE})"
echo "==> Synced bundled runtime env to ${RUNTIME_ENV_DEST} (source=${BUNDLE_ENV_SOURCE})"
