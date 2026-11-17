# Nixpkgs overlay. Apply it after nix-ros-overlay's own overlay.
final: prev:

let
  # ROS distros that ship depthai-core 2.x as `depthai` (and depthai-ros 2.x).
  distros = [
    "humble"
    "jazzy"
  ];

  rosOverlay = rosFinal: rosPrev: {
    depthai = rosPrev.depthai.overrideAttrs (
      final.callPackage ./pkgs/depthai.nix { }
    );
    depthai-examples = rosPrev.depthai-examples.overrideAttrs (
      final.callPackage ./pkgs/depthai-examples.nix { }
    );
  };
in
{
  xlink-luxonis = final.callPackage ./pkgs/xlink.nix { };
  libnop-luxonis = final.callPackage ./pkgs/libnop.nix { };
  fp16-luxonis = final.callPackage ./pkgs/fp16.nix { };

  rosPackages =
    prev.rosPackages
    // prev.lib.genAttrs (prev.lib.filter (d: prev.rosPackages ? ${d}) distros) (
      distro: prev.rosPackages.${distro}.overrideScope rosOverlay
    );
}
