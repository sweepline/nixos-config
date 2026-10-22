{ ... }:
{
  # Kitty switches these automatically when the color scheme changes
  # (theme toggle in waybar), so it is not themed by stylix.
  stylix.targets.kitty.enable = false;
  xdg.configFile = {
    "kitty/dark-theme.auto.conf".source = ./kitty/dark-theme.auto.conf;
    "kitty/light-theme.auto.conf".source = ./kitty/light-theme.auto.conf;
    "kitty/no-preference-theme.auto.conf".source = ./kitty/no-preference-theme.auto.conf;
  };

  programs.kitty = {
    enable = true;
    font = {
      name = "Iosevka";
      size = 14;
    };
    shellIntegration.enableBashIntegration = true;
    settings = {
      window_padding_width = 4;
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
