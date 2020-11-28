# build user.o
# ar user.o libuser.o
# generate platform_user_ram.ld
# link app.elf (modules/xenon/user-part)
# re-generate platform_user_ram.ld
# link app.elf (modules/xenon/user-part)
# mv app_fi.elf app.elf

set(BUILD_DIR ${CMAKE_BINARY_DIR})
set(GCC_ARM_PATH /usr/local/gcc-arm/bin)
set(FIRMWARE_DIR /usr/local/src/particle/firmware)

# CONAN_SETTINGS_OS_BOARD

function(particle_app name)
    include(particle)

    set(CONAN_SRC_DEPS "")
    foreach (dep IN LISTS CONAN_DEPENDENCIES)
        string(TOUPPER ${dep} DEP)
        file(GLOB dep_src ${CONAN_SRC_DIRS_${DEP}}/*.c ${CONAN_SRC_DIRS_${DEP}}/*.h ${CONAN_SRC_DIRS_${DEP}}/*.cpp ${CONAN_SRC_DIRS_${DEP}}/*.hpp)
        list(LENGTH dep_src dep_cnt)
        if(${dep_cnt} GREATER 0)
            message(STATUS "Adding ${dep_cnt} sources from ${dep} at ${CONAN_SRC_DIRS_${DEP}}")
            list(APPEND CONAN_SRC_DEPS ${dep_src})
        endif()
    endforeach ()

    set(MODULE_PATH ${CONAN_PARTICLE_ROOT}/modules/${PLATFORM})
    set(USER_PART_MODULE_PATH ${MODULE_PATH}/user-part)
    set(USER_PART_MODULE_CSRC_PATH ${USER_PART_MODULE_PATH}/src/*.c)
    set(USER_PART_MODULE_CXXSRC_PATH ${USER_PART_MODULE_PATH}/src/*.cpp)
    file(GLOB USER_PART_MODULE_CSRC ${USER_PART_MODULE_CSRC_PATH})
    file(GLOB USER_PART_MODULE_CXXSRC ${USER_PART_MODULE_CXXSRC_PATH})

    # todo;; hack; these arent being extracted at the moment
    include_directories(${CONAN_INCLUDE_DIRS_PARTICLE}/user/inc
                        ${CONAN_PARTICLE_ROOT}/modules/shared/${CONAN_SETTINGS_ARCH}/inc
                        ${CONAN_INCLUDE_DIRS_PARTICLE}/modules/shared/${CONAN_SETTINGS_ARCH}/inc/user-part)

    add_library(user-part-c STATIC ${USER_PART_MODULE_CSRC})
    target_include_directories(user-part-c PRIVATE ${USER_CXX_INCLUDES})
    target_compile_options(user-part-c PRIVATE ${USER_CC_FLAGS})
    target_compile_definitions(user-part-c PRIVATE ${ELF_CXX_DEFS}) # todo;; platform_id missing from user defs

    add_library(user-part-cpp STATIC ${USER_PART_MODULE_CXXSRC})
    target_include_directories(user-part-cpp PRIVATE ${USER_CXX_INCLUDES})
    target_compile_options(user-part-cpp PRIVATE ${USER_CC_FLAGS} ${USER_CXX_FLAGS})
    target_compile_definitions(user-part-cpp PRIVATE ${ELF_CXX_DEFS}) # todo;; platform_id missing from user defs


    add_custom_command(TARGET user-part-c POST_BUILD
                       COMMAND ${CMAKE_CXX_COMPILER_AR} x $<TARGET_FILE:user-part-c>
                       WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                       BYPRODUCTS user_module.c.o module_info.c.o user_export.c.o
                       COMMENT "Extracting c object files")

    add_custom_command(TARGET user-part-cpp POST_BUILD
                       COMMAND ${CMAKE_CXX_COMPILER_AR} x $<TARGET_FILE:user-part-cpp>
                       WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                       BYPRODUCTS newlib_stubs.cpp.o
                       COMMENT "Extracting cpp object files")

    set(APP_DIR ${CMAKE_SOURCE_DIR}/${name})
    file(GLOB SOURCE_FILES ${APP_DIR}/*.cpp ${APP_DIR}/*.hpp ${APP_DIR}/*.h)

    list(LENGTH SOURCE_FILES src_cnt)
    message(STATUS "Adding ${src_cnt} sources from ${name}")
    list(APPEND SOURCE_FILES ${CONAN_SRC_DEPS})


    add_library(user STATIC ${SOURCE_FILES})
    target_include_directories(user PRIVATE ${CONAN_INCLUDE_DIRS} ${USER_CXX_INCLUDES})
    target_compile_options(user PRIVATE ${USER_CC_FLAGS} ${USER_CXX_FLAGS})
    target_compile_definitions(user PRIVATE ${ELF_CXX_DEFS})

    #link options here?

    set(pre ${name}_pre)
    add_executable(${pre} user_module.c.o module_info.c.o user_export.c.o newlib_stubs.cpp.o)
    set_target_properties(${pre} PROPERTIES OUTPUT_NAME ${pre}.elf)
    target_link_libraries(${pre} PRIVATE -Wl,--whole-archive user ${CONAN_LIBS_PARTICLE} -Wl,--no-whole-archive)
    target_link_directories(${pre} PRIVATE ${CMAKE_BINARY_DIR} ${CONAN_LIB_DIRS_PARTICLE} ${ELF_LD_PATHS})
    target_link_options(${pre} PRIVATE ${ELF_LD_FLAGS} ${ELF_CC_FLAGS} ${ELF_CXX_FLAGS})

    target_include_directories(${pre} PRIVATE ${CONAN_INCLUDE_DIRS} ${ELF_CXX_INCLUDES})
    target_compile_options(${pre} PRIVATE ${ELF_CC_FLAGS} ${ELF_CXX_FLAGS})
    target_compile_definitions(${pre} PRIVATE ${ELF_CXX_DEFS})

    add_custom_command(TARGET user PRE_BUILD
                       COMMAND cp ${CONAN_PARTICLE_ROOT}/common/platform_user_ram.ld platform_user_ram.ld
                       BYPRODUCTS platform_user_ram.ld
                       WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                       COMMENT "Copy initial platform_user_ram.ld")

    add_custom_command(TARGET ${pre} POST_BUILD
                       COMMAND rm platform_user_ram.ld
                       WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                       COMMENT "Delete initial platform_user_ram.ld")

    add_custom_command(TARGET ${pre} POST_BUILD
                       COMMAND GCC_ARM_PATH=/usr/local/gcc-arm/bin/ MODULE_USER_MEMORY_FILE_GEN=${CMAKE_BINARY_DIR}/platform_user_ram.ld INTERMEDIATE_ELF=$<TARGET_FILE:${pre}> make -f common/build_linker_script.mk
                       BYPRODUCTS platform_user_ram.ld
                       WORKING_DIRECTORY ${CONAN_PARTICLE_ROOT}
                       COMMENT "Generate final platform_user_ram.ld")


    set(final ${name})
    add_executable(${final} user_module.c.o module_info.c.o user_export.c.o newlib_stubs.cpp.o)
    set_target_properties(${final} PROPERTIES OUTPUT_NAME ${final}.elf)
    target_link_libraries(${final} PRIVATE -Wl,--whole-archive user ${CONAN_LIBS_PARTICLE} -Wl,--no-whole-archive)
    target_link_directories(${final} PRIVATE ${CMAKE_BINARY_DIR} ${CONAN_LIB_DIRS_PARTICLE} ${ELF_LD_PATHS})
    target_link_options(${final} PRIVATE ${ELF_LD_FLAGS} ${ELF_CC_FLAGS} ${ELF_CXX_FLAGS})

    target_include_directories(${final} PRIVATE ${CONAN_INCLUDE_DIRS} ${ELF_CXX_INCLUDES})
    target_compile_options(${final} PRIVATE ${ELF_CC_FLAGS} ${ELF_CXX_FLAGS})
    target_compile_definitions(${final} PRIVATE ${ELF_CXX_DEFS})

    add_custom_command(TARGET ${name} POST_BUILD
                       COMMAND ELF=${name}.elf make -f ${CONAN_PARTICLE_ROOT}/common/bin.mk
                       BYPRODUCTS ${name}.bin
                       WORKING_DIRECTORY ${CMAKE_BINARY_DIR})

    add_custom_command(TARGET ${name} POST_BUILD
                       COMMAND /usr/local/gcc-arm/bin/arm-none-eabi-size
                       ARGS --format=berkeley ${name}.elf)

    include(flasher)
endfunction(particle_app)
