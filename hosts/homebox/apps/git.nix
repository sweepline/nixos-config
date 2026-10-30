# Bare git repos in /storage/git, used over SSH as mikkel
#   git clone mikkel@192.168.3.2:/storage/git/foo.git
# and browsed read-only with cgit on git.i.<domain>. Repos also on GitHub get a second push
# URL (git remote set-url --add --push origin ...), so one push updates both.
#
# New repos: ssh mikkel@192.168.3.2 git init --bare /storage/git/foo.git (cgit lists every
# repo in the folder by itself; set the description in foo.git/description).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cgitDir = "${pkgs.cgit}/cgit";
  filters = "${pkgs.cgit}/lib/cgit/filters";

  cgitrc = pkgs.writeText "cgitrc" ''
    root-title=git
    root-desc=
    css=/cgit.css
    logo=/cgit.png
    favicon=/favicon.ico
    js=/cgit.js
    virtual-root=/
    # Render README.md on the about page, and highlight source files.
    readme=:README.md
    about-filter=${filters}/about-formatting.sh
    source-filter=${filters}/syntax-highlighting.py
    # Description, owner etc. from each repo's own config.
    enable-git-config=1
    remove-suffix=1
    clone-url=mikkel@192.168.3.2:/storage/git/$CGIT_REPO_URL.git
    # Must come after the options above: it applies them to the repos it finds.
    scan-path=/storage/git
  '';
in
{
  # mikkel pushes as himself; cgit only reads, through the group. The setgid bit gives new
  # repos (and everything in them) the group, and git writes group-readable files.
  my.datasets."storage/git" = {
    group = "cgit";
    mode = "2750";
  };

  users.users.cgit = {
    isSystemUser = true;
    group = "cgit";
  };
  users.groups.cgit = { };

  # cgit is a CGI program: fcgiwrap runs it as cgit for each request. Only Caddy can use the
  # socket.
  services.fcgiwrap.instances.cgit = {
    process = {
      user = "cgit";
      group = "cgit";
    };
    socket = {
      user = config.services.caddy.user;
      group = config.services.caddy.group;
      mode = "0600";
    };
  };

  my.proxy."git.i".extraConfig = ''
    @static path /cgit.css /cgit.png /cgit.js /favicon.ico /robots.txt
    handle @static {
      root * ${cgitDir}
      file_server
    }
    handle {
      reverse_proxy unix/${config.services.fcgiwrap.instances.cgit.socket.address} {
        transport fastcgi {
          env SCRIPT_FILENAME ${cgitDir}/cgit.cgi
          env CGIT_CONFIG ${cgitrc}
          # cgit takes the repo and page from PATH_INFO (virtual-root=/), not from a script
          # path like PHP.
          env SCRIPT_NAME ""
          env PATH_INFO {path}
        }
      }
    }
  '';
}
