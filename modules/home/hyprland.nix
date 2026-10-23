{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.lib.stylix.colors;
  rofi = "rofi";
  lock = "loginctl lock-session";
  exitPrompt = pkgs.writeShellScript "hypr-exit-prompt" ''
    choice=$(printf 'No\nYes, exit Hyprland' | ${rofi} -dmenu -p 'Exit Hyprland?')
    [ "$choice" = "Yes, exit Hyprland" ] && hyprctl dispatch 'hl.dsp.exit()'
  '';
  dndToggle = pkgs.writeShellScript "dnd-toggle" ''
    if makoctl mode | grep -q do-not-disturb; then
      makoctl mode -r do-not-disturb
      notify-send "Do Not Disturb off"
    else
      notify-send "Do Not Disturb on"
      sleep 2
      makoctl mode -a do-not-disturb
    fi
  '';
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    # Use the packages from the NixOS module (programs.hyprland).
    package = null;
    portalPackage = null;
    configType = "lua";
    systemd.variables = [ "--all" ];

    settings.config = {
      general = {
        gaps_in = 10;
        gaps_out = 5;
        border_size = 3;
        layout = "dwindle";
        resize_on_border = true;
        col = {
          active_border = "rgb(${c.base0D})";
          inactive_border = "rgb(${c.base03})";
        };
      };
      decoration = {
        rounding = 2;
        shadow.enabled = true;
        blur.enabled = true;
      };
      animations.enabled = true;
      dwindle.preserve_split = false;
      input = {
        kb_layout = "us";
        kb_options = "compose:ralt";
        follow_mouse = 1;
      };
      misc = {
        disable_hyprland_logo = true;
        force_default_wallpaper = 0;
        focus_on_activate = true;
        # Any key or mouse movement turns screens back on after hypridle turned
        # them off. Without this, waking depends only on hypridle's resume event.
        key_press_enables_dpms = true;
        mouse_move_enables_dpms = true;
      };
      ecosystem.no_update_news = true;
    };

    extraConfig = ''
      local mod = "SUPER"
      local function bind(keys, action, flags) hl.bind(mod .. " + " .. keys, action, flags) end
      local function run(cmd) return hl.dsp.exec_cmd(cmd) end

      -- Basics (same keys as the old sway config)
      bind("RETURN", run("kitty"))
      bind("SHIFT + Q", hl.dsp.window.close())
      bind("D", run("${rofi} -show combi"))
      bind("C", run("${rofi} -show calc -modi calc -no-show-match -no-sort"))
      bind("SHIFT + C", run("hyprctl reload"))
      bind("SHIFT + E", run("${exitPrompt}"))
      bind("SHIFT + W", run("playerctl -a pause; ${lock}"))

      -- Focus and move with hjkl and arrows
      local dirs = { h = "l", j = "d", k = "u", l = "r", left = "l", down = "d", up = "u", right = "r" }
      for key, dir in pairs(dirs) do
        bind(key, hl.dsp.focus({ direction = dir }))
        bind("SHIFT + " .. key, hl.dsp.window.move({ direction = dir, group_aware = true }))
      end

      -- Workspaces 1-10. Workspaces are global: each one lives on a single monitor.
      for i = 1, 10 do
        local key = i % 10
        bind(tostring(key), hl.dsp.focus({ workspace = i }))
        bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
      end

      -- Layout. sway's splith/splitv = preselect where the next window goes.
      bind("B", hl.dsp.layout("preselect r"))
      bind("V", hl.dsp.layout("preselect d"))
      bind("E", hl.dsp.layout("togglesplit"))
      -- sway's tabbed layout = a Hyprland group. Mod+s cycles through the tabs.
      bind("W", hl.dsp.group.toggle())
      bind("S", hl.dsp.group.next())
      bind("F", hl.dsp.window.fullscreen())
      bind("SHIFT + SPACE", hl.dsp.window.float())
      -- sway's "focus mode_toggle": jump between tiled and floating windows.
      bind("SPACE", function()
        local win = hl.get_active_window()
        if win and win.floating then
          hl.dispatch(hl.dsp.window.cycle_next({ tiled = true }))
        else
          hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
        end
      end)

      -- Scratchpad
      bind("SHIFT + MINUS", hl.dsp.window.move({ workspace = "special:scratchpad" }))
      bind("MINUS", hl.dsp.workspace.toggle_special("scratchpad"))

      -- Resize mode
      bind("R", hl.dsp.submap("resize"))
      hl.define_submap("resize", function()
        hl.bind("h", hl.dsp.window.resize({ x = -200, y = 0, relative = true }), { repeating = true })
        hl.bind("l", hl.dsp.window.resize({ x = 200, y = 0, relative = true }), { repeating = true })
        hl.bind("k", hl.dsp.window.resize({ x = 0, y = -200, relative = true }), { repeating = true })
        hl.bind("j", hl.dsp.window.resize({ x = 0, y = 200, relative = true }), { repeating = true })
        hl.bind("RETURN", hl.dsp.submap("reset"))
        hl.bind("ESCAPE", hl.dsp.submap("reset"))
      end)

      -- Mouse: drag with Mod+left, resize with Mod+right
      bind("mouse:272", hl.dsp.window.drag(), { mouse = true })
      bind("mouse:273", hl.dsp.window.resize(), { mouse = true })

      -- Media
      bind("U", run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      bind("I", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
      bind("O", run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
      bind("Y", run("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
      bind("P", run("playerctl -a play-pause"))
      bind("bracketright", run("playerctl -a next"))
      bind("bracketleft", run("playerctl -a previous"))
      hl.bind("XF86AudioRaiseVolume", run("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
      hl.bind("XF86AudioLowerVolume", run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
      hl.bind("XF86AudioMute", run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
      hl.bind("XF86AudioPlay", run("playerctl -a play-pause"), { locked = true })
      hl.bind("XF86AudioNext", run("playerctl -a next"), { locked = true })
      hl.bind("XF86AudioPrev", run("playerctl -a previous"), { locked = true })
      hl.bind("XF86MonBrightnessDown", run("brightnessctl s 10%-"), { locked = true, repeating = true })
      hl.bind("XF86MonBrightnessUp", run("brightnessctl s 10%+"), { locked = true, repeating = true })

      -- Screenshots and recording
      bind("SHIFT + S", run("grimblast --notify copy area"))
      hl.bind("Print", run("grimblast --notify copy area"))
      bind("SHIFT + R", run("screen-record"))

      -- Wallpaper: pick new random ones
      bind("SHIFT + B", run("wallpaper-random"))

      -- Notifications: dismiss, bring back the last one, Do Not Disturb
      bind("N", run("makoctl dismiss"))
      bind("SHIFT + N", run("makoctl restore"))
      bind("CTRL + N", run("${dndToggle}"))

      -- Clipboard history
      bind("SHIFT + V", run("cliphist list | ${rofi} -dmenu -display-columns 2 -p clipboard | cliphist decode | wl-copy"))

      -- Animations. Hyprland's built-in default is 0.8 s per animation (speed 8,
      -- 1 = 0.1 s), which is slow when tiles move around. Everything inherits "global".
      hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
      hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 90%" })
      hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeOutQuint", style = "popin 90%" })

      -- Smart gaps: no gaps or borders when a window is alone
      --hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 0, gaps_in = 0 })
      --hl.workspace_rule({ workspace = "f[1]s[false]", gaps_out = 0, gaps_in = 0 })
      --hl.window_rule({ match = { float = false, workspace = "w[tv1]s[false]" }, border_size = 0 })
      --hl.window_rule({ match = { float = false, workspace = "f[1]s[false]" }, border_size = 0 })

      -- Window rules
      hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })
      hl.window_rule({ match = { class = "^Godot$" }, float = true })
      hl.window_rule({ match = { class = "^Godot$", title = "^Godot Engine" }, float = false, tile = true })
      hl.window_rule({ match = { class = "^Godot_Engine$" }, float = true })
      hl.window_rule({ match = { class = "^mtgo.exe$" }, float = true })
      hl.window_rule({ match = { class = "^firefox$", title = "^Extension: \\(Bitwarden" }, float = true })
      hl.window_rule({ match = { title = "^(Open|Save) (File|Folder|As)" }, float = true, size = "1030 710", center = true })
      hl.window_rule({ match = { class = "^swayimg$" }, float = true, center = true })
      hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" }, float = true })

      -- Host-specific (hosts/<host>/home.nix)
      ${config.my.hyprland.hostConfig}
    '';
  };

  home.packages = with pkgs; [
    grimblast
    playerctl
    brightnessctl
    wl-clipboard
    hyprpicker
    libnotify
  ];

  # Night light: warmer screen from 21:00 to 07:00
  services.hyprsunset = {
    enable = true;
    settings.profile = [
      {
        time = "7:00";
        identity = true;
      }
      {
        time = "21:00";
        temperature = 4000;
      }
    ];
  };

  services.hyprpolkitagent.enable = true;

  # Clipboard history (text and images), picker on Mod+Shift+V
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # stylix writes hyprlang-style keys ("col.active_border"), which the Lua
  # config does not use, so the colors are set above instead.
  stylix.targets.hyprland.enable = false;
}
