#!/bin/bash
# Build the three static codec libs scrap/build.rs needs (libvpx, libyuv, aom),
# mirroring rustdesk's res/vcpkg overlay ports, into a vcpkg-shaped install tree.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"

export PATH="$ROOT/tools/cmake-3.31.6-macos-universal/CMake.app/Contents/bin:$ROOT/tools/nasm-2.16.03:$PATH"
CMAKE="$ROOT/tools/cmake-3.31.6-macos-universal/CMake.app/Contents/bin/cmake"
JOBS="$(sysctl -n hw.ncpu)"

PREFIX="$ROOT/vendor/vcpkg/installed/x64-osx"
mkdir -p "$PREFIX/lib" "$PREFIX/include"
echo "== tools =="; cmake --version | head -1; nasm --version; echo "jobs=$JOBS prefix=$PREFIX"

echo "== [1/3] libyuv =="
mkdir -p "$ROOT/build/libyuv"
"$CMAKE" -S "$ROOT/src" -B "$ROOT/build/libyuv" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DBUILD_SHARED_LIBS=OFF -DTEST=OFF
"$CMAKE" --build "$ROOT/build/libyuv" --parallel "$JOBS"
"$CMAKE" --install "$ROOT/build/libyuv"
# guarantee header layout even if install rules differ
[ -f "$PREFIX/include/libyuv/convert.h" ] || { mkdir -p "$PREFIX/include/libyuv" && cp -R "$ROOT/src/include/libyuv/." "$PREFIX/include/libyuv/"; }

echo "== [2/3] libvpx =="
mkdir -p "$ROOT/build/libvpx"
cd "$ROOT/build/libvpx"
"$ROOT/src/libvpx-1.15.2/configure" --prefix="$PREFIX" \
  --enable-static --disable-shared --enable-pic \
  --disable-examples --disable-tools --disable-docs --disable-unit-tests \
  --as=nasm
make -j"$JOBS"
make install
cd "$ROOT"

echo "== [3/3] aom (slow) =="
mkdir -p "$ROOT/build/aom"
"$CMAKE" -S "$ROOT/src/aom_tmp" -B "$ROOT/build/aom" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DENABLE_DOCS=OFF -DENABLE_EXAMPLES=OFF -DENABLE_TESTDATA=OFF \
  -DENABLE_TESTS=OFF -DENABLE_TOOLS=OFF
"$CMAKE" --build "$ROOT/build/aom" --parallel "$JOBS"
"$CMAKE" --install "$ROOT/build/aom"

echo "== RESULT =="
ls -la "$PREFIX/lib/"
test -f "$PREFIX/lib/libvpx.a" && test -f "$PREFIX/lib/libyuv.a" && test -f "$PREFIX/lib/libaom.a" \
  && test -f "$PREFIX/include/vpx/vpx_codec.h" && test -f "$PREFIX/include/aom/aom.h" \
  && test -f "$PREFIX/include/libyuv/convert.h" \
  && echo "ALL_CODEC_LIBS_OK" || echo "MISSING_SOMETHING"
