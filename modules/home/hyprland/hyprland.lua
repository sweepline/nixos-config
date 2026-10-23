-- Hyprland config (Lua): https://wiki.hypr.land/Configuring/Start/
--
-- Colors are set by stylix before this file runs. The host-specific part (monitors,
-- keyboards, workspace and window rules) is appended after it, from hosts/<host>/hyprland.lua.

local mainMod = "SUPER"

---------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------

hl.config({
    general = {
        gaps_in          = 10,
        gaps_out         = 5,
        border_size      = 3,
        layout           = "scrolling",
        resize_on_border = true,
    },

    decoration = {
        rounding = 2,
        shadow   = { enabled = true },
        blur     = { enabled = true },
    },

    animations = {
        enabled = true,
    },

    input = {
        kb_layout    = "us",
        kb_options   = "compose:ralt",
        follow_mouse = 1,
    },

    misc = {
        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,
        -- Wake the screens on any key or mouse movement after hypridle turned them off.
        key_press_enables_dpms  = true,
        mouse_move_enables_dpms = true,
    },

    ecosystem = {
        no_update_news = true,
    },
})

---------------------------------------------------------------------------
-- Animations
---------------------------------------------------------------------------

-- Hyprland's built-in default is 0.8 s per animation (speed 8, 1 = 0.1 s).
-- Everything inherits from "global".
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })

hl.animation({ leaf = "global",     enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",  enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeOutQuint", style = "popin 90%" })

---------------------------------------------------------------------------
-- Keybinds
---------------------------------------------------------------------------

-- Programs
hl.bind(mainMod .. " + RETURN",      hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + D",           hl.dsp.exec_cmd("rofi -show combi"))
hl.bind(mainMod .. " + C",           hl.dsp.exec_cmd("rofi -show calc -modi calc -no-show-match -no-sort"))
hl.bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("cliphist list | rofi -dmenu -display-columns 2 -p clipboard | cliphist decode | wl-copy"))
hl.bind(mainMod .. " + SHIFT + P",   hl.dsp.exec_cmd("hyprpicker -a"))

-- Session
hl.bind(mainMod .. " + SHIFT + Q",   hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + C",   hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + SHIFT + E",   hl.dsp.exec_cmd("hypr-exit"))
hl.bind(mainMod .. " + SHIFT + W",   hl.dsp.exec_cmd("playerctl -a pause; loginctl lock-session"))

-- Directions for the hjkl and arrow keys
local dirs = { h = "l", j = "d", k = "u", l = "r", left = "l", down = "d", up = "u", right = "r" }

-- Focus: left/right between columns, up/down between the windows of a column
for key, dir in pairs(dirs) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.layout("focus " .. dir))
end

-- Move the window. Left/right: into the neighbouring column, or into a new column at the edge
-- of the strip. Up/down: swap places with the window above/below in its column.
for key, dir in pairs(dirs) do
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- Move the column: swap places with the neighbouring column
for key, dir in pairs({ h = "l", left = "l", l = "r", right = "r" }) do
    hl.bind(mainMod .. " + CTRL + " .. key, hl.dsp.layout("swapcol " .. dir))
end

-- Take the focused window out of its column into a column of its own, right after it.
-- (Mod+Shift+h/l only creates a new column at the edge of the strip.)
hl.bind(mainMod .. " + CTRL + k",  hl.dsp.layout("promote"))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.layout("promote"))

-- The reverse: a window alone in its column joins the previous column (at the bottom).
-- On a window that shares its column this pops it out to the left instead.
hl.bind(mainMod .. " + CTRL + j",    hl.dsp.layout("consume_or_expel prev"))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.layout("consume_or_expel prev"))

-- Column width: cycle through 1/3, 1/2, 2/3 and full width
hl.bind(mainMod .. " + E", hl.dsp.layout("colresize +conf"))

-- Scroll the view one column, or center the focused column
hl.bind(mainMod .. " + comma",  hl.dsp.layout("move -col"))
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + A",      hl.dsp.layout("center"))

