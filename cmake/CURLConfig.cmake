# Stand-in for the CURLConfig.cmake that curl's CMake build installs.
# nixpkgs builds curl with autotools, which installs only libcurl.pc, but
# depthai-core 3.x does find_package(CURL CONFIG). CMake's FindCURL module
# provides the same CURL::libcurl target; CURL_NO_CURL_CMAKE stops it from
# looking for a config package and finding this file again.
if(NOT TARGET CURL::libcurl)
  set(_nix_ros_depthai_curl_no_cmake "${CURL_NO_CURL_CMAKE}")
  set(CURL_NO_CURL_CMAKE ON)
  include("${CMAKE_ROOT}/Modules/FindCURL.cmake")
  set(CURL_NO_CURL_CMAKE "${_nix_ros_depthai_curl_no_cmake}")
  unset(_nix_ros_depthai_curl_no_cmake)
endif()
set(CURL_FOUND TRUE)
