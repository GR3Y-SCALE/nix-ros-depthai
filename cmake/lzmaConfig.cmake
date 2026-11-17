# Stand-in for Hunter's lzma config package. depthai-core only needs lzma as a
# transitive dependency of its static libarchive; the system libarchive is
# shared and already links liblzma itself, so there is nothing to provide.
