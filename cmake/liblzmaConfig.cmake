# Stand-in for the liblzma config package that xz's CMake build installs.
# nixpkgs builds xz with autotools, which installs only liblzma.pc, but
# depthai-core 3.x does find_package(liblzma CONFIG) and links liblzma::liblzma.
if(NOT TARGET liblzma::liblzma)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(_LIBLZMA REQUIRED IMPORTED_TARGET liblzma)
  add_library(liblzma::liblzma INTERFACE IMPORTED)
  set_target_properties(liblzma::liblzma PROPERTIES INTERFACE_LINK_LIBRARIES PkgConfig::_LIBLZMA)
endif()
set(liblzma_FOUND TRUE)
