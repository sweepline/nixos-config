{ pkgs, ... }:
let
  # Mod+Shift+R: select a region and start recording; press again to stop.
  screenRecord = pkgs.writeShellApplication {
    name = "screen-record";
    runtimeInputs = with pkgs; [
      gpu-screen-recorder
      slurp
      libnotify
      coreutils
      gnugrep
    ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/screen-record"

      # Second press: stop the running recording. The recorder is a Nix wrapper script, so
      # its command line starts with a store path and cannot be matched by name; the PID
      # saved at start is used instead.
      if [ -f "$state" ]; then
        pid="$(head -n1 "$state")"
        file="$(tail -n1 "$state")"
        if [ -n "$pid" ] && { tr '\0' ' ' < "/proc/$pid/cmdline"; } 2>/dev/null | grep -q gpu-screen-recorder; then
          kill -INT "$pid"
          # On SIGINT the recorder finishes writing the file, then exits.
          for _ in $(seq 1 100); do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.1
          done
          rm -f "$state"
          notify-send "Recording saved" "$file"
          exit 0
        fi
        # Stale state from a recorder that is gone: start a new recording below.
        rm -f "$state"
      fi

      region="$(slurp -f '%wx%h+%x+%y')" || exit 0
      mkdir -p "$HOME/Videos"
      file="$HOME/Videos/recording_$(date +%F_%H-%M-%S).mp4"
      notify-send "Recording" "Press Mod+Shift+R again to stop"
      # exec keeps this PID, so the saved PID is the recorder's.
      printf '%s\n%s\n' "$$" "$file" > "$state"
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
