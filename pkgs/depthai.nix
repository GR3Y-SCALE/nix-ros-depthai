# Override for nix-ros-overlay's `depthai` (depthai-core 2.x) that makes it
# build inside the Nix sandbox.
#
# depthai-core normally uses the Hunter package manager to download and build
# its dependencies at configure time, and then downloads device firmware from
# Luxonis' artifact server. Here Hunter is switched off, the dependencies come
# from nixpkgs (or pkgs/ in this repo), and the firmware is prefetched.
{
  lib,
  fetchurl,
  bzip2,
  zlib,
  libarchive,
  spdlog,
  ghc_filesystem,
  backward-cpp,
  xlink-luxonis,
  libnop-luxonis,
  fp16-luxonis,
}:

let
  # Firmware pinned by each depthai-core release, from
  # cmake/Depthai/DepthaiDeviceSideConfig.cmake and DepthaiBootloaderConfig.cmake.
  firmwareFor = {
    "2.31.1" = {
      deviceCommit = "393e4f64252329c13741f696de6863234c117768";
      deviceHash = "sha256-T+ScPzdI4c0MQYNmulfoswtashoqh3zaJqJXFh/eXDI=";
      bootloaderVersion = "0.0.28";
      bootloaderHash = "sha256-5xQ7vj0BLt2dgZQKC+Ug6BVkcIt7TsebBx1wF1i7gow=";
    };
  };

  artifactory = "https://artifacts.luxonis.com/artifactory";

  # Config packages for dependencies whose nixpkgs builds don't ship the
  # (Hunter-specific) ones depthai-core asks for.
  shims = ../cmake;
in
old:
let
  # "2.31.1-r1" -> "2.31.1"
  upstreamVersion = lib.head (lib.splitString "-" old.version);

  firmware =
    firmwareFor.${upstreamVersion}
      or (throw "nix-ros-depthai: no firmware pinned for depthai-core ${upstreamVersion}; add it to pkgs/depthai.nix");

  deviceFwp = fetchurl {
    url = "${artifactory}/luxonis-myriad-snapshot-local/depthai-device-side/${firmware.deviceCommit}/depthai-device-fwp-${firmware.deviceCommit}.tar.xz";
    hash = firmware.deviceHash;
  };

  bootloaderFwp = fetchurl {
    url = "${artifactory}/luxonis-myriad-release-local/depthai-bootloader/${firmware.bootloaderVersion}/depthai-bootloader-fwp-${firmware.bootloaderVersion}.tar.xz";
    hash = firmware.bootloaderHash;
  };
in
{
  buildInputs = (old.buildInputs or [ ]) ++ [
    bzip2
    zlib
    libarchive
    spdlog
    ghc_filesystem
    backward-cpp
    fp16-luxonis
  ];

  # depthaiConfig.cmake does find_package() on these for every consumer.
  propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [
    xlink-luxonis
    libnop-luxonis
  ];

  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    (lib.cmakeBool "HUNTER_ENABLED" false)
    # CMakeLists.txt asks for CMake 3.4, which CMake 4 no longer accepts.
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    # Only used to upload crash dumps to Luxonis; would also need a patched cpr.
    (lib.cmakeBool "DEPTHAI_ENABLE_CURL" false)
    (lib.cmakeBool "DEPTHAI_CLANG_FORMAT" false)
    (lib.cmakeFeature "BZip2_DIR" "${shims}")
    (lib.cmakeFeature "ZLIB_DIR" "${shims}")
    (lib.cmakeFeature "archive_static_DIR" "${shims}")
    (lib.cmakeFeature "lzma_DIR" "${shims}")
  ];

  postPatch = (old.postPatch or "") + ''
    # fmt >= 11 (which nixpkgs' spdlog uses) requires format() to be const.
    substituteInPlace src/utility/spdlog-fmt.hpp \
      --replace-fail \
        'auto format(const dai::Path& p, FormatContext& ctx) {' \
        'auto format(const dai::Path& p, FormatContext& ctx) const {'
  '';

  preConfigure = (old.preConfigure or "") + ''
    # The downloaders skip any file that is already in the resources folder.
    mkdir -p build/resources
    cp ${deviceFwp} build/resources/depthai-device-fwp-${firmware.deviceCommit}.tar.xz
    cp ${bootloaderFwp} build/resources/depthai-bootloader-fwp-${firmware.bootloaderVersion}.tar.xz

    # The install rules copy everything under HUNTER_INSTALL_PREFIX into
    # $out; give them an empty directory instead of an unset variable.
    mkdir hunter-prefix
    cmakeFlagsArray+=("-DHUNTER_INSTALL_PREFIX=$PWD/hunter-prefix")
  '';
}
