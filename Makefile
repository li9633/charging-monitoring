.PHONY: build run clean

build:
	flutter build apk --split-per-abi --release

run:
	flutter run -d emulator-5554

clean:
	flutter clean && flutter pub get