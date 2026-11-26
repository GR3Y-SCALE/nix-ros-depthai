{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  eigen,
  sophus,
  cereal,
}:

# Luxonis' fork of basalt-headers (header-only), at the revision depthai-core
# 3.x pins in cmake/ports/basalt-headers. Needed by basalt-sdk-luxonis.
stdenv.mkDerivation {
  pname = "basalt-headers-luxonis";
  version = "0-unstable-2024-11-07";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "basalt-headers";
    rev = "5392967dc6825838a52fa6d6ed38188a55a6acf7";
    hash = "sha256-Adlsx3wXEZJ1DTGTW7fmvboSJzi3eAplMqraxqmlDxI=";
  };

  nativeBuildInputs = [ cmake ];

  # basalt-headersConfig.cmake does find_dependency() on all three.
  propagatedBuildInputs = [
    eigen
    sophus
    cereal
  ];

  cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" false) ];

  meta = {
    description = "Reusable header-only components of Basalt VIO (Luxonis fork)";
    homepage = "https://github.com/luxonis/basalt-headers";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.linux;
  };
}
