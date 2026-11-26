# Override for nix-ros-overlay's `depthai-v3` (depthai-core 3.x) that makes it
# build inside the Nix sandbox.
#
# depthai-core 3.x bootstraps vcpkg at configure time to build its
# dependencies, fetches a few more with FetchContent, and downloads device
# firmware and helper binaries from Luxonis' artifact server. Here vcpkg is
# switched off, the dependencies come from nixpkgs (or pkgs/ in this repo),
# FetchContent is pointed at prefetched or vendored sources, and the artifacts
# are prefetched.
{
  lib,
  stdenv,
  fetchurl,
  fetchFromGitHub,
  pkg-config,
  bzip2,
  zlib,
  lz4,
  xz,
  libarchive,
  openssl,
  httplib,
  eigen,
  yaml-cpp,
  neargye-semver,
  magic-enum,
  apriltag,
  backward-cpp,
  libcpr,
  protobuf,
  fp16-luxonis,
  libnop-luxonis,
  basalt-sdk-luxonis,
  mp4v2-luxonis,
  websocketpp-luxonis,
}:

let
  # Pinned by each depthai-core release: XLink, xtensor and xtl in
  # cmake/depthaiDependencies.cmake, the rest in cmake/Depthai/*Config.cmake.
  pinsFor = {
    "3.6.1" = {
      xlinkRev = "f001d710be6a4010db913510da08caaa3a58466c";
      xlinkHash = "sha256-5EJtspMCasIMeJGITiU4KRfH9rAYqWlyGm29fNnwGUI=";
      # Luxonis forks. The release tarball also vendors an xtensor/xtl in
      # 3rdparty/, but that is an older 0.24 one the sources no longer build
      # against (they include xtensor/containers/...).
      xtensorRev = "d070cfcba9418ec45e5399708100eee1181a9573";
      xtensorHash = "sha256-QPiDWSHMQuhKpUsnk+KeeHjfSEtWoWIyAUE8Z4oPn1A=";
      xtlRev = "2da8e13ef3d7d9d6ccae3fd68f07892160e8b6c6";
      xtlHash = "sha256-1gO6H1IJyq9wJgHCCpwix9NrzH0VjpyxaWSE7BQutvA=";
      # RVC2 (OAK-D, OAK-D PoE, ...) device firmware.
      deviceCommit = "358472a96039cc24ae416b9612210f04544c1928";
      deviceHash = "sha256-DQ8ivdDn3vCC0RzfG5nQ8LgDH8shiFhK0qAiDwbnDfk=";
      bootloaderVersion = "0.0.28";
      bootloaderHash = "sha256-5xQ7vj0BLt2dgZQKC+Ug6BVkcIt7TsebBx1wF1i7gow=";
      # RVC4 (OAK 4) device firmware.
      rvc4Version = "0.0.1+181be0a49a92b9b23ba3a7853aacf43b7e60549d";
      rvc4Hash = "sha256-QXfAwP+w9hI4LtgbSGzhI/sJQCSbd2JrYKwGc8V6zW4=";
      # Web frontend served by RemoteConnection.
      visualizerVersion = "2.3.3";
      visualizerHash = "sha256-5MH1ElwcKQpxZZRIuPEV2KY1j3ZeYQzq6pybolP7jfw=";
      # Prebuilt, closed-source dynamic calibration library.
      dynamicCalibrationVersion = "003c5040b732498ae4547f0c5464fe431170bef1";
      dynamicCalibrationHash = {
        "linux-x86_64" = "sha256-CzMgPtoJoiQE/8Yu+/vuj8PZmlkSylQpPJxWIQ5Ip6o=";
        "linux-arm64" = "sha256-SzvjRWKylYfjlMkZ+GJXmpTjGPnjSdtCf03CpeCHYsE=";
      };
    };
  };

  artifactory = "https://artifacts.luxonis.com/artifactory";

  # As cmake/PlatformParsing.cmake names them.
  hostArch =
    {
      "x86_64-linux" = "linux-x86_64";
      "aarch64-linux" = "linux-arm64";
    }
    .${stdenv.hostPlatform.system}
      or (throw "nix-ros-depthai: depthai-core 3.x has no dynamic calibration build for ${stdenv.hostPlatform.system}");

  # Config packages for dependencies whose nixpkgs builds don't ship the ones
  # depthai-core asks for.
  shims = ../cmake;

  # nixpkgs builds apriltag's example programs, which pull in a GTK-enabled
  # OpenCV that no binary cache has. depthai only links the detector library.
  apriltagNoExamples = apriltag.overrideAttrs (old: {
    buildInputs = [ ];
    cmakeFlags = [ (lib.cmakeBool "BUILD_EXAMPLES" false) ];
  });
