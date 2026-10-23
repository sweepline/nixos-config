{ pkgs, ... }:
let
  # Picks a random wallpaper per monitor from ~/Pictures/Wallpapers, matching
  # orientation: portrait images for rotated monitors, landscape for the rest.
  wallpaperRandom = pkgs.writeShellApplication {
    name = "wallpaper-random";
    runtimeInputs = with pkgs; [
      hyprland
      jq
      imagemagick
      coreutils
      findutils
      gnugrep
    ];
    text = ''
      dir="''${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
      cache="''${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-orientation"
      touch "$cache"

      # Cache "path<TAB>portrait|landscape" so identify only runs once per image.
      mapfile -t files < <(find "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort)
      [[ ''${#files[@]} -gt 0 ]] || { echo "No wallpapers in $dir" >&2; exit 0; }
      for f in "''${files[@]}"; do
        grep -qF "$f	" "$cache" && continue
        read -r w h < <(identify -format '%w %h\n' "''${f}[0]" 2>/dev/null || echo "1 0")
        if (( h > w )); then o=portrait; else o=landscape; fi
        printf '%s\t%s\n' "$f" "$o" >> "$cache"
      done

      pick() {
        local want="$1" pool
        pool="$(grep -P "\t$want$" "$cache" | cut -f1 | while read -r f; do [[ -f "$f" ]] && echo "$f"; done)"
        [[ -z "$pool" ]] && pool="$(printf '%s\n' "''${files[@]}")"
        for used in "''${chosen[@]}"; do pool="$(grep -vxF "$used" <<<"$pool" || true)"; done
        [[ -z "$pool" ]] && pool="$(printf '%s\n' "''${files[@]}")"
        shuf -n1 <<<"$pool"
      }

      # hyprpaper starts together with the session: retry until it accepts the request.
      set_wallpaper() {
        for _ in $(seq 1 50); do
          hyprctl hyprpaper wallpaper "$1, $2, cover" >/dev/null 2>&1 && return 0
          sleep 0.2
        done
        echo "hyprpaper did not accept $2 for $1" >&2
      }

      # Right after login Hyprland may not answer (or list its monitors) yet: wait for it.
      monitors=""
      for _ in $(seq 1 50); do
        monitors="$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | "\(.name) \(.transform)"' || true)"
        [[ -n "$monitors" ]] && break
        sleep 0.2
      done
      [[ -n "$monitors" ]] || { echo "Hyprland did not list any monitors" >&2; exit 1; }

      chosen=()
      while read -r name transform; do
        if (( transform % 2 == 1 )); then want=portrait; else want=landscape; fi
        img="$(pick "$want")"
        chosen+=("$img")
        set_wallpaper "$name" "$img"
      done <<<"$monitors"
    '';
  };
in
{
  home.packages = [ wallpaperRandom ];

  # The wallpapers themselves are set per monitor by the script above (over hyprpaper's IPC).
  services.hyprpaper = {
    enable = true;
    settings.splash = false;
  };

  systemd.user.services.wallpaper-random = {
    Unit = {
      Description = "Random wallpaper per monitor";
      Wants = [ "hyprpaper.service" ];
      After = [ "hyprpaper.service" ];
      PartOf = [ "hyprpaper.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${wallpaperRandom}/bin/wallpaper-random";
    };
    # Not graphical-session.target: hyprpaper starts after that target, so ordering this
    # after hyprpaper and before the target is a cycle (systemd then drops this job).
    Install.WantedBy = [ "hyprpaper.service" ];
  };
}
