#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
village_check_dir=$(mktemp -d /tmp/memorygame-village.XXXXXX)
trap 'rm -rf "$village_check_dir"' EXIT
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swiftc \
  -module-cache-path "$village_check_dir/modules" \
  MemoryGame/Models/Village/VillageMap.swift \
  MemoryGame/Systems/Village/VillageNavigation.swift \
  Validation/Village/main.swift -o "$village_check_dir/checks"
"$village_check_dir/checks"
