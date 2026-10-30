# Reverse proxy and TLS for everything on the server. Certificates come from Let's Encrypt
# through the Cloudflare DNS challenge: one wildcard for the public names and one for the
# internal *.i. names (Caddy >= 2.10 uses a matching wildcard instead of getting a certificate
# per name, so the CT logs only show the two wildcards).
#
# The domain is a secret (docs/HOMEBOX.md, domain.nix): Caddy substitutes {$DOMAIN} when it
# reads the Caddyfile (start and reload). Names in this repo never contain it.
#
# Apps add themselves with my.proxy, keyed by the name without the domain (usually next to
# their container):
#   my.proxy."sonarr.i".port = 8101;                                         # internal
#   my.proxy."stream" = { port = 8096; public = true; maintenance = true; }; # public
{
  config,
  lib,
  pkgs,
  ...
}:
let
  secret = ../../secrets/caddy-homebox.age;
  hasSecret = builtins.pathExists secret;

  # Without the secret the names end in the reserved .invalid TLD, so Caddy still starts
  # (and the VM test works) instead of failing on addresses like "stream.".
  domain = "{$DOMAIN:invalid}";
  host = name: "${name}.${domain}";

  maintenancePage = ./www/maintenance;

  # Port 443 is forwarded from the internet, so every site is reachable from outside by
  # sending its name (SNI/Host) to the public IP; leaving the internal names out of public DNS
  # is not enough. Internal sites therefore drop connections that do not come from a private
  # address: LAN, the server VLAN, WireGuard (192.168.3.0/24, fd0c:d4ed:7945:ddd9::/64) and the
  # router's hairpin NAT. A list of subnets would miss the LAN's IPv6 prefix, which comes from
  # the ISP and can change.
  internalOnly = ''
    @external not remote_ip private_ranges
    abort @external
  '';

  # Everything in a `route` block: there Caddy runs the directives in the order written.
  # Outside of one it sorts them by type, and `handle` (e.g. cgit's site) comes before
  # `abort`, so the internal-only check would never run and the site would be public.
  siteConfig = site: ''
    route {
      ${lib.optionalString (!site.public) internalOnly}
      ${lib.optionalString (site.port != null) "reverse_proxy localhost:${toString site.port}"}
      ${site.extraConfig}
    }
    ${lib.optionalString site.maintenance ''
      # Shown while the app is down or restarting (it does not answer), with the upstream's
      # error status so clients and monitoring still see the outage.
      handle_errors 502 503 504 {
        root * ${maintenancePage}
        rewrite * /index.html
        file_server {
          status {err.status_code}
        }
      }
    ''}
  '';
in
{
  options.my.proxy = lib.mkOption {
    description = ''
      Sites served by Caddy, proxied to a port on localhost. Keyed by the host name without
      the domain ("stream", "sonarr.i"); internal names end in ".i".
    '';
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.nullOr lib.types.port;
            default = null;
            description = "Port the app listens on at 127.0.0.1. Null for sites set up with extraConfig only.";
          };
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Further Caddy directives for the site, e.g. instead of a port (cgit's FastCGI).";
          };
          public = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Reachable from the internet. Otherwise only from private addresses (LAN, WireGuard).";
          };
          maintenance = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Show the maintenance page (www/maintenance) while the app is down.";
          };
        };
      }
    );
  };

  config = {
    assertions = lib.concatLists (
      lib.mapAttrsToList (name: site: [
        {
          # Catches a public site under the internal names (or an internal one outside them),
          # which would put it under the wrong wildcard certificate and expectations.
          assertion = site.public == !(lib.hasSuffix ".i" name);
          message = "my.proxy.\"${name}\": names ending in \".i\" are internal, all others must set public = true.";
        }
        {
          assertion = site.port != null || site.extraConfig != "";
          message = "my.proxy.\"${name}\": set port or extraConfig.";
        }
      ]) config.my.proxy
    );

    services.caddy = {
      enable = true;
      # Cloudflare plugin for the DNS challenge. v0.2.4 or newer is needed for Cloudflare's
      # current token format (cfut_..., longer than older versions accept:
      # https://github.com/caddy-dns/cloudflare/issues/127).
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
      };
      # CF_API_TOKEN=... (Zone:Read + DNS:Edit for the new zone only). DOMAIN comes from the
      # domain secret (domain.nix), added below. Without them Caddy still runs, but on
      # .invalid names and without certificates.
      environmentFile = lib.mkIf hasSecret config.age.secrets.caddy.path;
      globalConfig = ''
        acme_dns cloudflare {env.CF_API_TOKEN}
      '';

      virtualHosts = {
        # These two get the wildcard certificates, and answer for names without a site of
        # their own: public ones are dropped, internal ones get a 404.
        "*.${domain}".extraConfig = ''
          abort
        '';
        "*.i.${domain}".extraConfig = ''
          ${internalOnly}
          respond "Not found" 404
        '';
        # Quick check that Caddy and the internal network path work.
        ${host "homebox.i"}.extraConfig = ''
          ${internalOnly}
          respond "Hello, world!"
        '';
      }
      // lib.mapAttrs' (
        name: site: lib.nameValuePair (host name) { extraConfig = siteConfig site; }
      ) config.my.proxy;
    };

    age.secrets.caddy = lib.mkIf hasSecret {
      file = secret;
    };

    # The module only takes one environment file; systemd merges this list with it.
    systemd.services.caddy.serviceConfig.EnvironmentFile = lib.mkIf (config.age.secrets ? domain) [
      config.age.secrets.domain.path
    ];

    networking.firewall = {
      allowedTCPPorts = [
        80
        443
      ];
      # HTTP/3
      allowedUDPPorts = [ 443 ];
    };
  };
}
