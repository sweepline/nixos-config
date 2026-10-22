{ config, pkgs, ... }:
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

  # Your Lua config lives in this repo and is linked, not copied, so lazy.nvim
  # can update plugins and write lazy-lock.json.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/nixos-config/dotfiles/nvim";
}
