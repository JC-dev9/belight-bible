ENV_FILE = dart_env.json

.PHONY: run run-release build-apk build-aab clean

## Corre a app em modo debug no dispositivo ligado
run:
	flutter run --dart-define-from-file=$(ENV_FILE)

## Corre a app em modo release
run-release:
	flutter run --release --dart-define-from-file=$(ENV_FILE)

## Gera o APK de debug
build-apk:
	flutter build apk --dart-define-from-file=$(ENV_FILE)

## Gera o AAB para o Google Play
build-aab:
	flutter build appbundle --dart-define-from-file=$(ENV_FILE)

## Limpa artefactos de build
clean:
	flutter clean
