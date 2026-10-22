{ ... }:
{
  # Translated from the old sway config.d/dongmyo.
  my.hyprland.hostConfig = ''
    -- Docked: turn the laptop screen off when the lid closes, back on when it opens.
    -- (Without an external monitor, logind suspends instead.)
    hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd([[hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })']]), { locked = true })
    hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd([[hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1200", position = "0x0", scale = 1 })']]), { locked = true })

    hl.monitor({ output = "eDP-1", mode = "1920x1200", position = "0x0", scale = 1 })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    hl.config({
      cursor = { hide_on_key_press = true },
      input = { touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true } },
    })

    hl.device({ name = "topre-corporation-hhkb-professional", kb_options = "compose:ralt" })

    -- Move the current workspace to the other monitor
    hl.bind("SUPER + M", hl.dsp.workspace.move({ monitor = "r" }))
  '';

  # Fingerprint unlock on the lock screen (password still works)
  programs.hyprlock.settings.auth."fingerprint:enabled" = true;
}
