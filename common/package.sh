#!/usr/bin/env bash

export PLATFORM=$1

arch="nRF52840"
if [[ "$PLATFORM" == "photon" ]] || [[ "$PLATFORM" == "electron" ]]; then
  arch="stm32f2xx"
fi

echo "packaging $arch $PLATFORM..."
echo "generating config..."
printconf.sh "$PLATFORM"

echo "building device-os..."
make -C "$FIRMWARE_DIR/main" > /dev/null

echo "set(PLATFORM $PLATFORM)" > "$PROJECTS_DIR/cmake/platform.cmake"

echo "packaging artifacts..."
conan export-pkg -pr "$PROJECTS_DIR/particle.profile" --force -s os.board="$PLATFORM" -s arch="$arch" "$PROJECTS_DIR/conanfile.py" jw3/2.0.0 | tail

du -sh "$HOME/.conan/data/particle/2.0.0/jw3/pure/package"

echo "done!"
