{ lib, pkgs, ... }:
let
  # Dark is the normal Home Manager generation; light is a specialisation of it.
  # The theme button in ashell activates the other one (no rebuild, both are prebuilt).
  themeToggle = pkgs.writeShellApplication {
    name = "theme-toggle";
    runtimeInputs = with pkgs; [
      glib
      coreutils
      procps
    ];
    text = ''
      schema=org.gnome.desktop.interface
      key=color-scheme
      state="''${XDG_STATE_HOME:-$HOME/.local/state}"
      current="$state/home-manager/gcroots/current-home"
      basefile="$state/theme-base-generation"

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
      if [[ -d "$gen/specialisation/light" ]]; then
        # On the dark base generation: remember it, switch to light.
        echo "$gen" > "$basefile"
        "$gen/specialisation/light/activate"
        gsettings set "$schema" "$key" prefer-light
      else
        base="$(cat "$basefile" 2>/dev/null || true)"
        if [[ -z "$base" || ! -x "$base/activate" ]]; then
          echo "Do not know the dark generation; run a rebuild first." >&2
          exit 1
        fi
        "$base/activate"
        gsettings set "$schema" "$key" prefer-dark
      fi

      # Running kitty windows reload their (stylix) config.
      pkill -USR1 -x kitty || true
    '';
  };
in
{
  home.packages = [ themeToggle ];

  specialisation.light.configuration = {
    stylix.polarity = lib.mkForce "light";
    stylix.base16Scheme = lib.mkForce "${pkgs.base16-schemes}/share/themes/gruvbox-material-light-medium.yaml";
    dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkForce "prefer-light";
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = lib.mkDefault "prefer-dark";
}