in
old:
let
  # "3.6.1-r2" -> "3.6.1"
  upstreamVersion = lib.head (lib.splitString "-" old.version);

  pins =
    pinsFor.${upstreamVersion}
      or (throw "nix-ros-depthai: nothing pinned for depthai-core ${upstreamVersion}; add it to pkgs/depthai-v3.nix");

  fetchLuxonis =
    repo: rev: hash:
    fetchFromGitHub {
      owner = "luxonis";
      inherit repo rev hash;
    };

  xlinkSrc = fetchLuxonis "XLink" pins.xlinkRev pins.xlinkHash;
  xtensorSrc = fetchLuxonis "xtensor" pins.xtensorRev pins.xtensorHash;
  xtlSrc = fetchLuxonis "xtl" pins.xtlRev pins.xtlHash;

  # Keyed by the file name each downloader looks for in build/resources.
  resources = {
    "depthai-device-fwp-${pins.deviceCommit}.tar.xz" = fetchurl {
      url = "${artifactory}/luxonis-myriad-snapshot-local/depthai-device-side/${pins.deviceCommit}/depthai-device-fwp-${pins.deviceCommit}.tar.xz";
      hash = pins.deviceHash;
    };
    "depthai-bootloader-fwp-${pins.bootloaderVersion}.tar.xz" = fetchurl {
      url = "${artifactory}/luxonis-myriad-release-local/depthai-bootloader/${pins.bootloaderVersion}/depthai-bootloader-fwp-${pins.bootloaderVersion}.tar.xz";
      hash = pins.bootloaderHash;
    };
    "depthai-device-rvc4-fwp-${pins.rvc4Version}.tar.xz" = fetchurl {
      url = "${artifactory}/luxonis-rvc4-snapshot-local/depthai-device-rvc4/${pins.rvc4Version}/depthai-device-rvc4-fwp-${pins.rvc4Version}.tar.xz";
      hash = pins.rvc4Hash;
    };
    "depthai-visualizer-${pins.visualizerVersion}.tar.xz" = fetchurl {
      url = "${artifactory}/luxonis-depthai-visualizer-local/${pins.visualizerVersion}/depthai-visualizer-${pins.visualizerVersion}.tar.xz";
      hash = pins.visualizerHash;
    };
  };

  dynamicCalibration = fetchurl {
    url = "${artifactory}/luxonis-depthai-helper-binaries/dynamic_calibration/${pins.dynamicCalibrationVersion}/dynamic_calibration_${pins.dynamicCalibrationVersion}_${hostArch}.zip";
    hash = pins.dynamicCalibrationHash.${hostArch};
  };
in
{
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
    pkg-config
    # protoc, for the messages library.
    protobuf
  ];

  buildInputs = (old.buildInputs or [ ]) ++ [
    bzip2
    zlib
    lz4
    xz
    libarchive
    openssl
    httplib
    eigen
    yaml-cpp
    neargye-semver
    magic-enum
    apriltagNoExamples
    backward-cpp
    libcpr
    protobuf
    fp16-luxonis
    basalt-sdk-luxonis
    mp4v2-luxonis
    websocketpp-luxonis
  ];

  # depthai_v3Config.cmake does find_dependency() on libnop for every consumer.
  # (XLink and xtensor are built here and installed alongside it.)
  propagatedBuildInputs = (old.propagatedBuildInputs or [ ]) ++ [ libnop-luxonis ];

  cmakeFlags = (old.cmakeFlags or [ ]) ++ [
    (lib.cmakeBool "DEPTHAI_BOOTSTRAP_VCPKG" false)
    (lib.cmakeBool "DEPTHAI_CLANG_FORMAT" false)
    (lib.cmakeBool "DEPTHAI_LIBNOP_EXTERNAL" true)
    # Build the pinned Luxonis xtensor/xtl forks in-tree (installed alongside
    # depthai) rather than use nixpkgs' upstream ones.
    (lib.cmakeBool "DEPTHAI_XTENSOR_EXTERNAL" false)
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_XLINK" "${xlinkSrc}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_XTENSOR" "${xtensorSrc}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_XTL" "${xtlSrc}")
    (lib.cmakeFeature "DEPTHAI_DYNAMIC_CALIBRATION_PATH" "${dynamicCalibration}")
    (lib.cmakeFeature "liblzma_DIR" "${shims}")
    (lib.cmakeFeature "CURL_DIR" "${shims}")
  ];

  postPatch = (old.postPatch or "") + ''
    # vcpkg's lz4 port names its target lz4::lz4; lz4's own CMake config, which
    # nixpkgs installs, calls it LZ4::lz4.
    substituteInPlace CMakeLists.txt --replace-fail 'lz4::lz4' 'LZ4::lz4'

    # vcpkg's protobuf port forces find_package(Protobuf) into CONFIG mode.
    # Without it, CMake's FindProtobuf module hands back a bare libprotobuf.a
    # with none of its abseil link dependencies, leaving libdepthai_v3-core.so
    # with undefined absl:: symbols that only fail once a consumer links it.
    substituteInPlace cmake/depthaiDependencies.cmake \
      --replace-fail 'find_package(Protobuf ''${_QUIET} REQUIRED)' 'find_package(Protobuf ''${_QUIET} CONFIG REQUIRED)'
    substituteInPlace protos/CMakeLists.txt \
      --replace-fail 'find_package(Protobuf REQUIRED)' 'find_package(Protobuf CONFIG REQUIRED)'
  '';

  preConfigure = (old.preConfigure or "") + ''
    # The downloaders skip any file that is already in the resources folder.
    mkdir -p build/resources
  ''
  + lib.concatStrings (
    lib.mapAttrsToList (name: file: ''
      cp ${file} "build/resources/${name}"
    '') resources
  );
}
