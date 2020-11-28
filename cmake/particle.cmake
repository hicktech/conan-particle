# see common-tools.mk
# see arm-tools.mk
# see gcc-tools.mk

# todo;; set these with appropriate path rooted to user_remote
#-MD
#-MP
#-MF
#../build/target/user/platform-14-m/workspace/application.o.d

include(platform)

message("\n=============================== Configuring firmware for the -=-= ${PLATFORM} =-=- ===============================\n")

# todo;; fail if CONAN_SETTINGS_ARCH is not set
# todo;; fail if CONAN_SETTINGS_OS_BOARD is not set

set(CMAKE_CXX_COMPILER "${GCC_ARM_PATH}/arm-none-eabi-g++")

include(ELF.cc.defines)
include(ELF.cc.includes)
include(ELF.cc.flags)
include(ELF.cxx.flags)
include(ELF.libs)
include(ELF.ld.paths)
include(ELF.ld.flags)

include(USER.cc.defines)
include(USER.cc.includes)
include(USER.cc.flags)
include(USER.cxx.flags)
include(USER.libs)
include(USER.ld.paths)
include(USER.ld.flags)
