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
      final.callPackage ./pkgs/depthai-v3.nix { }
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
  basalt-headers-luxonis = final.callPackage ./pkgs/basalt-headers.nix { };
  basalt-sdk-luxonis = final.callPackage ./pkgs/basalt-sdk.nix { };
  mp4v2-luxonis = final.callPackage ./pkgs/mp4v2.nix { };
  websocketpp-luxonis = final.callPackage ./pkgs/websocketpp.nix { };

  rosPackages =
    prev.rosPackages
    // lib.genAttrs (lib.filter (d: prev.rosPackages ? ${d}) (lib.unique (distros ++ v3Distros))) (
      distro: prev.rosPackages.${distro}.overrideScope (lib.composeManyExtensions (overlaysFor distro))
    );
}
