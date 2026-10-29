{
  # Kensington Expert Mouse (the trackball that travels between hosts).
  # Its SIM receiver (047d:1020) reports the top buttons natively as middle (scancode
  # 90003) and back (90004); this restores the layout from the old X setup: top-left =
  # back, top-right = forward (browser buttons). The scancodes come from `evtest`.
  # Remapping happens in the kernel via udev hwdb, so it holds on Wayland, X and tty
  # alike. Middle click is lost as a physical button; Hyprland re-creates it as the
  # left+right chord (middle_button_emulation in the shared hyprland.lua).
  services.udev.extraHwdb = ''
    evdev:input:b0003v047Dp1020*
     KEYBOARD_KEY_90003=btn_side
     KEYBOARD_KEY_90004=btn_extra
  '';
}
