{ pkgs, ... }:
let
  # Mod+Shift+R: select a region and start recording; press again to stop.
  screenRecord = pkgs.writeShellApplication {
    name = "screen-record";
    runtimeInputs = with pkgs; [
      gpu-screen-recorder
      slurp
      libnotify
      procps
      coreutils
    ];
    text = ''
      if pkill -SIGINT -f '^gpu-screen-recorder '; then
        notify-send "Recording saved" "$HOME/Videos"
        exit 0
      fi
      region="$(slurp -f '%wx%h+%x+%y')" || exit 0
      mkdir -p "$HOME/Videos"
      file="$HOME/Videos/recording_$(date +%F_%H-%M-%S).mp4"
      notify-send "Recording" "Press Mod+Shift+R again to stop"
      exec gpu-screen-recorder -w region -region "$region" -f 60 -a default_output -o "$file"
    '';
  };
in
{
  home.packages = [
    screenRecord
    pkgs.gpu-screen-recorder-gtk
  ];
}
