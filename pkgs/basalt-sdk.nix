{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  opencv,
  tbb,
  basalt-headers-luxonis,
  magic-enum,
  fmt,
  nlohmann_json,
}:

# Luxonis' fork of Basalt, built as the VIO SDK library only (BASALT_SDK_ONLY,
# which CMakeLists.txt forces on), at the revision depthai-core 3.x pins in
# cmake/ports/basalt. depthai-core's BasaltVIO node links it, and
# depthai-ros-driver-v3 uses that node unconditionally.
#
# The SDK build finds every dependency with find_package(), so the git
# submodules (Pangolin, opengv, ROS, ...) that the full build uses are not
# needed.
stdenv.mkDerivation {
  pname = "basalt-sdk-luxonis";
  version = "0-unstable-2025-05-30";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "basalt";
    rev = "ef61684ca32d0f827981270f780830c5f84c8e85";
    hash = "sha256-eWjkwyWbjHFnGZZPrJW9cNLl2ptRW8AsjCKyK0O84cY=";
  };

  nativeBuildInputs = [ cmake ];

  buildInputs = [ opencv ];

  # Eigen 3.4.1 no longer converts the int literal for ArrayBase::max(Scalar)
  # (vcpkg's baseline has 3.4.0).
  postPatch = ''
    substituteInPlace \
      src/linearization/linearization_rel_sc.cpp \
      src/linearization/linearization_abs_sc.cpp \
      src/vi_estimator/marg_helper.cpp \
      --replace-fail '.array().max(0)' '.array().max(Scalar(0))'
  '';

  # basalt_sdkConfig.cmake does find_dependency() on these.
  propagatedBuildInputs = [
    tbb
    basalt-headers-luxonis
    magic-enum
    fmt
    nlohmann_json
  ];

  meta = {
    description = "Basalt visual-inertial odometry SDK library (Luxonis fork)";
    homepage = "https://github.com/luxonis/basalt";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
