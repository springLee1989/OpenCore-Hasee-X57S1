#!/bin/bash
# Rebuild VoodooI2CHID PR #78 with Xcode. Do not compile this kext by hand:
# the earlier clang -mkernel build loaded, but the trackpad did not work.
set -euo pipefail

ROOT="/Users/springmacbookpro/x57s1/build"
PROJ="$ROOT/i2c/VoodooI2C Satellites/VoodooI2CHID/VoodooI2CHID.xcodeproj"
DERIVED="$ROOT/xcode-derived"
KEXT="$DERIVED/Build/Products/Release/VoodooI2CHID.kext"
EFI_KEXT="/Users/springmacbookpro/x57s1/EFI/OC/Kexts/VoodooI2CHID.kext"

xcodebuild \
  -project "$PROJ" \
  -scheme VoodooI2CHID \
  -configuration Release \
  -derivedDataPath "$DERIVED" \
  -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

rm -rf "$EFI_KEXT"
cp -a "$KEXT" "$EFI_KEXT"
codesign --force --sign - "$EFI_KEXT"
echo "INSTALLED $EFI_KEXT"
