#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
swift test
plutil -lint IOSCourse-Exercise3/Info.plist IOSCourse-Exercise3/PrivacyInfo.xcprivacy IOSCourse-Exercise3.xcodeproj/project.pbxproj
xmllint --noout IOSCourse-Exercise3.xcodeproj/xcshareddata/xcschemes/IOSCourse-Exercise3.xcscheme
ibtool --errors --warnings --notices --minimum-deployment-target 15.0 IOSCourse-Exercise3/Base.lproj/Main.storyboard >/dev/null
multiples_destination="${IOS_MULTIPLES_DESTINATION:-platform=iOS Simulator,name=iPhone 16 Pro}"
xcodebuild -project IOSCourse-Exercise3.xcodeproj -scheme IOSCourse-Exercise3 -destination "$multiples_destination" -configuration Debug CODE_SIGNING_ALLOWED=NO test
xcodebuild -project IOSCourse-Exercise3.xcodeproj -scheme IOSCourse-Exercise3 -sdk iphonesimulator -configuration Release CODE_SIGNING_ALLOWED=NO analyze
