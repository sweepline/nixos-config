-- Host-specific Hyprland config for dongmyo, appended after modules/home/hyprland/hyprland.lua.
-- Translated from the old sway config.d/dongmyo. Lid handling: modules/home/laptop.nix.

-- Every monitor, the laptop panel included: native mode, placed left to right in the order
-- they were connected (the laptop first), no scaling. Scale "auto" would pick 1.5 for this panel.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    cursor = { hide_on_key_press = true },
    input  = { touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true } },
})

