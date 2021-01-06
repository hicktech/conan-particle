#!/usr/bin/env bash

readonly usage="usage: $(basename $0) <platform-name>"
readonly platform_name=$1
readonly PLATFORM_NAME=${platform_name^^}
readonly firmware_dir=${2:-${FIRMWARE_DIR}}

format_conf() {
  echo "$1" | sed -e 's#\s#\n#g'
}

build_conf() {
  local flag=$1
  local conf=$2

  local ccflags=$(echo "$conf" | grep "${flag}_CC" | awk -F'===' '{print $2}')
  local cxflags=$(echo "$conf" | grep "${flag}_CX" | awk -F'===' '{print $2}')
  local ldflags=$(echo "$conf" | grep "${flag}_LD" | awk -F'===' '{print $2}')

  format_conf "$ccflags" | sed '/^$/d' > "$flag.cc.full"
  format_conf "$cxflags" | sed '/^$/d' > "$flag.cx.full"
  format_conf "$ldflags" | sed '/^$/d' > "$flag.ld.full"

  grep -e '^-D' "$flag.cc.full" | sed 's#-D##'> "$flag.cc.defines"
  grep -e '^-I' "$flag.cc.full" | sed 's#-I##' |  sed 's#\.*\./*##g' > "$flag.cc.includes.raw"
  grep -e '^-[^DI]' "$flag.cc.full" > "$flag.cc.options"

  grep -e '^-L' "$flag.ld.full" | sed 's#-L##' |  sed 's#\.*\./*##g' | head -n-2 > "$flag.ld.paths.raw"
  grep -e '^-l' "$flag.ld.full" | sed 's#-l##' > "$flag.ld.libs"
  grep -e '^-[^Ll]' "$flag.ld.full" | grep -v -e '-Map' | sed "s#^-T./#-T\${CONAN_${PLATFORM_NAME}_ROOT}/modules/$platform_name/user-part/#" > "$flag.ld.options"

  # build cmake include variable
  echo "set(${flag}_CXX_INCLUDES" > "$flag.cc.includes.cmake"
  sed "s#^#  \${CONAN_INCLUDE_DIRS_${PLATFORM_NAME}}/#" "$flag.cc.includes.raw" >> "$flag.cc.includes.cmake"
  echo ")" >> "$flag.cc.includes.cmake"

  # build cmake definitions variable
  echo "set(${flag}_CXX_DEFS" > "$flag.cc.defines.cmake"
  sed 's#^#  #' "$flag.cc.defines" >> "$flag.cc.defines.cmake"
  echo ")" >> "$flag.cc.defines.cmake"

  # build cmake libs variable
  echo "set(${flag}_CXX_LIBS" > "$flag.libs.cmake"
  sed 's#^#  #' "$flag.ld.libs" | grep -v nosys >> "$flag.libs.cmake"
  echo ")" >> "$flag.libs.cmake"

  # build cmake cc options variable
  echo "set(${flag}_CC_FLAGS" > "$flag.cc.flags.cmake"
  sed 's#^#  #' "$flag.cc.options" >> "$flag.cc.flags.cmake"
  echo ")" >> "$flag.cc.flags.cmake"

  # build cmake cxx options variable
  echo "set(${flag}_CXX_FLAGS" > "$flag.cxx.flags.cmake"
  sed 's#^#  #' "$flag.cx.full" >> "$flag.cxx.flags.cmake"
  echo ")" >> "$flag.cxx.flags.cmake"

  # build cmake ld options variable
  echo "set(${flag}_LD_FLAGS" > "$flag.ld.flags.cmake"
  sed 's#^#  #' "$flag.ld.options" >> "$flag.ld.flags.cmake"
  echo ")" >> "$flag.ld.flags.cmake"

  # build cmake ld paths variable
  echo "set(${flag}_LD_PATHS" > "$flag.ld.paths.cmake"
  grep "$flag.ld.paths.raw" -ve ^build/target | xargs -I{} echo "\${CONAN_${PLATFORM_NAME}_ROOT}/{}" >> "$flag.ld.paths.cmake"
  echo "\${CONAN_${PLATFORM_NAME}_ROOT}/modules/$platform_name/user-part" >> "$flag.ld.paths.cmake"
  echo "\${CONAN_${PLATFORM_NAME}_ROOT}/lib" >> "$flag.ld.paths.cmake"
  echo ")" >> "$flag.ld.paths.cmake"
}

combine_conf() {
  cat ELF.cc.includes.raw > cc.includes.tmp
  cat USER.cc.includes.raw >> cc.includes.tmp
  uniq < cc.includes.tmp > cc.includes

  cat ELF.ld.paths.raw > ld.paths.tmp
  cat USER.ld.paths.raw >> ld.paths.tmp
  uniq < ld.paths.tmp > ld.paths
}

main() {
  readonly user="$firmware_dir/user"
  readonly user_part="$firmware_dir/modules/$platform_name/user-part"
  readonly build_dir="$firmware_dir/build"

  printf "\ninclude %s/printconf.mk\n" "$build_dir" >> "$build_dir/arm-tlm.mk"

  export APPDIR="$user/src"
  export PLATFORM="$platform_name"

  # capture all config
  readonly userconf=$(make -C "$user" userconf | grep '===')
  readonly elfconf=$(make -C "$user_part" elfconf | grep '===')

  build_conf USER "$userconf"
  build_conf ELF "$elfconf"

  combine_conf
}

main "$@"
