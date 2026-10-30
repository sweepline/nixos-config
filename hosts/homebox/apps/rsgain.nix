# ReplayGain tags for the music library. Was a container looping `rsgain easy -S` with a
# 6 h sleep; rsgain is packaged in nixpkgs, so a timer is simpler.
{ pkgs, ... }:
{
  systemd.services.rsgain = {
    description = "ReplayGain tags for the music library";
    after = [
      "zfs-mount.service"
      "datasets.service"
    ];
    # Only when the music dataset is mounted (ZFS mounts are not systemd mount units, so
    # RequiresMountsFor would not help).
    unitConfig.ConditionPathIsMountPoint = "/storage/music";
    serviceConfig = {
      Type = "oneshot";
      # As mikkel in the music group: files that slskd downloaded and Lidarr moved into the
      # library belong to slskd's user, but are group-writable for music.
      User = "mikkel";
      Group = "music";
      UMask = "0002";
      # -S: skip files that already have ReplayGain tags, so only new music is written.
      ExecStart = "${pkgs.rsgain}/bin/rsgain easy -S /storage/music/library";
      # Runs in the background without slowing down streaming.
      Nice = 19;
      IOSchedulingClass = "idle";
      # Only needs to write the library.
      ProtectSystem = "strict";
      ReadWritePaths = [ "/storage/music/library" ];
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.rsgain = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "00/6:00";
      Persistent = true;
      RandomizedDelaySec = "30m";
    };
  };
}
