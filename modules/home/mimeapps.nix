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
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      assign "firefox.desktop" firefox
      // assign "swayimg.desktop" images
      // {
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
        "video/mp4" = "mpv.desktop";
        "application/pdf" = "firefox.desktop";
      };
  };
}
