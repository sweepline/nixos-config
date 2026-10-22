{ lib, pkgs, ... }:
let
  # Dark is the normal Home Manager generation; light is a specialisation of it.
  # The waybar button activates the other one (no rebuild, both are prebuilt).
  themeToggle = pkgs.writeShellApplication {
    name = "theme-toggle";
    runtimeInputs = with pkgs; [
      glib
      coreutils
    ];
    text = ''
      schema=org.gnome.desktop.interface
      key=color-scheme
      state="''${XDG_STATE_HOME:-$HOME/.local/state}"
      current="$state/home-manager/gcroots/current-home"
      basefile="$state/theme-base-generation"

      show() {
        case "$(gsettings get "$schema" "$key")" in
          *dark*) printf '{"text":"\U000f186","class":"dark","tooltip":"Dark theme — click for light"}\n' ;;
          *)      printf '{"text":"\U000f185","class":"light","tooltip":"Light theme — click for dark"}\n' ;;
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
