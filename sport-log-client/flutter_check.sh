flutter pub get
flutter format --set-exit-if-changed .
flutter analyze
# flutter build apk # needs SDK_REGISTRY_TOKEN in env args
# flutter test # needs SDK_REGISTRY_TOKEN in env args
jscpd --min-lines 20 --reporters consoleFull lib/