{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

# Luxonis' fork of MP4v2, at the revision depthai-core 3.x pins in
# cmake/ports/mp4v2, built the way that port builds it (static, no tools).
# nixpkgs' mp4v2 is a different fork and ships no mp4v2-config.cmake.
# Used by depthai-core's video recording.
stdenv.mkDerivation {
  pname = "mp4v2-luxonis";
  version = "2.1.3-unstable-2024-04-22";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "mp4v2";
    rev = "1dc9f4d24645ea43405582e5c813dec3eaa8fd3e";
    hash = "sha256-0WLQMjKllXjrgzWYyuoG7xyvgk9oVszghhhhPPEypm8=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED" false)
    (lib.cmakeBool "BUILD_UTILS" false)
    # Linked into libdepthai-core.so.
    (lib.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true)
    # CMakeLists.txt asks for a CMake version CMake 4 no longer accepts.
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    # mp4v2.pc.in prepends ${prefix}/ to these, so they must stay relative.
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
  ];

  meta = {
    description = "Library for reading and writing MP4 files (Luxonis fork)";
    homepage = "https://github.com/luxonis/mp4v2";
    license = lib.licenses.mpl11;
    platforms = lib.platforms.linux;
  };
}
