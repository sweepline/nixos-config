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
      # Work
      localstack = "$HOME/repos/mono/scripts/localstack.py";
      vncstart = "wayvnc -o DP-5 -g 0.0.0.0";
    };
    sessionVariables = {
      SCCACHE_REDIS = "redis://esa";
    };
    initExtra = ''
      PROMPT_COMMAND="history -a"

      source ${config.programs.git.package}/share/bash-completion/completions/git-prompt.sh
      export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(__git_ps1)\[\033[00m\] $ "

      findimage() {
        sadmin listImages -e 'docker:sadmin.scalgo.com/{image}@{hash} {rel_time} {labels[GIT_BRANCH]}' -i ''${1:-$(basename `pwd`)} | grep `git rev-parse --abbrev-ref HEAD`
      }

      ${builtins.readFile ./gut.sh}
    '';
  };

  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/.local/share/pnpm"
    "$HOME/.bun/bin"
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PNPM_HOME = "$HOME/.local/share/pnpm";
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

  # nix-locate, and "command not found" suggestions
  programs.nix-index = {
    enable = true;
    enableBashIntegration = true;
  };
}
