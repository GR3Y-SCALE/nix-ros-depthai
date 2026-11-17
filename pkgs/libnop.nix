{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

# Luxonis' fork of libnop (header-only). nixpkgs has the same revision, but
# installs it with the Makefile and so ships no libnopConfig.cmake, which
# depthaiConfig.cmake requires from every consumer.
stdenv.mkDerivation {
  pname = "libnop-luxonis";
  version = "0-unstable-2022-09-04";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "libnop";
    rev = "ab842f51dc2eb13916dc98417c2186b78320ed10";
    hash = "sha256-d2z/lDI9pe5TR82MxGkR9bBMNXPvzqb9Gsd5jOv6x1A=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    # CMakeLists.txt also writes a build-tree libnopConfig.cmake to a path
    # under CMAKE_INSTALL_LIBDIR. With the absolute path nixpkgs passes, that
    # lands in $out and shadows the installed one; keep it relative.
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
  ];

  meta = {
    description = "Fast, header-only C++ serialization library (Luxonis fork)";
    homepage = "https://github.com/luxonis/libnop";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
}
