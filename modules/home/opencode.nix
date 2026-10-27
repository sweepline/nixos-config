{
  config,
  osConfig,
  ...
}:
let
  dir = "${osConfig.my.configDir}/dotfiles/opencode";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dir}/${file}";
in
{
  # Plain symlinks into the repo, so opencode's config can be edited in place. Only these
  # files: the rest of ~/.config/opencode (service.json, ...) is written by opencode itself.
  xdg.configFile = {
    "opencode/opencode.json".source = link "opencode.json";
    "opencode/cli.json".source = link "cli.json";
    # Global instructions for every project (NixOS tooling hints)
    "opencode/AGENTS.md".source = link "AGENTS.md";
  };
}
