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
  # Plain symlinks into the repo, so opencode's config can be edited in place. Only these two
  # files: the rest of ~/.config/opencode (service.json, ...) is written by opencode itself.
  xdg.configFile = {
    "opencode/opencode.json".source = link "opencode.json";
    "opencode/cli.json".source = link "cli.json";
  };
}
