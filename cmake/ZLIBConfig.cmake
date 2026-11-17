# Stand-in for Hunter's ZLIB config package: wraps CMake's own FindZLIB and
# provides the ZLIB::zlib target name that depthai-core links against.
find_package(ZLIB MODULE REQUIRED)

if(NOT TARGET ZLIB::zlib)
    add_library(ZLIB::zlib INTERFACE IMPORTED)
    set_target_properties(ZLIB::zlib PROPERTIES INTERFACE_LINK_LIBRARIES ZLIB::ZLIB)
endif()
