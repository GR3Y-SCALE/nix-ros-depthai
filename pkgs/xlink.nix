{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  libusb1,
}:

# Luxonis' fork of XLink, at the revision depthai-core 2.31.1 pins in
# cmake/Hunter/config.cmake. Built as a static PIC archive, like Hunter does,
# so it ends up inside libdepthai-core.so.
stdenv.mkDerivation {
  pname = "xlink-luxonis";
  version = "0-unstable-2025-05-07";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "XLink";
    rev = "b0be8f9d9d24eac43fbe4ac9313f9afe425c6dba";
    hash = "sha256-NMulJ+lrxmV853G837LomXticIZRJMVcah9YgMqD0cU=";
  };

  nativeBuildInputs = [ cmake ];

  # XLinkTargets.cmake links libusb by absolute path, so consumers need it too.
  propagatedBuildInputs = [ libusb1 ];

  cmakeFlags = [
    (lib.cmakeBool "HUNTER_ENABLED" false)
    (lib.cmakeBool "XLINK_ENABLE_LIBUSB" true)
    (lib.cmakeBool "XLINK_LIBUSB_SYSTEM" true)
    (lib.cmakeBool "BUILD_SHARED_LIBS" false)
    (lib.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true)
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];

  meta = {
    description = "Luxonis fork of the XLink device communication library";
    homepage = "https://github.com/luxonis/XLink";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
