#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
swift_source="$project_dir/native/MuseBridge.swift"
build_dir="$project_dir/native/build"
output="$project_dir/com.davidedicillo.muse.sdPlugin/bin/MuseBridge"
mkdir -p "$build_dir"

swiftc -target arm64-apple-macos12.0 -framework AppKit -framework ApplicationServices "$swift_source" -o "$build_dir/MuseBridge.arm64"
swiftc -target x86_64-apple-macos12.0 -framework AppKit -framework ApplicationServices "$swift_source" -o "$build_dir/MuseBridge.x86_64"
lipo -create "$build_dir/MuseBridge.arm64" "$build_dir/MuseBridge.x86_64" -output "$output"
rm "$build_dir/MuseBridge.arm64" "$build_dir/MuseBridge.x86_64"
rmdir "$build_dir"
