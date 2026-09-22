#!/usr/bin/env bash
set -euo pipefail

APK_URL="https://github.com/MojoLauncher/MojoLauncher/releases/download/nightly/MojoLauncher-release.apk"
WORKDIR="aar_build"
OUTDIR="out"
AAR_NAME="mesa.aar"
AAR_PACKAGE="com.maxjubayeryt.copper.libs"

LIBS_ALL_ABI=(libEGL_mesa.so libgallium_dri.so libdrm.so)
LIBS_ARM64_ONLY=(libvulkan_freedreno.so)
ABIS=(armeabi-v7a arm64-v8a x86 x86_64)

rm -rf "$WORKDIR" "$OUTDIR"
mkdir -p "$WORKDIR" "$OUTDIR"

echo "Downloading Mojo APK"
curl -fL -o "$WORKDIR/mojo.apk" "$APK_URL"

echo "Extracting APK"
unzip -q "$WORKDIR/mojo.apk" -d "$WORKDIR/apk"

for abi in "${ABIS[@]}"; do
  src="$WORKDIR/apk/lib/$abi"
  [ -d "$src" ] || continue
  dst="$WORKDIR/jni/$abi"
  mkdir -p "$dst"

  for lib in "${LIBS_ALL_ABI[@]}"; do
    if [ -f "$src/$lib" ]; then
      cp "$src/$lib" "$dst/"
    fi
  done

  if [ "$abi" = "arm64-v8a" ]; then
    for lib in "${LIBS_ARM64_ONLY[@]}"; do
      if [ -f "$src/$lib" ]; then
        cp "$src/$lib" "$dst/"
      fi
    done
  fi

  if [ -z "$(ls -A "$dst" 2>/dev/null)" ]; then
    rmdir "$dst"
  fi
done

if [ ! -d "$WORKDIR/jni" ]; then
  echo "No matching libs found in the Mojo APK, aborting" >&2
  exit 1
fi

echo "Libs collected:"
find "$WORKDIR/jni" -type f | sort

cat > "$WORKDIR/AndroidManifest.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$AAR_PACKAGE">
</manifest>
EOF

mkdir -p "$WORKDIR/emptyjar"
touch "$WORKDIR/emptyjar/.keep"
( cd "$WORKDIR/emptyjar" && zip -q -X ../classes.jar .keep )

cd "$WORKDIR"
zip -qr -X "../$OUTDIR/$AAR_NAME" AndroidManifest.xml classes.jar jni
cd ..

echo "Built $OUTDIR/$AAR_NAME"
sha256sum "$OUTDIR/$AAR_NAME"
