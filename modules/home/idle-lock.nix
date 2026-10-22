{ ... }:
let
  dpms = action: "hyprctl dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";
in
{
  # Same timings as the old swayidle setup: lock after 10 min, screens off
  # 30 s later, and screens off after 30 s idle while already locked.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "playerctl -a pause; loginctl lock-session";
        after_sleep_cmd = dpms "enable";
      };
      listener = [
        {
          timeout = 30;
          on-timeout = "pidof hyprlock && ${dpms "disable"}";
          on-resume = dpms "enable";
        }
        {
          timeout = 600;
          on-timeout = "playerctl -a pause; loginctl lock-session";
        }
        {
          timeout = 630;
          on-timeout = dpms "disable";
          on-resume = dpms "enable";
        }
      ];
    };
  };

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };
      # input-field and background come from stylix
      label = [
        {
          text = "$TIME";
          font_size = 64;
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
