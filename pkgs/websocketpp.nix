{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  boost,
}:

# Luxonis' fork of websocketpp (header-only), at the revision depthai-core
# 3.x pins in cmake/ports/websocketpp. The vendored foxglove-websocket server
# behind depthai's remote connection (RemoteConnection, the visualizer) builds
# on it.
stdenv.mkDerivation {
  pname = "websocketpp-luxonis";
  version = "0.8.2-unstable-2025-11-11";

  src = fetchFromGitHub {
    owner = "luxonis";
    repo = "websocketpp";
    rev = "cebc62c393f07e664121f9b801ee7e8a1b273cee";
    hash = "sha256-cIg8Y8vxj6LwOOSMgNg6OxH1dA3DOo8VNdf5eS8i+3I=";
  };

  nativeBuildInputs = [ cmake ];

  # Without ASIO_STANDALONE its headers use Boost.Asio, as vcpkg's port does
  # (boost-asio), so everything that includes them needs Boost.
  propagatedBuildInputs = [ boost ];

  cmakeFlags = [ (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5") ];

  meta = {
    description = "Header-only C++ WebSocket client/server library (Luxonis fork)";
    homepage = "https://github.com/luxonis/websocketpp";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
}
