#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
spendy_check_dir=$(mktemp -d /tmp/spendy-release-check.XXXXXX)
spendy_test_destination=${SPENDY_TEST_DESTINATION:-'platform=iOS Simulator,name=iPhone 17 Pro'}
print "Validation artifacts: $spendy_check_dir"
xcodebuild -project Spendy.xcodeproj -scheme Spendy -configuration Debug \
  -destination "$spendy_test_destination" -derivedDataPath "$spendy_check_dir/build" \
  -resultBundlePath "$spendy_check_dir/tests.xcresult" test > "$spendy_check_dir/tests.log" 2>&1
xcodebuild -project Spendy.xcodeproj -scheme Spendy -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$spendy_check_dir/Spendy.xcarchive" \
  archive > "$spendy_check_dir/archive.log" 2>&1
codesign --verify --deep --strict "$spendy_check_dir/Spendy.xcarchive/Products/Applications/Spendy.app"
print 'Tests, signed archive, and signature verification passed.'
