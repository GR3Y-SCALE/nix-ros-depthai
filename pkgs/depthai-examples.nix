# Override for nix-ros-overlay's `depthai-examples` (depthai-ros 2.x).
#
# Its CMakeLists.txt downloads three neural network blobs at configure time.
# depthai-ros-driver loads them from this package's share directory at
# runtime, so they are prefetched rather than dropped.
{ fetchurl }:

let
  # Keyed by the file name CMakeLists.txt saves each download as.
  blobs = {
    "mobilenet-ssd_openvino_2021.2_6shave.blob" = fetchurl {
      url = "https://artifacts.luxonis.com/artifactory/luxonis-depthai-data-local/network/mobilenet-ssd_openvino_2021.2_6shave.blob";
      hash = "sha256-UVDQ5dGKvQ7LIcgoDgmHCXc1jASn0s+lOeHg9sKpPnE=";
    };
    "yolov4_tiny_coco_416x416_openvino_2021.4_6shave_bgr.blob" = fetchurl {
      url = "https://artifacts.luxonis.com/artifactory/luxonis-depthai-data-local/network/tiny-yolo-v4_openvino_2021.2_6shave.blob";
      hash = "sha256-mExQ4illK+nCUJLfSHGF6uKegOSteWT/NjL0d9v16FE=";
    };
    "deeplab_v3_plus_mnv2_decoder_256_openvino_2021.4.blob" = fetchurl {
      # Upstream fetches this from the master branch of depthai-experiments
      # (since renamed oak-examples); pinned to the commit that added it.
      url = "https://raw.githubusercontent.com/luxonis/oak-examples/49635efa1d23ec0d30d9f6ab7093a472e99e4bb2/gen2-deeplabv3_multiclass/models/deeplab_v3_plus_mnv2_decoder_256_openvino_2021.4.blob";
      hash = "sha256-KAY6eTwqXCEajqyoRF0ItBlzb0rQ5V1lEYVJU9f3Jio=";
    };
  };
in
old: {
  # file(DOWNLOAD ... EXPECTED_HASH) is skipped when the file already exists
  # with the right hash.
  postPatch =
    (old.postPatch or "")
    + ''
      mkdir -p resources
    ''
    + builtins.concatStringsSep "" (
      builtins.attrValues (
        builtins.mapAttrs (name: blob: ''
          cp ${blob} resources/${name}
        '') blobs
      )
    );
}
