#!/bin/bash

set -euo pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
cd "$project_dir"

printf '\nSecure By Design — iPhone setup\n\n'

if ! command -v flutter >/dev/null 2>&1; then
  printf 'Flutter is not available in this Terminal session.\n'
  printf 'Install it from https://docs.flutter.dev/install/manual, then run this file again.\n'
  printf '\nPress Return to close.\n'
  read -r
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  printf 'Xcode command-line tools are not available.\n'
  printf 'Install and open Xcode, finish its first-run setup, then run this file again.\n'
  printf '\nPress Return to close.\n'
  read -r
  exit 1
fi

printf 'Flutter:\n'
flutter --version | head -n 1
printf '\nXcode:\n'
xcodebuild -version | head -n 2

printf '\nRestoring the app packages...\n'
flutter pub get

printf '\nChecking the iOS development setup...\n'
flutter doctor

printf '\nOpening the iOS workspace in Xcode...\n'
open ios/Runner.xcworkspace

printf '\nNext in Xcode:\n'
printf '1. Select the Runner target.\n'
printf '2. Open Signing & Capabilities.\n'
printf '3. Enable Automatically manage signing.\n'
printf '4. Choose your Personal Team.\n'
printf '5. Select your iPhone or an iPhone simulator and press Run.\n'
printf '\nThe detailed guide is IPHONE_SETUP.md.\n'
printf '\nPress Return to close this window after Xcode opens.\n'
read -r
