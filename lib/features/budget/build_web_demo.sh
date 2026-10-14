#!/usr/bin/env bash
# Build a standalone demo without adding a web platform to the shared app.
set -euo pipefail
feature_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_dir=$(cd "$feature_dir/../../.." && pwd)
demo_dir=$(mktemp -d /tmp/meridian-budget-web.XXXXXX)
flutter create --platforms=web --project-name smart_travel_assistant --no-pub "$demo_dir"
cp "$project_dir/pubspec.yaml" "$project_dir/pubspec.lock" "$demo_dir/"
mv "$demo_dir/lib" "$demo_dir/generated-lib"
ln -s "$project_dir/lib" "$demo_dir/lib"
ln -s "$project_dir/assets" "$demo_dir/assets"
cd "$demo_dir"
flutter pub get --enforce-lockfile
flutter build web --no-pub --no-web-resources-cdn \
  --target lib/features/budget/budget_demo.dart --dart-define=USE_FAKE_DATA=true
printf '\nHost the contents of this directory: %s/build/web\n' "$demo_dir"
