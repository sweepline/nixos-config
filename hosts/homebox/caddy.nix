# Reverse proxy and TLS for everything on the server. Certificates come from Let's Encrypt
# through the Cloudflare DNS challenge, including a wildcard for *.i.esmi.dk that every
# internal site uses (Caddy >= 2.10 picks the wildcard over per-name certificates).
#
# Apps add themselves with my.proxy (usually next to their container):
#   my.proxy."sonarr.i.esmi.dk".port = 8101;
{
  config,
  lib,
  pkgs,
  ...
}:
let
  secret = ../../secrets/caddy-homebox.age;
  hasSecret = builtins.pathExists secret;

  maintenancePage = ./www/maintenance;

  # Port 443 is forwarded from the internet, so every site is reachable from outside by
  # sending its name (SNI/Host) to the public IP; hiding the names from public DNS is not
  # enough (the wildcard certificate is in public CT logs). Internal sites therefore drop
  # connections that do not come from a private address: LAN (192.168.10.0/24), WireGuard
  # (192.168.3.0/24, fd0c:d4ed:7945:ddd9::/64) and the router's hairpin NAT. A list of
  # subnets would miss the LAN's IPv6 prefix, which comes from the ISP and can change.
  internalOnly = ''
    @external not remote_ip private_ranges
    abort @external
  '';

  siteConfig = site: ''
    ${lib.optionalString (!site.public) internalOnly}
    reverse_proxy localhost:${toString site.port}
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
    description = "Sites served by Caddy, by host name, proxied to a port on localhost.";
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.port;
            description = "Port the app listens on at 127.0.0.1.";
          };
          public = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Reachable from the internet. Otherwise only from LAN and WireGuard.";
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
    services.caddy = {
      enable = true;
      # Cloudflare plugin for the DNS challenge. v0.2.4 or newer is needed for Cloudflare's
      # current token format (cfut_..., longer than older versions accept:
      # https://github.com/caddy-dns/cloudflare/issues/127).
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
        hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
      };
      # CF_API_TOKEN=... (Zone:Read + DNS:Edit for esmi.dk). Without the secret Caddy still
      # runs, it just cannot get certificates.
      environmentFile = lib.mkIf hasSecret config.age.secrets.caddy.path;
      globalConfig = ''
        acme_dns cloudflare {env.CF_API_TOKEN}
      '';

      virtualHosts = {
        "esmi.dk".extraConfig = ''
          root * ${./www/esmi.dk}
          file_server
        '';
        "www.esmi.dk".extraConfig = ''
          redir https://esmi.dk{uri}
        '';
        # Gets the wildcard certificate, and answers for names without a site of their own.
        "*.i.esmi.dk".extraConfig = ''
          ${internalOnly}
          respond "Not found" 404
        '';
        # Quick check that Caddy and the internal network path work.
        "homebox.i.esmi.dk".extraConfig = ''
          ${internalOnly}
          respond "Hello, world!"
        '';
      }
      // lib.mapAttrs (_: site: { extraConfig = siteConfig site; }) config.my.proxy;
    };

    age.secrets.caddy = lib.mkIf hasSecret {
      file = secret;
    };

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
