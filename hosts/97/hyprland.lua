-- Host-specific Hyprland config for 97, appended after modules/home/hyprland/hyprland.lua.
-- Translated from the old sway config.d/97.

hl.monitor({
    output   = "desc:Lenovo Group Limited LEN G34w-10 UGW05532",
    mode     = "3440x1440@144",
    position = "0x0",
    vrr      = 0,
})
hl.monitor({
    output   = "desc:Invalid Vendor Codename - RTK ZZX-FHD-HDR demoset-1",
    mode     = "1920x1080",
    position = "400x1440",
})
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    cursor    = { hide_on_key_press = false },
    -- Ultrawide: new columns start at 1/3 (same value as in the Mod+E cycle)
    scrolling = { column_width = 0.333 },
})

-- Keyboard with the remaps in hardware
hl.device({ name = "fc750rbt-keyboard", kb_options = "compose:ralt" })
hl.device({ name = "------fc750r",      kb_options = "compose:ralt" })

for i = 1, 4 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "desc:Lenovo Group Limited LEN G34w-10 UGW05532" })
end
for i = 5, 6 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "desc:Invalid Vendor Codename - RTK ZZX-FHD-HDR demoset-1" })
end

-- Per-screen scrolling column width. Window rules cannot match monitors in Hyprland
-- 0.56 (no match property for it), so key off the workspace pins above: 1-4 live on the
-- ultrawide (global column_width), 5-6 on the 1080p, which gets 3/4 columns since
-- 0.333 of 1920 is only ~640px. Widths apply to newly mapped windows; adjust here.
for _, ws in ipairs({ "5", "6" }) do
    hl.window_rule({ name = "colw-1080p-" .. ws, match = { workspace = ws }, scrolling_width = 0.667 })
end

hl.window_rule({ match = { class = "^firefox$" },              workspace = "3 silent" })
hl.window_rule({ match = { class = "^steam$" },                workspace = "2 silent" })
hl.window_rule({ match = { class = "^@joplin/app-desktop$" },  workspace = "5 silent" })
hl.window_rule({ match = { class = "^signal$" },               workspace = "5 silent" })
hl.window_rule({ match = { class = "^vesktop$" },              workspace = "5 silent" })
hl.window_rule({ match = { title = "Battle.net" },             workspace = "4 silent", float = true })
