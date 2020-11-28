standalone_toolchain=/usr/local/gcc-arm
target_host=arm-none-eabi

[build_requires]
[env]
CHOST=$target_host
AR=$standalone_toolchain/bin/$target_host-ar
AS=$standalone_toolchain/bin/$target_host-as
RANLIB=$standalone_toolchain/bin/$target_host-ranlib
CC=$standalone_toolchain/bin/$target_host-gcc
CXX=$standalone_toolchain/bin/$target_host-g++
STRIP=$standalone_toolchain/bin/$target_host-strip
RC=$standalone_toolchain/bin/$target_host-windres

[settings]
os_build=Linux
arch_build=x86_64

os=Particle
compiler=gcc

compiler.version=5.3
compiler.libcxx=libstdc++11
build_type=Release
