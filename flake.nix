{
  description = "Sandbox-buildable depthai (OAK camera) packages for nix-ros-overlay";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/c1b3e6b7f2146af98748735d263f5bf584275461";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-ros-overlay,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            nix-ros-overlay.overlays.default
            self.overlays.default
          ];
        };
    in
    {
      # Expects nix-ros-overlay's overlay to be applied first.
      overlays.default = import ./overlay.nix;

      packages = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = pkgsFor system;
          ros = pkgs.rosPackages.jazzy;
        in
        {
          inherit (pkgs)
            xlink-luxonis
            libnop-luxonis
            fp16-luxonis
            basalt-headers-luxonis
            basalt-sdk-luxonis
            mp4v2-luxonis
            websocketpp-luxonis
            ;
          inherit (ros)
            depthai
            depthai-bridge
            depthai-examples
            depthai-ros-driver
            depthai-ros
            depthai-v3
            depthai-bridge-v3
            depthai-examples-v3
            depthai-filters-v3
            depthai-ros-driver-v3
            depthai-ros-v3
            ;
          default = ros.depthai-ros-driver;
        }
      );
    };
}
