#!/usr/bin/env bash

export PLATFORM=$1

arch="nRF52840"
if [[ "$PLATFORM" == "photon" ]] || [[ "$PLATFORM" == "electron" ]]; then
  arch="stm32f2xx"
fi

export "$(head -n1 /src/build/version.mk | tr -d ' ')"

echo "packaging $arch $PLATFORM $VERSION_STRING..."
echo "generating config..."
printconf.sh "$PLATFORM"

echo "building device-os..."
make -C "$FIRMWARE_DIR/main" > /dev/null

echo "set(PLATFORM $PLATFORM)" > "$PROJECTS_DIR/cmake/platform.cmake"

echo "packaging artifacts..."
conan export-pkg -pr "$PROJECTS_DIR/particle.profile" --force -s os.board="$PLATFORM" -s arch="$arch" "$PROJECTS_DIR/conanfile.py" hicktech/particle | tail

du -sh "$HOME/.conan/data/$PLATFORM/$VERSION_STRING/hicktech/particle/package"

echo "done!"
