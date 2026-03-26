# ── Code Generation ────────────────────────────────────────────────────
gen:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

clean:
	flutter clean && flutter pub get

analyze:
	flutter analyze

test:
	flutter test

release-apk:
	flutter build apk --release --obfuscate --split-debug-info=build/debug-info

.PHONY: gen watch clean analyze test release-apk
