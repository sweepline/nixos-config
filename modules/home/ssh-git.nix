{ lib, pkgs, ... }:
{
  # The agent is gcr-ssh-agent (modules/nixos/desktop/session.nix): the key passphrase
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
      "*.i.esmi.dk".User = "mikkel";
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        email = "m@esmi.dk";
        name = "Mikkel Holmer Pedersen";
      };
      push = {
        default = "simple";
        autoSetupRemote = true;
      };
      core.editor = "nvim";
      init.defaultBranch = "main";
      diff = {
        algorithm = "histogram";
        tool = "nvimdiff";
      };
      difftool = {
        prompt = false;
        nvimdiff.cmd = "nvim -n -d \"$LOCAL\" \"$REMOTE\"";
      };
      merge = {
        # Include the common ancestor in conflict markers; required by
        # diffview.nvim's conflict_choose("base") action (<leader>cb).
        conflictStyle = "zdiff3";
        tool = "diffview";
      };
      mergetool = {
        keepBackup = false;
        prompt = false;
        diffview.cmd = "nvim -n -c \"DiffviewOpen\" \"$MERGED\"";
      };
      rerere.enabled = true;
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
        amend = "commit --amend --no-edit";
        dv = "!f() { nvim -c \"DiffviewOpen $*\"; }; f";
      };
    };
  };
}
