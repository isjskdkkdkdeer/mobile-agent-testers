#!/usr/bin/env bash
# Build the YueLiao iOS app for the Simulator, reusing the app's own build
# workflow: the Swift sources live as heredocs inside
# .github/workflows/build-yueliao.yml, so extract that workflow's build step,
# swap the device destination for the Simulator, and skip the IPA packaging.
# Run from the checked-out yueliao repo root (APP_DIR for the template).
# Output: native-ios/build/Build/Products/Release-iphonesimulator/YueLiao.app
set -euo pipefail
WF=.github/workflows/build-yueliao.yml
[ -f "$WF" ] || { echo "yueliao workflow not found in $PWD" >&2; exit 1; }
TMP=$(mktemp -d)
python3 - "$WF" "$TMP/build.sh" <<'PYEOF'
import sys
wf, out = sys.argv[1], sys.argv[2]
lines = open(wf, encoding='utf-8').read().splitlines()
start = next(i for i, l in enumerate(lines) if l.rstrip() == '      - run: |')
body = []
for l in lines[start + 1:]:
    if l.startswith('      - ') and l.strip().startswith(('- uses:', '- name:', '- run:')):
        break
    body.append(l[10:] if l.startswith(' ' * 10) else l)
# Cut everything from IPA packaging on; keep through the xcodebuild check.
cut = next(i for i, l in enumerate(body) if l.strip() == 'mkdir Payload')
body = body[:cut]
text = '\n'.join(body)
text = text.replace(
    "xcodebuild -project YueLiao.xcodeproj -scheme YueLiao -configuration Release -destination 'generic/platform=iOS'",
    "xcodebuild -project YueLiao.xcodeproj -scheme YueLiao -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator'")
open(out, 'w', encoding='utf-8').write(text + '\n')
PYEOF
bash "$TMP/build.sh"
APP=native-ios/build/Build/Products/Release-iphonesimulator/YueLiao.app
[ -d "$APP" ] || { echo "Simulator .app not found at $APP" >&2; exit 1; }
echo "Simulator app ready: $APP"
