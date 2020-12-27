device-os
===

### build dockerfile

`docker build -t particle-conan-build:1.4.2 --build-arg VER=1.4.2 .`

### package from docker

`docker run --rm -it particle-conan-build xenon`

### conan install

some settings need cleaned up, for now it takes a longer config string

`PLATFORM=xenon VERSION_STRING=1.4.2 conan install . -if <bin-dir> -s compiler.version=5.3 -s os=Particle -s os.board=xenon -s arch=nRF52840 -s compiler.libcxx=libstdc++11`

### optional

Add a descriptive error when conan install has not initialized the build directory

```cmake
if (NOT EXISTS ${CMAKE_BINARY_DIR}/conanbuildinfo.cmake)
    message(FATAL_ERROR "The file conanbuildinfo.cmake doesn't exist, you have to run conan install first")
endif ()
```

check tinker

```text
arm-none-eabi-size --format=berkeley /usr/local/src/particle/firmware/user/applications/tinker/target/tinker.elf
   text	   data	    bss	    dec	    hex	filename
  13348	    156	   1428	  14932	   3a54	/usr/local/src/particle/firmware/user/applications/tinker/target/tinker.elf

```
