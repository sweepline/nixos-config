{ ... }:
{
  my.hyprland.hostConfig = builtins.readFile ./hyprland.lua;

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
}
