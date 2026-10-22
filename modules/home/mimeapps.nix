{ lib, ... }:
let
  firefox = [
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/chrome"
    "text/html"
    "application/x-extension-htm"
    "application/x-extension-html"
    "application/x-extension-shtml"
    "application/xhtml+xml"
    "application/x-extension-xhtml"
    "application/x-extension-xht"
  ];
  images = map (t: "image/${t}") [
    "png"
    "jpeg"
    "gif"
    "webp"
    "bmp"
    "svg+xml"
    "tiff"
    "jxl"
    "avif"
    "heif"
    "heic"
    "qoi"
  ];
  assign = app: types: lib.genAttrs types (_: app);
in
{
  # Opening a folder (e.g. "Show in folder" in Firefox) starts yazi in kitty.
  xdg.desktopEntries.yazi-kitty = {
    name = "yazi";
    genericName = "File Manager";
    exec = "kitty -e yazi %u";
    icon = "system-file-manager";
    mimeType = [ "inode/directory" ];
    noDisplay = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      assign "firefox.desktop" firefox
      // assign "swayimg.desktop" images
      // {
        "inode/directory" = "yazi-kitty.desktop";
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
        "video/mp4" = "mpv.desktop";
        "application/pdf" = "org.pwmt.zathura.desktop";
      };
  };
}
