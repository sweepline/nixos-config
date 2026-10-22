{ config, lib, ... }:
let
  cfg = config.my;
in
{
  options.my.secureBoot.enable = lib.mkEnableOption ''
    signing Limine with sbctl. Turn this on only after `sbctl create-keys` and
    `sbctl enroll-keys -m` (see docs/INSTALL.md)'';

  config = {
    boot.loader = {
      efi.canTouchEfiVariables = true;
      timeout = 5;
      limine = {
        enable = true;
        maxGenerations = 10;
        secureBoot.enable = cfg.secureBoot.enable;
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
