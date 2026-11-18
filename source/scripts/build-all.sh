#!/usr/bin/env bash
# Format, build and test every Swift package under source/Packages.
# Exits non-zero on the first failure. Finding no packages is a failure, never a pass.
# App targets (xcodebuild) are not covered yet; the feature that adds the first app target extends this script.
set -euo pipefail

cd "$(dirname "$0")/../.."

packages=""
if [ -d source/Packages ]; then
  packages="$(find source/Packages -mindepth 2 -maxdepth 2 -name Package.swift | sed 's|/Package.swift$||' | sort)"
fi
if [ -z "$packages" ]; then
  echo "No Swift packages found under source/Packages." >&2
  exit 1
fi

echo "==> format"
# shellcheck disable=SC2086 # the package paths contain no spaces
swift format lint --strict --recursive $packages

while IFS= read -r package; do
  echo "==> build $package"
  swift build --package-path "$package"
  echo "==> test $package"
  swift test --package-path "$package"
done <<EOF
$packages
EOF

echo "==> build-all passed"
