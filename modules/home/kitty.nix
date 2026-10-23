{ ... }:
{
  # Colors and font come from stylix. theme-toggle tells running kitty
  # windows to reload (SIGUSR1) so they follow the light/dark switch.
  programs.kitty = {
    enable = true;
    shellIntegration.enableBashIntegration = true;
    settings = {
      window_padding_width = 4;
      # Hyprland tells every window it is maximized, kitty saves that state when a window
      # closes and restores it at the next start, so new windows opened maximized and covered
      # the others. Kitty's author recommends turning this off. Tiled windows get their size
      # from the layout anyway.
      remember_window_size = "no";
      cursor_shape = "block";
      cursor_blink_interval = 1;
      scrollback_lines = 3000;
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
      copy_on_select = "yes";
      strip_trailing_spaces = "smart";
      tab_bar_edge = "top";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_align = "left";
      tab_bar_min_tabs = 2;
      tab_bar_margin_width = "0.0";
      tab_bar_margin_height = "2.5 1.5";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";
      tab_activity_symbol = "\" ● \"";
      tab_title_template = "\"{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title[:30]}{title[30:] and '…'} [{index}]\"";
      active_tab_title_template = "\"{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title[:30]}{title[30:] and '…'} [{index}]\"";
    };
    keybindings = {
      "ctrl+shift+n" = "new_window";
      "ctrl+t" = "new_tab";
      "ctrl+plus" = "change_font_size all +1.0";
      "ctrl+minus" = "change_font_size all -1.0";
      "ctrl+0" = "change_font_size all 0";
      "--allow-fallback=shifted,ascii ctrl+shift+t" = "new_tab_with_cwd";
    };
  };
}
