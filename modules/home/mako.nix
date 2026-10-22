{ ... }:
{
  # History: dismissed notifications are kept; `makoctl restore` brings back the
  # last one. Do Not Disturb is a mode that hides new notifications (they still
  # go to the history). Keybinds are in hyprland.nix (Mod+n, Mod+Shift+n, Mod+Ctrl+n).
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 10000;
      max-history = 50;
      "mode=do-not-disturb".invisible = 1;
    };
  };
}
