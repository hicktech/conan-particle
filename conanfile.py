from conans import ConanFile
import os

platform_name = os.getenv("PLATFORM")
if not platform_name:
    raise ValueError('platform was not specified')

platform_version = os.getenv("VERSION_STRING")
if not platform_version:
    raise ValueError('version was not specified')

if platform_name in ['photon', 'electron']:
    arch_name = "stm32f2xx"
else:
    arch_name = "nRF52840"

build_dir = os.getenv("FIRMWARE_DIR", os.getcwd())
projs_dir = os.getenv("PROJECTS_DIR", os.getcwd())
common_dir = os.path.join(projs_dir, 'common')
cmake_dir = os.path.join(projs_dir, 'cmake')


def fw_src(relpath):
    return os.path.join(build_dir, relpath)


class ParticleFirmware(ConanFile):
    name = platform_name
    version = platform_version
    license = "Apache 2.0"
    url = "https://github.com/jw3/particle-conan"
    description = "Conan packages from the Particle firmware"
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False]}
    default_options = {"shared": False}
    generators = "cmake"
    app_dir = fw_src("user/src")

    def package(self):
        print(os.getcwd())

        # using include list, loop to copy headers
        with open('ELF.cc.includes.raw', 'r') as f:
            for p in f.readlines():
                p = p.strip()
                dest = "include/%s" % p
                self.copy("*.h", dst=dest, keep_path=True, src=fw_src(p))
                self.copy("*.inc", dst=dest, keep_path=True, src=fw_src(p))
                self.copy("*.ld", dst=dest, keep_path=True, src=fw_src(p))

        # using lib path list, loop to copy static libs
        with open('ELF.ld.paths.raw', 'r') as f:
            for p in f.readlines():
                p = p.strip()
                if p.startswith('build/target/user'):
                    continue;
                self.copy("*.a", dst="lib", keep_path=False, src=fw_src(p))
                self.copy("*.ld", dst=p, keep_path=True, src=fw_src(p))

        # optional headers, non automated
        self.copy("Serial*", dst="include", keep_path=True, src=fw_src("user/libraries"))

        # hal libs (automated?)
        hal_path = "hal/src/%s/lib" % platform_name
        self.copy("*.a", dst=hal_path, keep_path=True, src=fw_src(hal_path))

        # user-part src, non automated
        module_path = "modules/%s" % platform_name
        module_path_userpart = "%s/user-part" % module_path
        self.copy("*.ld", dst=module_path_userpart, keep_path=True, src=fw_src(module_path_userpart))

        module_path_src = os.path.join(module_path_userpart, 'src')
        self.copy("*.c*", dst=module_path_src, keep_path=True, src=fw_src(module_path_src))

        # special cases
        module_shared_path = 'modules/shared/%s' % arch_name
        self.copy("*", dst=module_shared_path, keep_path=True, src=fw_src(module_shared_path))

        # commons
        self.copy("*", dst='common', keep_path=True, src=common_dir)

        # cmake
        self.copy("*.cmake", src='.')
        self.copy("*.cmake", src=cmake_dir)

        # flasher support

        self.copy("modular.mk", dst=module_path, keep_path=True, src=fw_src(module_path))
        self.copy("common-tools.mk", dst='build', keep_path=True, src=fw_src('build'))
        self.copy("platform-id.mk", dst='build', keep_path=True, src=fw_src('build'))

    def package_info(self):
        self.cpp_info.libs = self.collect_libs()
