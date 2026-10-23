{ lib, ... }:
{
  # Translated from the old sway config.d/dongmyo.
  my.hyprland.hostConfig = ''
    -- Docked (another monitor connected): turn the laptop screen off when the lid
    -- closes. Not docked: do nothing here, logind suspends. Opening the lid always
    -- turns the laptop screen back on.
    local laptopScreen = [[hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1200", position = "0x0", scale = 1 })']]
    hl.bind("switch:on:Lid Switch", function()
      for _, mon in ipairs(hl.get_monitors()) do
        if mon.name ~= "eDP-1" then
          hl.dispatch(hl.dsp.exec_cmd([[hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })']]))
          return
        end
      end
    end, { locked = true })
    hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(laptopScreen), { locked = true })

    hl.monitor({ output = "eDP-1", mode = "1920x1200", position = "0x0", scale = 1 })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    hl.config({
      cursor = { hide_on_key_press = true },
      input = { touchpad = { natural_scroll = true, tap_to_click = true, disable_while_typing = true } },
    })

    hl.device({ name = "topre-corporation-hhkb-professional", kb_options = "compose:ralt" })
    hl.device({ name = "at-translated-set-2-keyboard", kb_options = "ctrl:nocaps,altwin:swap_lalt_lwin,compose:ralt"

    -- Move the current workspace to the other monitor
    hl.bind("SUPER + M", hl.dsp.workspace.move({ monitor = "r" }))
  '';

  # Fingerprint unlock on the lock screen (password still works)
  programs.hyprlock.settings.auth."fingerprint:enabled" = true;

  # After waking up: screens on, and the laptop screen re-enabled if the lid is
  # open (in case the lid-open event was missed while asleep).
  services.hypridle.settings.general.after_sleep_cmd = lib.mkForce (
    "hyprctl dispatch 'hl.dsp.dpms({ action = \"enable\" })'; "
    + "grep -q open /proc/acpi/button/lid/*/state && "
    + "hyprctl eval 'hl.monitor({ output = \"eDP-1\", mode = \"1920x1200\", position = \"0x0\", scale = 1 })'"
  );
}
