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
      # Block AI features (also future ones), except the two that run locally
      AIControls = {
        Default = {
          Value = "blocked";
          Locked = true;
        };
        Translations = {
          Value = "available";
          Locked = true;
        };
        PDFAltText = {
          Value = "available";
          Locked = true;
        };
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
        ImproveSuggest = false;
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        MoreFromMozilla = false;
        SkipOnboarding = true;
      };
      HttpsOnlyMode = "enabled";
      # PDFs open in zathura (the xdg default, modules/home/mimeapps.nix)
      DisableBuiltinPDFViewer = true;
      Handlers.mimeTypes."application/pdf" = {
        action = "useSystemDefault";
        ask = false;
      };
      # Not packaged in NUR, so installed from addons.mozilla.org
      ExtensionSettings."{8fc14e5e-b3fd-43b3-9eec-c61c08781782}" = {
        installation_mode = "force_installed";
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/twitch-ad-muter/latest.xpi";
      };
      # uBlock filter lists: the defaults plus URL tracking, cookie notices, annoyances
      # and the Nordic (Danish) list. Replaces the list selection on every start.
      "3rdparty".Extensions."uBlock0@raymondhill.net".toOverwrite.filterLists = [
        "user-filters"
        # defaults
        "ublock-filters"
        "ublock-badware"
        "ublock-privacy"
        "ublock-unbreak"
        "ublock-quick-fixes"
        "easylist"
        "easyprivacy"
        "urlhaus-1"
        "plowe-0"
        # privacy
        "adguard-spyware-url"
        # cookie notices
        "adguard-cookies"
        "ublock-cookies-adguard"
        "fanboy-cookiemonster"
        "ublock-cookies-easylist"
        # annoyances
        "ublock-annoyances"
        "adguard-popup-overlays"
        "adguard-mobile-app-banners"
        "adguard-other-annoyances"
        "adguard-widgets"
        "easylist-annoyances"
        "easylist-chat"
        "easylist-newsletters"
        "easylist-notifications"
        # region
        "NOR-0"
      ];
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
          sponsorblock
          return-youtube-dislikes
          enhancer-for-youtube
          reddit-enhancement-suite
          frankerfacez
          leechblock-ng
          violentmonkey
          react-devtools
        ];
      };
      search = {
        force = true;
        default = "ddg";
        engines = {
          wikipedia.metaData.alias = "@w";
          nix-options = {
            name = "NixOS options";
            urls = [ { template = "https://search.nixos.org/options?channel=unstable&query={searchTerms}"; } ];
            definedAliases = [ "@nix" ];
          };
          nix-packages = {
            name = "Nix packages";
            urls = [ { template = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"; } ];
            definedAliases = [ "@np" ];
          };
          home-manager = {
            name = "Home Manager options";
            urls = [
              { template = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}"; }
            ];
            definedAliases = [ "@hm" ];
          };
          noogle = {
            name = "Noogle";
            urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
            definedAliases = [ "@ng" ];
          };
          arch-wiki = {
            name = "Arch Wiki";
            urls = [ { template = "https://wiki.archlinux.org/index.php?search={searchTerms}"; } ];
            definedAliases = [ "@aw" ];
          };
          mdn = {
            name = "MDN";
            urls = [ { template = "https://developer.mozilla.org/en-US/search?q={searchTerms}"; } ];
            definedAliases = [ "@mdn" ];
          };
          github = {
            name = "GitHub";
            urls = [ { template = "https://github.com/search?type=code&q={searchTerms}"; } ];
            definedAliases = [ "@gh" ];
          };
          youtube = {
            name = "YouTube";
            urls = [ { template = "https://www.youtube.com/results?search_query={searchTerms}"; } ];
            definedAliases = [ "@yt" ];
          };
          bing.metaData.hidden = true;
          perplexity.metaData.hidden = true;
        };
      };
      settings = {
        # Sync keeps bookmarks, history, tabs, addresses and extension data.
        # Settings and the extension list come from this file; passwords from Bitwarden.
        "services.sync.engine.prefs" = false;
        "services.sync.engine.addons" = false;
        "services.sync.engine.passwords" = false;
        # Downloads go straight to ~/Downloads
        "browser.download.useDownloadDir" = true;
        "browser.download.folderList" = 1;
        # UI: vertical tabs, compact, no titlebar buttons (Hyprland manages windows)
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.main.tools" = "history,bookmarks,syncedtabs";
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        "browser.tabs.inTitlebar" = 0;
        "browser.tabs.warnOnClose" = false;
        "browser.startup.page" = 3;
        # Tracking protection beyond the defaults (was set by hand before)
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.query_stripping.enabled" = true;
        "privacy.query_stripping.enabled.pbmode" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.bounceTrackingProtection.mode" = 1;
        "network.prefetch-next" = false;
        "network.dns.disablePrefetch" = true;
        "network.http.speculative-parallel-limit" = 0;
        "media.eme.enabled" = true;
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
