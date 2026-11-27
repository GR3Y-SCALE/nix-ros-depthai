# Nixpkgs overlay. Apply it after nix-ros-overlay's own overlay.
final: prev:

let
  inherit (prev) lib;

  # ROS distros that ship depthai-core 2.x as `depthai` (and depthai-ros 2.x).
  distros = [
    "humble"
    "jazzy"
  ];

  # ROS distros whose `depthai-v3` (depthai-core 3.x, used by the `*-v3`
  # depthai-ros packages) has its artifacts pinned in pkgs/depthai-v3.nix.
  v3Distros = [ "jazzy" ];

  # depthai-core 3.6.1's vcpkg versions of the libraries whose newer nixpkgs
  # releases changed APIs it uses: Eigen 3.4.1's min/max(int) overloads,
  # protobuf 30+'s string_view descriptor names, cpp-httplib 0.23+'s renamed
  # upload types, and cpr 1.12+'s string_view DebugCallback. All are private
  # to libdepthai (linked PRIVATE, absent from its public headers and
  # depthai_v3Config.cmake), so consumers keep nixpkgs' versions. Basalt's
  # headers (and Sophus) propagate Eigen, so they get the same one, keeping a
  # single Eigen on the CMake path.
  #
  # protobuf and cpr are linked statically, as vcpkg's x64-linux triplet does,
  # so depthai's own -Wl,--exclude-libs=ALL (DEPTHAI_VCPKG_INTERNAL_ONLY, on by
  # default) hides their symbols. A shared libprotobuf.so.29 clashes with the
  # nixpkgs libprotobuf.so.34 that OpenCV's dnn module brings into the same
  # process (image_transport plugins load it), and segfaults in protobuf's
  # static initialisers when the driver creates its image publishers.
  v3Pins = {
    # semver 1.0 reworked the API that src/device/Version.cpp uses
    # (semver::version from a string). Header-only, and linked PRIVATE.
    neargye-semver = final.neargye-semver.overrideAttrs {
      version = "0.3.1";
      src = final.fetchFromGitHub {
        owner = "Neargye";
        repo = "semver";
        tag = "v0.3.1";
        hash = "sha256-0HOp+xzo8xcCUUgtSh87N9DXP5P0odBaYXhcDzOiiXE=";
      };
    };
    eigen = final.eigen_3_4_0;
    protobuf = (final.protobuf_29.override { enableShared = false; }).overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (lib.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true) ];
    });
    httplib = final.httplib.overrideAttrs (old: {
      version = "0.20.1";
      src = final.fetchFromGitHub {
        owner = "yhirose";
        repo = "cpp-httplib";
        rev = "v0.20.1";
        hash = "sha256-t/ddZjKelnXQdXQvZgv9pQcJt3M2rwgbtTQNW/T6Gpk=";
      };
    });
    # Luxonis' own vcpkg port (cmake/ports/cpr), patches included: one drops
    # cpr's -Werror, the other makes it find the system CA bundle.
    libcpr = (final.libcpr.override { staticOnly = true; }).overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [ (lib.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true) ];
      version = "1.11.0";
      src = final.fetchFromGitHub {
        owner = "libcpr";
        repo = "cpr";
        rev = "1.11.0";
        hash = "sha256-jWyss0krj8MVFqU1LAig+4UbXO5pdcWIT+hCs9DxemM=";
      };
      patches = (old.patches or [ ]) ++ [
        ./pkgs/patches/cpr/disable_werror.patch
        ./pkgs/patches/cpr/multi_cert.patch
      ];
    });
  };

  rosOverlay = rosFinal: rosPrev: {
    depthai = rosPrev.depthai.overrideAttrs (
      final.callPackage ./pkgs/depthai.nix { }
    );
    depthai-examples = rosPrev.depthai-examples.overrideAttrs (
      final.callPackage ./pkgs/depthai-examples.nix { }
    );
  };

  v3RosOverlay = rosFinal: rosPrev: {
    depthai-v3 = rosPrev.depthai-v3.overrideAttrs (
      final.callPackage ./pkgs/depthai-v3.nix v3Pins
    );
  };

  overlaysFor =
    distro:
    lib.optional (lib.elem distro distros) rosOverlay
    ++ lib.optional (lib.elem distro v3Distros) v3RosOverlay;
in
{
  xlink-luxonis = final.callPackage ./pkgs/xlink.nix { };
  libnop-luxonis = final.callPackage ./pkgs/libnop.nix { };
  fp16-luxonis = final.callPackage ./pkgs/fp16.nix { };
  basalt-headers-luxonis = final.callPackage ./pkgs/basalt-headers.nix {
    inherit (v3Pins) eigen;
    sophus = final.sophus.override { inherit (v3Pins) eigen; };
  };
  basalt-sdk-luxonis = final.callPackage ./pkgs/basalt-sdk.nix { };
  mp4v2-luxonis = final.callPackage ./pkgs/mp4v2.nix { };
  websocketpp-luxonis = final.callPackage ./pkgs/websocketpp.nix { };

  rosPackages =
    prev.rosPackages
    // lib.genAttrs (lib.filter (d: prev.rosPackages ? ${d}) (lib.unique (distros ++ v3Distros))) (
      distro: prev.rosPackages.${distro}.overrideScope (lib.composeManyExtensions (overlaysFor distro))
    );
}
