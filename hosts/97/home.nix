{ ... }:
{
  # Translated from the old sway config.d/97.
  # TODO: check monitor descriptions with `hyprctl monitors all` and device
  # names with `hyprctl devices` after the first login.
  my.hyprland.hostConfig = ''
    hl.monitor({
      output = "desc:Lenovo Group Limited LEN G34w-10 UGW05532",
      mode = "3440x1440@144",
      position = "0x0",
      vrr = 0,
    })
    hl.monitor({
      output = "desc:Invalid Vendor Codename - RTK ZZX-FHD-HDR demoset-1",
      mode = "1920x1080",
      position = "400x1440",
    })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

    hl.config({ cursor = { hide_on_key_press = false } })

    hl.device({ name = "ducky-ducky-one-3-mini-rgb", kb_options = "ctrl:nocaps,compose:ralt,altwin:swap_alt_win" })
    hl.device({ name = "fc750rbt-keyboard", kb_options = "compose:ralt" })
    hl.device({ name = "topre-corporation-hhkb-professional", kb_options = "compose:ralt" })

    -- Move the current workspace to the other monitor
    hl.bind("SUPER + M", hl.dsp.workspace.move({ monitor = "u" }))

    for i = 1, 4 do
      hl.workspace_rule({ workspace = tostring(i), monitor = "desc:Lenovo Group Limited LEN G34w-10 UGW05532" })
    end
    for i = 5, 6 do
      hl.workspace_rule({ workspace = tostring(i), monitor = "desc:Invalid Vendor Codename - RTK ZZX-FHD-HDR demoset-1" })
    end

    hl.window_rule({ match = { class = "^firefox$" }, workspace = "3 silent" })
    hl.window_rule({ match = { class = "^steam$" }, workspace = "2 silent" })
    hl.window_rule({ match = { class = "^@joplin/app-desktop$" }, workspace = "5 silent" })
    hl.window_rule({ match = { class = "^signal$" }, workspace = "5 silent" })
    hl.window_rule({ match = { class = "^discord$" }, workspace = "5 silent" })
    hl.window_rule({ match = { title = "Battle.net" }, workspace = "4 silent", float = true })
  '';
}
