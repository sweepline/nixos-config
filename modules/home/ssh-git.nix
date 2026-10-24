{ lib, pkgs, ... }:
{
  # The agent is gcr-ssh-agent (modules/nixos/desktop.nix): the key passphrase
  # is saved in the login keyring the first time, then never asked again.
  home.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  systemd.user.sessionVariables.SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";

  # Ly (PAM) only unlocks the keyring named "login". If an app stored a secret before
  # that keyring existed, gnome-keyring made a separate "Default_keyring" that asks for
  # its password on first use. Make "login" the default, and turn a Default_keyring into
  # the login keyring (needs the same password as the user). Skipped while
  # gnome-keyring runs, as it would write the old file back; Home Manager also runs at
  # boot, before login.
  home.activation.loginKeyring = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    keyrings="''${XDG_DATA_HOME:-$HOME/.local/share}/keyrings"
    if ! ${pkgs.procps}/bin/pgrep -u "$(id -u)" -x gnome-keyring-d >/dev/null; then
      if [[ -f "$keyrings/Default_keyring.keyring" && ! -e "$keyrings/login.keyring" ]]; then
        run cp -p "$keyrings/Default_keyring.keyring" "$keyrings/Default_keyring.keyring.bak"
        run mv "$keyrings/Default_keyring.keyring" "$keyrings/login.keyring"
      fi
      if [[ -d "$keyrings" && "$(cat "$keyrings/default" 2>/dev/null)" != login ]]; then
        printf login | run tee "$keyrings/default" >/dev/null
      fi
    fi
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
      };
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
      "*.i.esmi.dk".User = "mikkel";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        email = "mikkel@esmi.dk";
        name = "Mikkel Holmer Pedersen";
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      core.editor = "nvim";
      diff.tool = "nvimdiff";
      merge.tool = "nvimdiff";
      difftool.nvimdiff.cmd = "nvim -n -d \"$LOCAL\" \"$REMOTE\"";
      mergetool.keepBackup = false;
      pull = {
        ff = "only";
        rebase = true;
      };
      include.path = "~/.gitconfig.local";
      alias = {
        logd = "log --graph --decorate --pretty=oneline --abbrev-commit";
        pushl = "push --force-with-lease";
        s = "status";
        diffw = "diff --color-words --word-diff-regex='[a-zA-Z]+|[^[:space:]]' -b -U10";
        fixup = "!~/scalgo/git-fixup/git-fixup.sh";
        add-no-white = "! git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
        pushmr = "!if [ $(git branch --show-current) != master ]; then git push -o merge_request.create -o merge_request.target=master --set-upstream origin $(git branch --show-current); else echo \"Can't push mr on master\"; fi";
        pushmrauto = "!if [ $(git branch --show-current) != master ]; then git push -o merge_request.create -o merge_request.target=master -o merge_request.merge_when_pipeline_succeeds --set-upstream origin $(git branch --show-current) && git switch master; else echo \"Can't push mr on master\"; fi";
        pushsr = "!git stash && git pull --rebase && git push && git stash pop";
        grepall = "!git grep -i \"$@\" -- . ':^*.min.js' ':^*/sqlx-data.json' ':^*/dfsinfo.js' ':^*/ol.css' ':^*/scalgo.css.map' ':^*/scalgo2.css.map' ':^*/viz.js' #";
        ud = "range-diff origin/master @{u} @";
        wiki = "!git add -p . && git commit -m 'Update mikkel_notes.md' && git pull --rebase && git push";
        amend = "commit --amend --no-edit";
      };
    };
  };
}
