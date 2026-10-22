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

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.xserver.videoDrivers = lib.mkIf (gpu == "nvidia") [ "nvidia" ];

  hardware.nvidia = lib.mkIf (gpu == "nvidia") {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

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
