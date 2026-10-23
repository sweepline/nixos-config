{ config, lib, ... }:
let
  cfg = config.my;
in
{
  options.my.secureBoot.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Sign Limine with sbctl. Keys are generated and enrolled automatically when
      the bootloader is installed, if the firmware is in Setup Mode (see docs/INSTALL.md).
    '';
  };

  config = {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      limine = {
        enable = true;
        maxGenerations = 10;
        secureBoot = {
          enable = cfg.secureBoot.enable;
          autoGenerateKeys = true;
          # Enrolls our keys plus Microsoft's (Windows, GPU firmware) and the
          # manufacturer's built-in keys. Only works while in Setup Mode.
          autoEnrollKeys.enable = true;
        };
        extraEntries = lib.mkIf cfg.windowsDualBoot.enable ''
          /Windows
            protocol: efi
            path: guid(${cfg.windowsDualBoot.efiPartUuid}):/EFI/Microsoft/Boot/bootmgfw.efi
        '';
      };
    };

    # systemd in the initrd is needed for TPM2 (+PIN) unlocking of LUKS.
    boot.initrd.systemd.enable = true;
    security.tpm2.enable = true;
  };
}
