{
  config,
  lib,
  pkgs,
  ...
}:
let
  gpu = config.my.gpu;
in
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages =
      lib.optionals (gpu == "intel") [
        pkgs.intel-media-driver
        pkgs.vpl-gpu-rt
      ]
      ++ lib.optionals (gpu == "nvidia") [ pkgs.nvidia-vaapi-driver ];
  };

  services.xserver.videoDrivers = lib.mkIf (gpu == "nvidia") [ "nvidia" ];

  hardware.nvidia = lib.mkIf (gpu == "nvidia") {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Early KMS: without it the console only switches from simpledrm to full resolution right
  # before ly starts, and ly ends up drawn at the old size in the top-left corner.
  boot.initrd.kernelModules = lib.mkIf (gpu == "nvidia") [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  environment.sessionVariables = lib.mkMerge [
    (lib.mkIf (gpu == "nvidia") {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
    })
    (lib.mkIf (gpu == "amd") { LIBVA_DRIVER_NAME = "radeonsi"; })
    (lib.mkIf (gpu == "intel") { LIBVA_DRIVER_NAME = "iHD"; })
  ];
}
