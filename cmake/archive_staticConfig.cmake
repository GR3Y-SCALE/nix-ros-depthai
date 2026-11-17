# Stand-in for the config package of Luxonis' hunterized libarchive fork:
# uses the system libarchive and provides the archive_static target name that
# depthai-core links against.
find_package(LibArchive MODULE REQUIRED)

if(NOT TARGET archive_static)
    add_library(archive_static INTERFACE IMPORTED)
    set_target_properties(archive_static PROPERTIES INTERFACE_LINK_LIBRARIES LibArchive::LibArchive)
endif()
