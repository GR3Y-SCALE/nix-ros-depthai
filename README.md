# nix-ros-depthai

Makes the Luxonis depthai (OAK camera) ROS 2 packages from
[nix-ros-overlay](https://github.com/lopsided98/nix-ros-overlay) build inside
the Nix sandbox.

Upstream they fail ([nix-ros-overlay#412](https://github.com/lopsided98/nix-ros-overlay/issues/412))
because depthai-core downloads its dependencies (with Hunter in 2.x, vcpkg and
FetchContent in 3.x), and its firmware, at configure time. This overlay fixes:

- `depthai` (depthai-core 2.31.1): Hunter is disabled, dependencies come from
  nixpkgs or `pkgs/`, and the device and bootloader firmware are prefetched.
- `depthai-examples`: the three neural network blobs it downloads are
  prefetched. `depthai-ros-driver` loads them at runtime.
- `depthai-v3` (depthai-core 3.6.1): vcpkg is disabled, dependencies come
  from nixpkgs or `pkgs/` (Luxonis' forks of basalt, basalt-headers, mp4v2
  and websocketpp), FetchContent uses prefetched XLink, xtensor and xtl (not
  the outdated xtensor/xtl copy vendored in the release tarball's `3rdparty/`),
  and the RVC2 and RVC4 (OAK 4) device
  firmware, bootloader, visualizer frontend and dynamic calibration library
  are prefetched. All the default features stay on, including Basalt VIO,
  which `depthai-ros-driver-v3` needs.

Everything else (`depthai-bridge`, `depthai-ros-driver`, `depthai-ros`, and
their `*-v3` counterparts) then builds unmodified.

Covers the depthai v2 packages in `humble` and `jazzy`, and the v3 packages
(`depthai-v3`, `depthai-ros-v3`, ...) in `jazzy`. OAK 4 cameras need the v3
packages. `humble`'s `depthai-v3` and `kilted`'s `depthai` (both 3.7.1) are not
touched yet; see Updating.

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

For the v3 packages, use `depthai-ros-driver-v3` (or `depthai-ros-v3` for all
of them) in place of `depthai-ros-driver`.

The flake also exposes the jazzy packages directly, e.g.
`nix build .#depthai-ros-driver` or `nix build .#depthai-ros-driver-v3`.

## Notes

- depthai-bridge needs several GB of RAM per compile job. If the build dies
  with `Killed signal terminated program cc1plus`, limit parallelism:
  `nix build --cores 3 -j1`.
- The camera needs a udev rule for USB vendor `03e7` to be usable without
  root; Nix does not install one.
- In 2.x, `DEPTHAI_ENABLE_CURL` is off, so the library cannot upload crash
  dumps to Luxonis. 3.x keeps it on (with nixpkgs' libcpr).
- libarchive, spdlog/fmt, bzip2, zlib and libusb come from nixpkgs rather than
  the old versions Hunter pins. In 3.x most dependencies come from nixpkgs too,
  so they are newer than vcpkg's baseline (e.g. fmt 12, OpenCV 4.13).
- Except for four, which `v3Pins` in `overlay.nix` holds at depthai 3.6.1's
  vcpkg versions because their newer releases changed APIs it uses: Eigen
  3.4.0 (3.4.1's `min`/`max` overloads reject `array.min(1)`), protobuf 29
  (30+ returns `string_view` from descriptor names), cpp-httplib 0.20.1
  (0.23+ renamed the client upload types) and cpr 1.11.0 with Luxonis' two
  port patches, copied to `pkgs/patches/cpr/` (1.12+ passes `string_view` to
  `DebugCallback`). They are private to libdepthai, so depthai-ros and other
  consumers still build against nixpkgs' versions. protobuf and cpr are
  linked statically, as vcpkg does, so depthai's `--exclude-libs=ALL` hides
  their symbols: a shared protobuf 29 collides with the protobuf 34 that
  OpenCV's dnn module loads into the driver process (via image_transport
  plugins) and segfaults in protobuf's static initialisers.
  basalt-headers and its Sophus use the pinned Eigen too, so depthai sees only
  one. Recheck these against `vcpkg-configuration.json`'s baseline when
  bumping depthai-core.
- 3.x links Luxonis' prebuilt, closed-source `libdynamic_calibration.so`,
  which is installed next to `libdepthai_v3-core.so`.
- `cmake/` holds stand-in config packages (`liblzmaConfig.cmake`,
  `CURLConfig.cmake`, ...) for nixpkgs builds that only ship pkg-config files.

## Updating

When nix-ros-overlay bumps depthai-core, add the new version's firmware to
`firmwareFor` in `pkgs/depthai.nix` (values are in
`cmake/Depthai/Depthai{DeviceSide,Bootloader}Config.cmake` in the source), and
check the XLink, libnop and FP16 revisions in `pkgs/` against
`cmake/Hunter/config.cmake`.

When it bumps depthai-core 3.x (`depthai-v3`), add the new version to
`pinsFor` in `pkgs/depthai-v3.nix`: the XLink, xtensor and xtl revisions are
in `cmake/depthaiDependencies.cmake`, and the firmware, visualizer and dynamic
calibration versions are in `cmake/Depthai/*Config.cmake`. Check the basalt,
basalt-headers, mp4v2 and websocketpp revisions in `pkgs/` against
`cmake/ports/*/portfile.cmake`. The same table is what supporting `humble`'s
`depthai-v3` or `kilted`'s `depthai` (3.7.1) needs, plus adding the distro to
`v3Distros` in `overlay.nix` (kilted names the package `depthai`).
