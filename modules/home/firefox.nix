{ pkgs, ... }:
let
  addons = pkgs.nur.repos.rycee.firefox-addons;
in
{
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };
      FirefoxHome = {
        SponsoredTopSites = false;
        SponsoredPocket = false;
        Pocket = false;
      };
    };

    profiles.mikkel = {
      id = 0;
      isDefault = true;
      extensions = {
        force = true;
        # TODO: pick Tridactyl or Vimium (see TODO.md)
        packages = with addons; [
          ublock-origin
          bitwarden
        ];
      };
      settings = {
        # Hardware video decoding (VA-API)
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "widget.dmabuf.force-enabled" = true;
        # Privacy
        "toolkit.telemetry.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "extensions.pocket.enabled" = false;
        "browser.shell.checkDefaultBrowser" = false;
        # Follow the light/dark toggle (via the portal color-scheme)
        "layout.css.prefers-color-scheme.content-override" = 2;
        "extensions.autoDisableScopes" = 0;
      };
    };
  };

  stylix.targets.firefox.profileNames = [ "mikkel" ];
}
