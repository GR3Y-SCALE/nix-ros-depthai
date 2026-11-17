# Stand-in for Hunter's BZip2 config package: wraps CMake's own FindBZip2 and
# provides the BZip2::bz2 target name that depthai-core links against.
find_package(BZip2 MODULE REQUIRED)

if(NOT TARGET BZip2::bz2)
    add_library(BZip2::bz2 INTERFACE IMPORTED)
    set_target_properties(BZip2::bz2 PROPERTIES INTERFACE_LINK_LIBRARIES BZip2::BZip2)
endif()
