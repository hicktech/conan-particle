configure_file(${CONAN_PARTICLE_ROOT}/common/flash.in ${CMAKE_BINARY_DIR}/flash @ONLY)
configure_file(${CONAN_PARTICLE_ROOT}/common/flash.mk.in ${CMAKE_BINARY_DIR}/${name}/flash.mk)
