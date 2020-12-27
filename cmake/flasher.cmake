configure_file(${CONAN_${PLATFORM}_ROOT}/common/flash.in ${CMAKE_BINARY_DIR}/flash @ONLY)
configure_file(${CONAN_${PLATFORM}_ROOT}/common/flash.mk.in ${CMAKE_BINARY_DIR}/${name}/flash.mk)