-- Windows
hl.bind(mainMod .. " + F",             hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float())

-- Jump between tiled and floating windows
hl.bind(mainMod .. " + SPACE", function()
    local win = hl.get_active_window()
    if win and win.floating then
        hl.dispatch(hl.dsp.window.cycle_next({ tiled = true }))
    else
        hl.dispatch(hl.dsp.window.cycle_next({ floating = true }))
    end
end)

-- Workspaces 1-10. Each workspace lives on a single monitor.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,           hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,   hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Scratchpad (a special workspace)
hl.bind(mainMod .. " + SHIFT + MINUS", hl.dsp.window.move({ workspace = "special:scratchpad" }))
hl.bind(mainMod .. " + MINUS",         hl.dsp.workspace.toggle_special("scratchpad"))

-- Resize mode: h/l change the column width, j/k the window height
hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("h", hl.dsp.layout("colresize -0.1"), { repeating = true })
    hl.bind("l", hl.dsp.layout("colresize +0.1"), { repeating = true })
    hl.bind("k", hl.dsp.window.resize({ x = 0, y = -200, relative = true }), { repeating = true })
    hl.bind("j", hl.dsp.window.resize({ x = 0, y = 200, relative = true }), { repeating = true })
    hl.bind("RETURN", hl.dsp.submap("reset"))
    hl.bind("ESCAPE", hl.dsp.submap("reset"))
end)

-- Mouse: drag with Mod+left button, resize with Mod+right button
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media
hl.bind(mainMod .. " + U",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind(mainMod .. " + I",           hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind(mainMod .. " + O",           hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind(mainMod .. " + Y",           hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bind(mainMod .. " + P",           hl.dsp.exec_cmd("playerctl -a play-pause"))
hl.bind(mainMod .. " + bracketright", hl.dsp.exec_cmd("playerctl -a next"))
hl.bind(mainMod .. " + bracketleft",  hl.dsp.exec_cmd("playerctl -a previous"))

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
hl.bind("XF86AudioPlay",         hl.dsp.exec_cmd("playerctl -a play-pause"),                          { locked = true })
hl.bind("XF86AudioNext",         hl.dsp.exec_cmd("playerctl -a next"),                                { locked = true })
hl.bind("XF86AudioPrev",         hl.dsp.exec_cmd("playerctl -a previous"),                            { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"),                             { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"),                             { locked = true, repeating = true })

-- Screenshots and recording
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grimblast --notify copy area"))
hl.bind("Print",                   hl.dsp.exec_cmd("grimblast --notify copy area"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("screen-record"))

-- Wallpaper: pick new random ones
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("wallpaper-random"))

-- Notifications: dismiss, bring back the last one, Do Not Disturb
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("makoctl dismiss"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl restore"))
hl.bind(mainMod .. " + CTRL + N",  hl.dsp.exec_cmd("dnd-toggle"))

---------------------------------------------------------------------------
-- Window rules
---------------------------------------------------------------------------

-- Ignore apps that ask to be maximized when they open (kitty restores a "maximized" state
-- that Hyprland reported to it, and covers the window next to it). Real fullscreen still works.
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

-- Do not let the screen go idle while something is fullscreen (video, games)
hl.window_rule({ match = { class = ".*" }, idle_inhibit = "fullscreen" })

hl.window_rule({ match = { class = "^Godot$" }, float = true })
hl.window_rule({ match = { class = "^Godot$", title = "^Godot Engine" }, float = false, tile = true })
hl.window_rule({ match = { class = "^Godot_Engine$" }, float = true })
hl.window_rule({ match = { class = "^mtgo.exe$" }, float = true })
hl.window_rule({ match = { class = "^firefox$", title = "^Extension: \\(Bitwarden" }, float = true })
hl.window_rule({ match = { class = "^swayimg$" }, float = true, center = true })
hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" }, float = true })
