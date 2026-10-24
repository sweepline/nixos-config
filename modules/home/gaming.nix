{ lib, osConfig, ... }:
lib.mkIf osConfig.my.gaming.enable {
  # In-game overlay. Enable per game in Steam: launch options `mangohud %command%`.
  # Right Shift+F12 toggles it.
  programs.mangohud = {
    enable = true;
    settings = {
      position = "top-left";
      toggle_hud = "Shift_R+F12";
      fps = true;
      frametime = true;
      frame_timing = true;
      cpu_stats = true;
      cpu_temp = true;
      gpu_stats = true;
      gpu_temp = true;
      vram = true;
      ram = true;
      fps_limit = 0;
    };
  };

  # GPU Screen Recorder overlay (gsr-ui, see modules/nixos/gaming.nix). Its own hotkeys are not
  # set up, so it is controlled from here. The overlay also offers screen, region and window
  # recording, screenshots, streaming and a replay buffer.
  my.hyprland.hostConfig = ''
    hl.bind("SUPER + G",         hl.dsp.exec_cmd("gsr-ui-cli toggle-show"))
    hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd("gsr-ui-cli replay-save"))
  '';
}
