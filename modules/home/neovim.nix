{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  nvimDir = "${osConfig.my.configDir}/dotfiles/nvim";
  link = path: config.lib.file.mkOutOfStoreSymlink "${nvimDir}/${path}";
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withNodeJs = true;
    withPython3 = true;
    # Language servers and tools for the lazy.nvim config (Mason is not used).
    extraPackages = with pkgs; [
      # Build tools for treesitter parsers and plugins
      gcc
      gnumake
      tree-sitter
      ripgrep
      fd
      unzip
      # HTML/CSS/JS/TS
      vscode-langservers-extracted
      typescript-language-server
      typescript
      efm-langserver
      biome
      prettier
      stylelint
      # Python
      basedpyright
      ruff
      # Rust
      rust-analyzer
      # Other
      lua-language-server
      clang-tools
      dockerfile-language-server
      docker-compose-language-service
      wgsl-analyzer
      copilot-language-server
      nixd
      nixfmt
    ];
  };

  # Your Lua config lives in this repo and is linked, not copied, so you can
  # edit it directly and lazy.nvim can update plugins and write lazy-lock.json.
  # Home Manager owns init.lua (it sets the Python/Node provider paths there)
  # and runs the repo's init.lua from it.
  programs.neovim.initLua = lib.mkAfter ''
    dofile("${nvimDir}/init.lua")
  '';
  xdg.configFile = {
    "nvim/lua".source = link "lua";
    "nvim/lazy-lock.json".source = link "lazy-lock.json";
  };

  # Colors come from the gruvbox-material plugin in the Lua config (it follows
  # the light/dark toggle through auto-dark-mode.nvim).
  stylix.targets.neovim.enable = false;
}
