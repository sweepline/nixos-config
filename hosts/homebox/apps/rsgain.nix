# ReplayGain tags for the music library (was a container looping `rsgain easy -S` every 6 h).
#
# Every 15 minutes, only the album folders with new or moved audio files are processed. Even
# with -S (skip tagged files) a run over the whole library opens every file, which makes the
# hard drives seek for minutes. Finding changed files only reads metadata, which is on the
# NVMe special vdev, so the drives stay quiet unless there is new music.
#
# Files are found by ctime, not mtime: moving a file into the library (Lidarr's import)
# updates its ctime but keeps the mtime it had when it was downloaded. A tag edited in place
# without a rename is not noticed, but such a file already has ReplayGain tags.
#
# A full pass also runs once a month as a safety net (and can be started by hand, e.g. after
# restoring files with old ctimes):
#   sudo systemctl start rsgain-full
{ lib, pkgs, ... }:
let
  library = "/storage/music/library";

  # Formats rsgain can tag.
  audioExtensions = [
    "flac"
    "mp3"
    "ogg"
    "oga"
    "opus"
    "m4a"
    "mp4"
    "wma"
    "wav"
    "aiff"
    "wv"
    "ape"
    "mpc"
  ];
  findAudio = lib.concatStringsSep " -o " (map (e: "-iname '*.${e}'") audioExtensions);

  changedAlbums = pkgs.writeShellApplication {
    name = "rsgain-changed-albums";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.rsgain
    ];
    text = ''
      stamp="$STATE_DIRECTORY/last-run"
      next="$STATE_DIRECTORY/last-run.next"
      # Taken before the scan: whatever changes while rsgain runs is picked up next time.
      # (That includes rsgain's own tag writes, so a new album is read once more, but -S then
      # skips it without writing.)
      touch "$next"

      if [ ! -e "$stamp" ]; then
        echo "no previous run: processing the whole library"
        rsgain easy -S ${library}
      else
        find ${library} -type f \( ${findAudio} \) -cnewer "$stamp" -printf '%h\0' |
          sort -zu |
          while IFS= read -r -d "" album; do
            echo "processing $album"
            rsgain easy -S "$album"
          done
      fi

      mv "$next" "$stamp"
    '';
  };

  serviceConfig = {
    Type = "oneshot";
    # As mikkel in the music group: files that slskd downloaded and Lidarr moved into the
    # library belong to slskd's user, but are group-writable for music.
    User = "mikkel";
    Group = "music";
    UMask = "0002";
    # Runs in the background without slowing down streaming.
    Nice = 19;
    IOSchedulingClass = "idle";
    # Only needs to write the library (and its own timestamp in /var/lib/rsgain).
    StateDirectory = "rsgain";
    ProtectSystem = "strict";
    ReadWritePaths = [ library ];
    ProtectHome = true;
    PrivateTmp = true;
    NoNewPrivileges = true;
  };

  # Only when the music dataset is mounted (ZFS mounts are not systemd mount units, so
  # RequiresMountsFor would not help).
  unitConfig.ConditionPathIsMountPoint = "/storage/music";
  after = [
    "zfs-mount.service"
    "datasets.service"
  ];
in
{
  systemd.services.rsgain = {
    description = "ReplayGain tags for new music";
    inherit unitConfig after;
    serviceConfig = serviceConfig // {
      ExecStart = lib.getExe changedAlbums;
    };
  };

  systemd.timers.rsgain = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/15";
  };

  systemd.services.rsgain-full = {
    description = "ReplayGain tags for the whole music library";
    inherit unitConfig after;
    serviceConfig = serviceConfig // {
      ExecStart = "${pkgs.rsgain}/bin/rsgain easy -S ${library}";
    };
  };

  systemd.timers.rsgain-full = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Midday, so the few minutes of drive noise are not at night. Persistent: catches up if
      # the server was off.
      OnCalendar = "*-*-01 13:00:00";
      Persistent = true;
    };
  };
}
