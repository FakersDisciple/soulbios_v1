#!/bin/bash
# Build script for SoulBios Flutter app with production configuration

echo "Building SoulBios Flutter app for production..."

# Build for Android with production API configuration
flutter build apk --release \
  --dart-define=API_BASE_URL=https://soulbios-v1-747hyhhxdq-uc.a.run.app \
  --dart-define=API_KEY=FVaiUzD7ipeSQi37RcuGQAbIsjkGqed8S0J2IT0znsnFolkPTAHfvceAYbAkNJc5

echo "Production APK built successfully!"
echo "Location: build/app/outputs/flutter-apk/app-release.apk"