# nix-ros-depthai

Makes the Luxonis depthai (OAK camera) ROS 2 packages from
[nix-ros-overlay](https://github.com/lopsided98/nix-ros-overlay) build inside
the Nix sandbox.

Upstream they fail ([nix-ros-overlay#412](https://github.com/lopsided98/nix-ros-overlay/issues/412))
because depthai-core downloads its dependencies with the Hunter package
manager, and its firmware, at configure time. This overlay fixes:

- `depthai` (depthai-core 2.31.1): Hunter is disabled, dependencies come from
  nixpkgs or `pkgs/`, and the device and bootloader firmware are prefetched.
- `depthai-examples`: the three neural network blobs it downloads are
  prefetched. `depthai-ros-driver` loads them at runtime.

Everything else (`depthai-bridge`, `depthai-ros-driver`, `depthai-ros`, ...)
then builds unmodified.

Covers the depthai v2 packages in `humble` and `jazzy`. The `*-v3` packages
and `kilted` (depthai-core 3.x) are not touched.

## Use

Apply `overlays.default` after nix-ros-overlay's overlay.

### devenv

`devenv.yaml`:

```yaml
inputs:
  nixpkgs:
    follows: nix-ros-overlay/nixpkgs
  nix-ros-overlay:
    url: github:lopsided98/nix-ros-overlay/2004728f9f450421c9d44b62d6c707a5834139bb
  nix-ros-depthai:
    url: github:GR3Y-SCALE/nix-ros-depthai
    inputs:
      nixpkgs:
        follows: nixpkgs
      nix-ros-overlay:
        follows: nix-ros-overlay
```

`devenv.nix`:

```nix
{ pkgs, inputs, ... }:
{
  overlays = [
    inputs.nix-ros-overlay.overlays.default
    inputs.nix-ros-depthai.overlays.default
  ];

  packages = [
    (pkgs.rosPackages.jazzy.buildEnv {
      paths = with pkgs.rosPackages.jazzy; [
        ros-core
        depthai-ros-driver
      ];
    })
  ];
}
```

### Flake

```nix
pkgs = import nixpkgs {
  inherit system;
  overlays = [
    nix-ros-overlay.overlays.default
    nix-ros-depthai.overlays.default
  ];
};
```

The flake also exposes the jazzy packages directly, e.g.
`nix build .#depthai-ros-driver`.

## Notes

- depthai-bridge needs several GB of RAM per compile job. If the build dies
  with `Killed signal terminated program cc1plus`, limit parallelism:
  `nix build --cores 3 -j1`.
- The camera needs a udev rule for USB vendor `03e7` to be usable without
  root; Nix does not install one.
- `DEPTHAI_ENABLE_CURL` is off, so the library cannot upload crash dumps to
  Luxonis.
- libarchive, spdlog/fmt, bzip2, zlib and libusb come from nixpkgs rather than
  the old versions Hunter pins.

## Updating

When nix-ros-overlay bumps depthai-core, add the new version's firmware to
`firmwareFor` in `pkgs/depthai.nix` (values are in
`cmake/Depthai/Depthai{DeviceSide,Bootloader}Config.cmake` in the source), and
check the XLink, libnop and FP16 revisions in `pkgs/` against
`cmake/Hunter/config.cmake`.
