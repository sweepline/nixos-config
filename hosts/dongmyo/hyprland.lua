-- Host-specific Hyprland config for dongmyo, appended after modules/home/hyprland/hyprland.lua.
-- Translated from the old sway config.d/dongmyo.

-- Docked (another monitor connected): turn the laptop screen off when the lid closes.
-- Not docked: do nothing here, logind suspends. Opening the lid always turns the laptop
-- screen back on.
local laptopScreen = [[hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1 })']]

hl.bind("switch:on:Lid Switch", function()
    for _, mon in ipairs(hl.get_monitors()) do
        if mon.name ~= "eDP-1" then
            hl.dispatch(hl.dsp.exec_cmd([[hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })']]))
            return
        end
    end
end, { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(laptopScreen), { locked = true })

-- Every monitor, the laptop panel included: native mode, placed left to right in the order
-- they were connected (the laptop first), no scaling. Scale "auto" would pick 1.5 for this panel.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

hl.config({
    cursor = { hide_on_key_press = true },
    input  = { touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true } },
})

hl.device({ name = "topre-corporation-hhkb-professional", kb_options = "compose:ralt" })
hl.device({ name = "at-translated-set-2-keyboard",        kb_options = "ctrl:nocaps,altwin:swap_lalt_lwin,compose:ralt" })

