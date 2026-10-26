{
  config,
  osConfig,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  default = osConfig.my.theme;
  other = if default == "dark" then "light" else "dark";
  cursorName =
    theme: "phinger-cursors-gruvbox-material" + lib.optionalString (theme == "light") "-light";

  # Both palettes, rendered from the stylix templates. GTK4 and kitty get both
  # and pick one from the color-scheme setting themselves, so running windows
  # switch live (the specialisation switch alone only helps newly started apps).
  schemeFiles = import ../color-schemes.nix pkgs;
  schemes = lib.mapAttrs (_: config.stylix.base16.mkSchemeAttrs) schemeFiles;
  gtkCss = lib.mapAttrs (
    _: scheme:
    scheme {
      template = builtins.readFile "${inputs.stylix}/modules/gtk/gtk.css.mustache";
      extension = ".css";
    }
  ) schemes;
  kittyTheme = lib.mapAttrs (
    _: scheme:
    scheme {
      templateRepo = inputs.stylix.inputs.tinted-kitty;
      target = "base16";
    }
  ) schemes;
  gtk4Css = pkgs.runCommandLocal "gtk.css" { } ''
    {
      echo '@media (prefers-color-scheme: dark) {'
      cat ${gtkCss.dark}
      echo '}'
      echo '@media (prefers-color-scheme: light) {'
      cat ${gtkCss.light}
      echo '}'
    } > $out
  '';

  # The default theme (my.theme) is the normal Home Manager generation; the other one is a
  # specialisation of it, named after its theme.
  # The theme button in ashell activates the other one (no rebuild, both are prebuilt).
  themeToggle = pkgs.writeShellApplication {
    name = "theme-toggle";
    runtimeInputs = with pkgs; [
      glib
      coreutils
      procps
      hyprland
      systemd
    ];
    text = ''
      # gsettings needs the schema files; a systemd user service does not have them in XDG_DATA_DIRS.
      export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:''${XDG_DATA_DIRS:-}"
      schema=org.gnome.desktop.interface
      key=color-scheme
      state="''${XDG_STATE_HOME:-$HOME/.local/state}"
      current="$state/home-manager/gcroots/current-home"
      basefile="$state/theme-base-generation"

      # Running apps only re-read the cursor theme when told to, so push it live
      # (the activated generation has already written the new name to dconf).
      apply_cursor() {
        name="$(gsettings get "$schema" cursor-theme | tr -d "'")"
        size="$(gsettings get "$schema" cursor-size)"
        hyprctl setcursor "$name" "$size" >/dev/null || true
      }

      # Output for the ashell custom module ("alt" selects the icon).
      show() {
        case "$(gsettings get "$schema" "$key")" in
          *dark*) echo '{"text":"","alt":"dark"}' ;;
          *)      echo '{"text":"","alt":"light"}' ;;
        esac
      }

      if [[ "''${1:-}" == watch ]]; then
        show
        gsettings monitor "$schema" "$key" | while read -r _; do show; done
        exit 0
      fi

      gen="$(readlink -f "$current")"
      if [[ -d "$gen/specialisation/${other}" ]]; then
        # On the base generation: remember it, switch to the other theme.
        echo "$gen" > "$basefile"
        "$gen/specialisation/${other}/activate"
        gsettings set "$schema" "$key" prefer-${other}
        apply_cursor
      else
        base="$(cat "$basefile" 2>/dev/null || true)"
        if [[ -z "$base" || ! -x "$base/activate" ]]; then
          echo "Do not know the ${default} generation; run a rebuild first." >&2
          exit 1
        fi
        "$base/activate"
        gsettings set "$schema" "$key" prefer-${default}
        apply_cursor
      fi

      # Last step: this script runs in ashell's cgroup (started from its theme module),
      # so the restart kills it.
      systemctl --user restart --no-block ashell.service
    '';
  };
in
{
  home.packages = [ themeToggle ];

  # ashell is restarted by theme-toggle: it watches its config file, but the
  # switch only re-points a symlink into the store, which did not trigger a reload.

  # Same files in both generations, so they never change on a toggle.
  # GTK3 has no media queries and keeps stylix's single-palette gtk.css.
  xdg.configFile = {
    "gtk-4.0/gtk.css".source = lib.mkForce gtk4Css;
    "kitty/dark-theme.auto.conf".source = kittyTheme.dark;
    "kitty/light-theme.auto.conf".source = kittyTheme.light;
    "kitty/no-preference-theme.auto.conf".source = kittyTheme.${default};
  };
  stylix.targets.kitty.colors.enable = false;

  specialisation.${other}.configuration = {
    stylix.polarity = lib.mkForce other;
    stylix.base16Scheme = lib.mkForce schemeFiles.${other};
    # Setting only the name would leave package and size null in this config.
    stylix.cursor = lib.mkForce {
      inherit (osConfig.stylix.cursor) package size;
      name = cursorName other;
    };
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-${other}";
  };

  # Beats stylix, which writes "default" for light (not "prefer-light"), but loses to the
  # specialisation's mkForce.
  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkOverride 60 "prefer-${default}";
}
