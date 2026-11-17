{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

let
  psimd-src = fetchFromGitHub {
    owner = "Maratyszcza";
    repo = "psimd";
    rev = "072586a71b55b7f8c584153d223e95687148a900";
    hash = "sha256-lV+VZi2b4SQlRYrhKx9Dxc6HlDEFz3newvcBjTekupo=";
  };
in
# Luxonis' fork of FP16 (header-only). Unlike upstream (and nixpkgs' fp16) it
# installs FP16Config.cmake with the FP16::fp16 target depthai-core links to.
stdenv.mkDerivation {
  pname = "fp16-luxonis";
  version = "0-unstable-2021-06-01";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "FP16";
    rev = "c911175d2717e562976e606c6e5f799bf40cf94e";
    hash = "sha256-4U5WmqqljHYoKdKqtFRBX++vGCv/3weuqPFr4WG7GNM=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeBool "FP16_BUILD_TESTS" false)
    (lib.cmakeBool "FP16_BUILD_BENCHMARKS" false)
    (lib.cmakeFeature "PSIMD_SOURCE_DIR" "${psimd-src}")
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];

  meta = {
    description = "Half-precision float conversion library (Luxonis fork)";
    homepage = "https://github.com/luxonis/FP16";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
