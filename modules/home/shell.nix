{ config, ... }:
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    historySize = 10000;
    historyFileSize = -1;
    historyControl = [ "ignorespace" ];
    shellOptions = [
      "histappend"
      "checkwinsize"
    ];
    shellAliases = {
      vimf = "nvim $(fzf --height 40%)";
      oc = "opencode";
      bp = "bpython";
      mvi = "mv -iv";
      cpi = "cp -riv";
      mkdiri = "mkdir -vp";
      rmi = "rm -v";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
    };
    initExtra = ''
      PROMPT_COMMAND="history -a"

      # Per-host API tokens from agenix (modules/nixos/desktop/env-secrets.nix)
      if [[ -r /run/agenix/env ]]; then
        set -a
        source /run/agenix/env
        set +a
      fi

      source ${config.programs.git.package}/share/bash-completion/completions/git-prompt.sh
      # IN_NIX_SHELL is what `nix develop` (and legacy `nix-shell`) export inside the shell,
      # so the (nix) marker shows whenever a nix dev env is active.
      export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(__git_ps1)\[\033[00m\]\''${IN_NIX_SHELL:+ \[\033[35m\](nix)\[\033[00m\]} $ "

      ${builtins.readFile ./gut.sh}
    '';
  };

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
    "$HOME/.local/share/pnpm/bin"
    "$HOME/.bun/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    COREPACK_ENABLE_DOWNLOAD_PROMPT = "0";
    BUN_INSTALL = "$HOME/.bun";
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;
  };

  # nix-locate, "command not found" suggestions, and `, <cmd>` to run any package without
  # installing it. The database comes prebuilt from nix-index-database (flake.nix).
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
  };
  programs.nix-index-database.comma.enable = true;
}
