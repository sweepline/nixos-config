{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  scalgoRoot = ../../certs/scalgo-root.crt;
in
lib.mkIf osConfig.my.work.enable {
  # Rootless buildah (used by mono's deploy scripts) re-execs into a user namespace and then
  # picks up the system storage.conf (/var/lib, /run/containers) and fails with "mkdir
  # /run/containers: permission denied". Podman doesn't have this problem. Pinning the
  # rootless graphroot here fixes buildah, and podman already uses this path, so both
  # share the same images.
  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    driver = "overlay"
    graphroot = "${config.xdg.dataHome}/containers/storage"
  '';

  # Firefox uses its own trust store, not the system one; a policy installs the root CA.
  programs.firefox.policies.Certificates.Install = [ "${scalgoRoot}" ];

  # Chromium on Linux only trusts extra roots from the NSS db in ~/.pki/nssdb, and has no
  # policy to add them, so add it there (what mono's `ca.py install-root` does by hand).
  home.activation.scalgoRootNss = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    db="$HOME/.pki/nssdb"
    run mkdir -p "$db"
    if [ ! -f "$db/cert9.db" ]; then
      run ${pkgs.nssTools}/bin/certutil -d "sql:$db" -N --empty-password
    fi
    run ${pkgs.nssTools}/bin/certutil -d "sql:$db" -A -t "C,," -n "SCALGO Root" -i ${scalgoRoot}
  '';

  programs.ssh.settings = {
    # Scalgo servers
    "git? ts?? ws? cs? c01 c01n?? gpu?? gpuc? management cc run?? ul? backup? ts??.na ts??na" = {
      HostName = "%h.emu-buri.ts.net";
      ServerAliveInterval = 30;
      ServerAliveCountMax = 10;
    };
    "git.i.scalgo.com".HostName = "git2.emu-buri.ts.net";
    "localhost.scalgo.com" = {
      HostName = "127.0.0.1";
      Port = 22;
      ControlMaster = "auto";
      ControlPath = "~/.ssh/cm-%C";
      ControlPersist = "1h";
    };
  };

  programs.git = {
    # Work email in every repo with a remote on Scalgo's GitLab.
    includes = [
      {
        condition = "hasconfig:remote.*.url:git@git.i.scalgo.com:**";
        contents.user.email = "mikkel@scalgo.com";
      }
      {
        condition = "hasconfig:remote.*.url:https://git.i.scalgo.com/**";
        contents.user.email = "mikkel@scalgo.com";
      }
    ];

    settings.alias = {
      fixup = "!~/scalgo/git-fixup/git-fixup.sh";
      add-no-white = "! git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
      pushmr = "!if [ $(git branch --show-current) != master ]; then git push -o merge_request.create -o merge_request.target=master --set-upstream origin $(git branch --show-current); else echo \"Can't push mr on master\"; fi";
      pushmrauto = "!if [ $(git branch --show-current) != master ]; then git push -o merge_request.create -o merge_request.target=master -o merge_request.merge_when_pipeline_succeeds --set-upstream origin $(git branch --show-current) && git switch master; else echo \"Can't push mr on master\"; fi";
      pushsr = "!git stash && git pull --rebase && git push && git stash pop";
      grepall = "!git grep -i \"$@\" -- . ':^*.min.js' ':^*/sqlx-data.json' ':^*/dfsinfo.js' ':^*/ol.css' ':^*/scalgo.css.map' ':^*/scalgo2.css.map' ':^*/viz.js' #";
      ud = "range-diff origin/master @{u} @";
      wiki = "!git add -p . && git commit -m 'Update mikkel_notes.md' && git pull --rebase && git push";
    };
  };

  programs.bash = {
    shellAliases.localstack = "$HOME/repos/mono/scripts/localstack.py";
    initExtra = ''
      findimage() {
        sadmin listImages -e 'docker:sadmin.scalgo.com/{image}@{hash} {rel_time} {labels[GIT_BRANCH]}' -i ''${1:-$(basename `pwd`)} | grep `git rev-parse --abbrev-ref HEAD`
      }
    '';
  };
}
