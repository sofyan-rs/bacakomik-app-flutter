#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
VERSION=${1:-$(sed -nE 's/^version: *([^+ ]+).*/\1/p' "$ROOT/pubspec.yaml")}
BUNDLE="$ROOT/build/linux/x64/release/bundle"
RPM_DIR="$ROOT/build/rpm"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a release version such as 2.11.0, got: $VERSION" >&2
  exit 1
fi
if [[ ! -x "$BUNDLE/yoru" ]]; then
  echo "Missing Linux release bundle. Run flutter build linux --release first." >&2
  exit 1
fi
if ! command -v rpmbuild >/dev/null; then
  echo "rpmbuild is required (Fedora: sudo dnf install rpm-build; Ubuntu: sudo apt-get install rpm)." >&2
  exit 1
fi

dart "$ROOT/linux/packaging/check_bundle.dart" "$BUNDLE"
PRIVATE_REQUIRES=$(dart "$ROOT/linux/packaging/check_bundle.dart" --private-library-requires "$BUNDLE")

mkdir -p "$RPM_DIR"/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS} "$ROOT/dist"
STAGING=$(mktemp -d "$RPM_DIR/source.XXXXXX")
trap 'rm -rf "$STAGING"' EXIT
SOURCE="$STAGING/yoru-$VERSION"
mkdir -p "$SOURCE"
cp -a "$BUNDLE" "$SOURCE/bundle"
cp "$ROOT/linux/packaging/yoru.desktop" "$ROOT/linux/packaging/yoru.png" \
  "$ROOT/LICENSE" "$SOURCE/"
tar -czf "$RPM_DIR/SOURCES/yoru-$VERSION.tar.gz" -C "$STAGING" "yoru-$VERSION"

rpmbuild -bb \
  --define "_topdir $RPM_DIR" \
  --define "app_version $VERSION" \
  --define "yoru_private_requires $PRIVATE_REQUIRES" \
  "$ROOT/linux/packaging/yoru.spec"
PACKAGE="$RPM_DIR/RPMS/x86_64/yoru-$VERSION-1.x86_64.rpm"
PACKAGE_REQUIRES=$(rpm -qp --requires "$PACKAGE")
if grep -E "$PRIVATE_REQUIRES" <<< "$PACKAGE_REQUIRES"; then
  echo "RPM incorrectly requires a private bundled library." >&2
  exit 1
fi
cp "$PACKAGE" \
  "$ROOT/dist/Yoru-$VERSION-linux-x86_64.rpm"
