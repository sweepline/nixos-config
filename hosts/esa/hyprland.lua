-- Host-specific Hyprland config for esa, appended after modules/home/hyprland/hyprland.lua.
-- Translated from the old sway config.d/esa.
-- Monitor output names verified with `hyprctl monitors` (MST: DP-7/DP-8); identify by desc.

hl.monitor({ output = "desc:Dell Inc. DELL U2717D J0XYN989DC7S", mode = "2560x1440", position = "0x0" })
hl.monitor({ output = "desc:Dell Inc. DELL U2717D J0XYN989DC8S", mode = "2560x1440", position = "2560x-280", transform = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    cursor = { hide_on_key_press = true },
})

-- Keyboards with the remaps in hardware
hl.device({ name = "------fc900rbt-keyboard", kb_options = "compose:ralt" })
hl.device({ name = "------fc900r",            kb_options = "compose:ralt" })

-- Connector names on this DP daisy-chain (MST) shift between boots (currently DP-7/DP-8),
-- so pins must identify monitors by description, like hl.monitor above does.
-- Vertical screen right: ...DC8S; horizontal screen left: ...DC7S.
local vertical = "desc:Dell Inc. DELL U2717D J0XYN989DC8S"
local horizontal = "desc:Dell Inc. DELL U2717D J0XYN989DC7S"
for _, ws in ipairs({ "1", "2" }) do hl.workspace_rule({ workspace = ws, monitor = vertical }) end
for i = 3, 6 do hl.workspace_rule({ workspace = tostring(i), monitor = horizontal }) end

-- Per-screen scrolling column width, keyed off the workspace pins above (window rules
-- cannot match monitors in Hyprland 0.56): ws 1-2 live on the vertical right monitor and
-- get full-width columns; ws 3-6 on the left one follow the global column_width.
for _, ws in ipairs({ "1", "2" }) do
    hl.window_rule({ name = "colw-vertical-" .. ws, match = { workspace = ws }, scrolling_width = 1.0 })
end

hl.window_rule({ match = { class = "^@joplin/app-desktop$" }, workspace = "6 silent" })
hl.window_rule({ match = { class = "^signal$" },              workspace = "6 silent" })
