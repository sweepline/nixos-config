-- Host-specific Hyprland config for esa, appended after modules/home/hyprland/hyprland.lua.
-- Translated from the old sway config.d/esa.
-- TODO: check output names (DP-1, DP-2) and device names after the first login.

hl.monitor({ output = "desc:Dell Inc. DELL U2717D J0XYN989DC7S", mode = "2560x1440", position = "0x0" })
hl.monitor({ output = "desc:Dell Inc. DELL U2717D ND7GD846719S", mode = "2560x1440", position = "0x0" })
hl.monitor({ output = "desc:Dell Inc. DELL U2717D J0XYN989DC8S", mode = "2560x1440", position = "2560x-280", transform = 3 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    cursor = { hide_on_key_press = true },
})

-- Keyboards with the remaps in hardware
hl.device({ name = "fc900rbt-keyboard", kb_options = "compose:ralt" })
hl.device({ name = "fc900r",            kb_options = "compose:ralt" })

for i = 1, 4 do hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1" }) end
for i = 5, 6 do hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2" }) end

hl.window_rule({ match = { class = "^@joplin/app-desktop$" }, workspace = "6 silent" })
hl.window_rule({ match = { class = "^signal$" },              workspace = "6 silent" })
