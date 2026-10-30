# Email alerts to myself, sent through Fastmail's SMTP server: failing disks (smartd), ZFS
# events (ZED: degraded pool, checksum errors, scrub results) and failed system services
# (nightly copy, snapshots, scrub, ...). With raidz2 two disks may fail, but only if the
# first one is noticed.
#
# secrets/smtp-homebox.age holds only a Fastmail app password (Settings > Privacy & Security >
# App passwords, access "SMTP"), a single line without a newline. Test after deploying:
#   echo test | sudo sendmail m@esmi.dk
#   sudo systemctl start notify-failure@test.service
{
  config,
  lib,
  pkgs,
  ...
}:
let
  secret = ../../secrets/smtp-homebox.age;
  address = "m@esmi.dk";

  # System services whose failure should send an email. Not every unit: a restarting app
  # container (user units) is visible in its app, these run unattended at night.
  watched = [
    "syncoid-appdata"
    "sanoid"
    "zfs-scrub"
    "storage-properties"
    "datasets"
    "rsgain"
    "rsgain-full"
    "caddy"
    "home-manager-mikkel"
  ];
in
lib.mkMerge [
  {
    age.secrets.smtp = lib.mkIf (builtins.pathExists secret) {
      file = secret;
      mode = "0400";
    };
  }
  # Only once the secret exists (the VM test brings its own, vm.nix).
  (lib.mkIf (config.age.secrets ? smtp) {

    programs.msmtp = {
      enable = true;
      accounts.default = {
        host = "smtp.fastmail.com";
        port = 465;
        tls = true;
        tls_starttls = false;
        auth = true;
        user = address;
        from = address;
        passwordeval = "cat ${config.age.secrets.smtp.path}";
      };
    };

    services.smartd = {
      enable = true;
      # Every disk; a short self-test every night at 02:00, a long one on the 15th at 03:00
      # (the long test takes hours on the HDDs but runs inside the drive, at low priority).
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../15/./03)";
      notifications = {
        mail = {
          enable = true;
          sender = address;
          recipient = address;
        };
        wall.enable = false;
      };
    };

    # msmtp provides `sendmail`, so ZED's email support is on (enableMail); only who gets it,
    # and also report scrubs that finished fine (a monthly sign of life).
    services.zfs.zed.settings = {
      ZED_EMAIL_ADDR = [ address ];
      ZED_NOTIFY_VERBOSE = true;
    };

    systemd.services = {
      "notify-failure@" = {
        description = "Email about the failure of %i";
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        script = ''
          {
            echo "To: ${address}"
            echo "From: homebox <${address}>"
            echo "Subject: homebox: $1 failed"
            echo
            ${pkgs.systemd}/bin/systemctl status --full --lines=50 --no-pager "$1" || true
          } | ${config.security.wrapperDir}/sendmail -t
        '';
      };
    }
    // lib.genAttrs watched (_: {
      onFailure = [ "notify-failure@%N.service" ];
    });
  })
]
