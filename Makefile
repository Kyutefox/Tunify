# Tunify Flutter + bundled Rust backend (Android).
#
# Default product behavior: local YouTube catalog + on-device backend until the user
# sets a hosted backend URL in Settings (then the existing gateway flow applies).
#
# Optional variables:
#   RUST_BACKEND_ROOT      Path to Rust-Backend repo (default: ../Rust-Backend)
#   ANDROID_RUST_TARGET    Rust triple (default: aarch64-linux-android; use x86_64-linux-android for some emulators)
#   FLUTTER_DEVICE         Passed to flutter -d when set
#   ANDROID_DEVICE_SERIAL  Alias for FLUTTER_DEVICE (useful when multiple adb devices are connected)
#
# Examples:
#   make run-android          # or: make android
#   make run-android FLUTTER_DEVICE=emulator-5554
#   make create-android       # or: make apk
#   make run-ios              # or: make ios
#   make create-ios           # or: make ipa
#
# Note: "make run android" is two goals (run + android). Use "make android" or "make run-android".

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

TUNIFY_ROOT := $(abspath .)
SCRIPTS := $(TUNIFY_ROOT)/scripts
RUST_BACKEND_ROOT ?= $(abspath $(TUNIFY_ROOT)/../Rust-Backend)
ANDROID_RUST_TARGET ?= aarch64-linux-android
export RUST_BACKEND_ROOT
export ANDROID_RUST_TARGET

.PHONY: help run-android run-ios create-android create-ios \
	bundle-android-debug bundle-android-release bundle-ios-debug bundle-ios-release flutter-pub-get \
	android ios apk ipa

help:
	@echo "Tunify mobile Makefile"
	@echo ""
	@echo "  make run-android   (alias: make android)   — NDK + Rust debug + embed + flutter run"
	@echo "  make run-ios       (alias: make ios)       — pod install + flutter run"
	@echo "  make create-android (alias: make apk)      — NDK + Rust release + embed + flutter build apk"
	@echo "  make create-ios    (alias: make ipa)      — pod install + flutter build ipa"
	@echo ""
	@echo "Optional: FLUTTER_DEVICE=...  ANDROID_DEVICE_SERIAL=...  RUST_BACKEND_ROOT=...  ANDROID_RUST_TARGET=..."
	@echo "NDK: ANDROID_NDK_HOME=...  ANDROID_SDK_ROOT=...  ANDROID_NATIVE_API_LEVEL=24 (default)"
	@echo "Skip compile: RUST_BACKEND_BINARY=/path/to/built/tunify-rust-backend ./scripts/bundle_rust_android.sh release"
	@echo ""
	@echo "Tip: use \"make android\" not \"make run android\" (the latter is two unrelated goals)."

android: run-android
ios: run-ios
apk: create-android
ipa: create-ios

flutter-pub-get:
	cd "$(TUNIFY_ROOT)" && flutter pub get

_chmod_scripts:
	@chmod +x "$(SCRIPTS)/bundle_rust_android.sh" 2>/dev/null || true
	@chmod +x "$(SCRIPTS)/bundle_rust_ios.sh" 2>/dev/null || true

# --- Android: embed Rust HTTP server for same-device 127.0.0.1:8080 ---

bundle-android-debug: _chmod_scripts
	ANDROID_RUST_TARGET="$(ANDROID_RUST_TARGET)" \
	RUST_BACKEND_ROOT="$(RUST_BACKEND_ROOT)" \
	RUST_BACKEND_BINARY="$(RUST_BACKEND_BINARY)" \
	ANDROID_NDK_HOME="$(ANDROID_NDK_HOME)" \
	ANDROID_NDK_VERSION="$(ANDROID_NDK_VERSION)" \
	ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" \
	ANDROID_HOME="$(ANDROID_HOME)" \
	ANDROID_NATIVE_API_LEVEL="$(ANDROID_NATIVE_API_LEVEL)" \
		"$(SCRIPTS)/bundle_rust_android.sh" debug

bundle-android-release: _chmod_scripts
	ANDROID_RUST_TARGET="$(ANDROID_RUST_TARGET)" \
	RUST_BACKEND_ROOT="$(RUST_BACKEND_ROOT)" \
	RUST_BACKEND_BINARY="$(RUST_BACKEND_BINARY)" \
	ANDROID_NDK_HOME="$(ANDROID_NDK_HOME)" \
	ANDROID_NDK_VERSION="$(ANDROID_NDK_VERSION)" \
	ANDROID_SDK_ROOT="$(ANDROID_SDK_ROOT)" \
	ANDROID_HOME="$(ANDROID_HOME)" \
	ANDROID_NATIVE_API_LEVEL="$(ANDROID_NATIVE_API_LEVEL)" \
		"$(SCRIPTS)/bundle_rust_android.sh" release

run-android: bundle-android-debug flutter-pub-get
	cd "$(TUNIFY_ROOT)" && \
	device="$${FLUTTER_DEVICE:-$${ANDROID_DEVICE_SERIAL:-}}"; \
	if [[ -n "$$device" ]]; then \
		flutter run -d "$$device"; \
	else \
		flutter run; \
	fi

create-android: bundle-android-release flutter-pub-get
	cd "$(TUNIFY_ROOT)" && flutter build apk --release
	@echo "==> APK artifacts under: $(TUNIFY_ROOT)/build/app/outputs/"

# --- iOS: build Rust xcframework + Flutter build ---

bundle-ios-debug: _chmod_scripts
	RUST_BACKEND_ROOT="$(RUST_BACKEND_ROOT)" \
		"$(SCRIPTS)/bundle_rust_ios.sh" debug
	cd "$(TUNIFY_ROOT)/ios" && pod install

bundle-ios-release: _chmod_scripts
	RUST_BACKEND_ROOT="$(RUST_BACKEND_ROOT)" \
		"$(SCRIPTS)/bundle_rust_ios.sh" release
	cd "$(TUNIFY_ROOT)/ios" && pod install

run-ios: bundle-ios-debug flutter-pub-get
	cd "$(TUNIFY_ROOT)" && \
	if [[ -n "$(FLUTTER_DEVICE)" ]]; then \
		flutter run -d "$(FLUTTER_DEVICE)"; \
	else \
		flutter run; \
	fi

create-ios: bundle-ios-release flutter-pub-get
	cd "$(TUNIFY_ROOT)" && flutter build ipa
	@echo "==> IPA: $(TUNIFY_ROOT)/build/ios/ipa/*.ipa"
