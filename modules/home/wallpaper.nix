{ pkgs, ... }:
let
  # Picks a random wallpaper per monitor from ~/Pictures/Wallpapers, matching
  # orientation: portrait images for rotated monitors, landscape for the rest.
  wallpaperRandom = pkgs.writeShellApplication {
    name = "wallpaper-random";
    runtimeInputs = with pkgs; [
      awww
      hyprland
      jq
      imagemagick
      coreutils
      findutils
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
        read -r w h < <(identify -format '%w %h\n' "$f[0]" 2>/dev/null || echo "1 0")
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

      awww query >/dev/null 2>&1 || { awww-daemon & sleep 0.5; }

      chosen=()
      while read -r name transform; do
        if (( transform % 2 == 1 )); then want=portrait; else want=landscape; fi
        img="$(pick "$want")"
        chosen+=("$img")
        awww img -o "$name" --transition-type fade "$img"
      done < <(hyprctl monitors -j | jq -r '.[] | "\(.name) \(.transform)"')
    '';
  };
in
{
  home.packages = [
    wallpaperRandom
    pkgs.awww
  ];

  systemd.user.services.wallpaper = {
    Unit = {
      Description = "Random wallpaper per monitor";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      ExecStartPost = "${pkgs.bash}/bin/bash -c 'sleep 1; ${wallpaperRandom}/bin/wallpaper-random'";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
