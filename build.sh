#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

project_path="$script_dir/SimpleMenuBarApp.xcodeproj"
scheme="SimpleMenuBarApp"
configuration="${CONFIGURATION:-Release}"
derived_data_path="${DERIVED_DATA_PATH:-$script_dir/build/DerivedData}"

echo "Building $scheme ($configuration)"
echo "Project: $project_path"
echo "DerivedData: $derived_data_path"

xcodebuild \
  -project "$project_path" \
  -scheme "$scheme" \
  -configuration "$configuration" \
  -derivedDataPath "$derived_data_path" \
  CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}" \
  build

echo
echo "Build output:"
echo "$derived_data_path/Build/Products/$configuration/$scheme.app"
