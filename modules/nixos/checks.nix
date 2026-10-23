{
  config,
  lib,
  pkgs,
  ...
}:
let
  hyprlandLua = config.home-manager.users.mikkel.xdg.configFile."hypr/hyprland.lua".source;
in
{
  options.my.checkHyprland = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Check the generated Hyprland config with `Hyprland --verify-config` while building the
      system. A broken config then fails `nh os switch/boot/test` before anything is
      activated. Turn off if the checker itself ever blocks a rebuild.
    '';
  };

  # Catches Lua syntax errors, unknown functions/options at load time and API changes after a
  # Hyprland update. It cannot catch code that only runs when a key is pressed, or device and
  # monitor names that do not match the hardware.
  config.system.checks = lib.mkIf config.my.checkHyprland [
    (pkgs.runCommand "hyprland-config-check"
      {
        nativeBuildInputs = [ config.programs.hyprland.package ];
      }
      ''
        export HOME="$TMPDIR"
        export XDG_RUNTIME_DIR="$(mktemp -d)"
        # The flag only skips Hyprland's "do not run as root" check, which matters when the
        # build runs as root (e.g. without build users). Nothing is started: --verify-config
        # only parses the config.
        Hyprland --i-am-really-stupid --verify-config -c ${hyprlandLua}
        touch "$out"
      ''
    )
  ];
}
