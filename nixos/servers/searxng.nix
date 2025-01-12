{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
{
  extraConfig = [
    # redis cache. no need to backup
    (mkIf config.modules.servers.redis.enable {
      sops.secrets.searxng-redis-password = {
        sopsFile = "${arcanum.secretPath}/searxng-secrets.yaml";
        owner = "redis-searxng";
        group = "redis-searxng";
        format = "yaml";
      };
      services.redis.servers.searxng = {
        enable = true;
        openFirewall = false;
        port = 6420;
        bind = "0.0.0.0";
        databases = 16;
        logLevel = "debug";
        requirePassFile = config.sops.secrets.searxng-redis-password.path;
      };
      environment.persistence."/persist".directories = singleton {
        directory = "/var/lib/redis-searxng";
        user = "redis-searxng";
        group = "redis-searxng";
        mode = "750";
      };
    })
  ];
  content = {
    sops.secrets.searxng-secrets = {
      sopsFile = "${arcanum.secretPath}/searxng-secrets.yaml";
      format = "yaml";
      owner = "searx";
      group = "searx";
    };
    services.searx = {
      enable = true;
      package = pkgs.searxng.overrideAttrs (
        oldAttrs:
        let
          logo = pkgs.fetchurl {
            url = "https://cdn.discordapp.com/emojis/932325302108053525.webp";
            sha256 = "0i2psqmjxigpbvqy6g7dvln66jv62pqy9g77zp8li05qq5d04jhx";
          };
        in
        {
          postInstall = lib.strings.concatStrings [
            oldAttrs.postInstall
            # bash
            ''
              # Replace logo
              cp ${logo} $out/${pkgs.python3.sitePackages}/searx/static/themes/simple/img/searxng.png
            ''
          ];
        }
      );
      runInUwsgi = true;
      uwsgiConfig = {
        http = ":8420";
      };
      # includes redis endpoint
      environmentFile = config.sops.secrets.searxng-secrets.path;
      settings = {
        general = {
          instance_name = "Search";
          debug = false;
          privacypolicy_url = false;
          donation_url = false;
          contact_url = false;
          enable_metrics = true;
        };
        ui = {
          query_in_title = true;
          results_on_new_tab = false;
          theme_args.simple_style = "black";
          infinite_scroll = true;
          static_use_hash = true;
        };
        favicons = {
          cfg_schema = 1;
          cache = {
            db_url = "/var/cache/searxng/faviconcache.db";
            LIMIT_TOTAL_BYTES = 2147483648; # 2 GB / default: 50 MB
            HOLD_TIME = 5184000; # 60 days / default: 30 days
            BLOB_MAX_BYTES = 40960; # 40 KB / default 20 KB
          };
        };
        search = {
          safe_search = 0;
          autocomplete = "google";
          favicon_resolver = "google";
          formats = [
            "html"
            "json"
          ];
        };
        engines = lib.mapAttrsToList (name: value: { inherit name; } // value) {
          "duckduckgo".disabled = false;
          "brave".disabled = true;
          "bing".disabled = false;
          "startpage".disabled = false;
          "mojeek".disabled = false;
          "mwmbl".disabled = false;
          "mwmbl".weight = 0.2;
          "qwant".disabled = true;
          "crowdview".disabled = false;
          "crowdview".weight = 0.5;
          "curlie".disabled = true;
          "ddg definitions".disabled = false;
          "ddg definitions".weight = 2;
          "wikibooks".disabled = false;
          "wikidata".disabled = false;
          "wikiquote".disabled = true;
          "wikisource".disabled = true;
          "wikispecies".disabled = true;
          "wikiversity".disabled = true;
          "wikivoyage".disabled = true;
          "currency".disabled = true;
          "dictzone".disabled = true;
          "lingva".disabled = true;
          "bing images".disabled = false;
          "brave.images".disabled = true;
          "duckduckgo images".disabled = true;
          "google images".disabled = false;
          "qwant images".disabled = true;
          "1x".disabled = true;
          "artic".disabled = false;
          "deviantart".disabled = false;
          "flickr".disabled = true;
          "frinklac".disabled = false;
          "imgur".disabled = false;
          "library of congress".disabled = false;
          "material icons".disabled = true;
          "material icons".weight = 0.2;
          "openverse".disabled = false;
          "pinterest".disabled = true;
          "svgrepo".disabled = false;
          "unsplash".disabled = false;
          "wallhaven".disabled = false;
          "wikicommons.images".disabled = false;
          "yacy images".disabled = true;
          "seekr images (EN)".disabled = true;
          "bing videos".disabled = false;
          "brave.videos".disabled = true;
          "duckduckgo videos".disabled = true;
          "google videos".disabled = false;
          "qwant videos".disabled = false;
          "bilibili".disabled = false;
          "ccc-tv".disabled = true;
          "dailymotion".disabled = true;
          "google play movies".disabled = true;
          "invidious".disabled = true;
          "odysee".disabled = true;
          "peertube".disabled = false;
          "piped".disabled = true;
          "rumble".disabled = false;
          "sepiasearch".disabled = false;
          "vimeo".disabled = true;
          "youtube".disabled = false;
          "mediathekviewweb (DE)".disabled = true;
          "seekr videos (EN)".disabled = true;
          "ina (FR)".disabled = true;
          "brave.news".disabled = true;
          "google news".disabled = true;
          "apple maps".disabled = false;
          "piped.music".disabled = true;
          "radio browser".disabled = true;
          "codeberg".disabled = true;
          "gitlab".disabled = false;
          "internetarchivescholar".disabled = true;
          "pdbe".disabled = true;
        };
        outgoing = {
          request_timeout = 1.2; # the maximum timeout in seconds
          max_request_timeout = 1.2; # the maximum timeout in seconds
          keepalive_expiry = 10.0;
          pool_connections = 100; # Maximum number of allowable connections, or null
          pool_maxsize = 10; # Number of allowable keep-alive connections, or null
          enable_http2 = true; # See https://www.python-httpx.org/http2/
          proxies."all://" = singleton "socks5h://127.0.0.1:9050";
          using_tor_proxy = true;
        };
        server = {
          port = 8420;
          bind_address = "0.0.0.0";
          secret_key = "@SEARXNG_SECRET@";
          base_url = "https://search.${arcanum.domain}";
          public_instance = false;
          image_proxy = true;
          default_locale = "en";
          method = "GET";
        };
        enabled_plugins = [
          "Basic Calculator"
          "Hash plugin"
          "Hostnames plugin"
          "Open Access DOI rewrite"
          "Self Information"
          "Tor check plugin"
          "Tracker URL remover"
          "Unit converter plugin"
        ];
        hostnames = {
          replace = {
            "(.*\.)?twitter\.com$" = "xcancel.com";
            "(.*\.)?x\.com$" = "xcancel.com";
            "(.*\.)?tiktok\.com$" = "sticktock.com";
          };
          remove = [
            "(.*\.)?pinterest\.com$"
            "(.*\.)?pinterest\.co.uk$"
            "(.*\.)?pinterest\.de$"
            "(.*\.)?pinterest\.ca$"
            "(.*\.)?pinterest\.fr$"
            "(.*\.)?pinterest\.com.au$"
            "(.*\.)?pinterest\.es$"
            "(.*\.)?foxnews\.com$"
            "(.*\.)?breitbart\.com$"
            "(.*\.)?facebook\.com$"
          ];
          low_priority = [
            "(.*\.)?quora\.com$"
            "(.*\.)?dailymail\.co.uk$"
            "(.*\.)?msn\.com$"
            "(.*\.)?togetter\.com$"
            "(.*\.)?play\.google\.com$"
            "(.*\.)?etsy\.com$"
          ];
          high_priority = [
            "(.*\.)?github\.com$"
            "(.*\.)?reddit\.com$"
            "(.*\.)?stackoverflow\.com$"
            "(.*\.)?stackexchange\.com$"
            "(.*\.)?ymcombinator\.com$"
            "(.*\.)?mozilla\.org$"
            "(.*\.)?wikipedia\.org$"
            "(.*\.)?archlinux\.org$"
            "(.*\.)?nixos\.org$"
            "(.*\.)?superuser\.com$"
            "(.*\.)?python\.org$"
            "(.*\.)?gitlab\.com$"
            "(.*\.)?serverfault\.com$"
            "(.*\.)?steampowered\.com$"
            "(.*\.)?nih\.gov$"
            "(.*\.)?rust-lang\.org$"
            "(.*\.)?docs\.rs$"
            "(.*\.)?postgresql\.org$"
            "(.*\.)?seriouseats\.com$"
            "(.*\.)?css-tricks\.com$"
            "(.*\.)?archive\.org$"
            "(.*\.)?developer\.apple\.com$"
            "(.*\.)?learn\.microsoft\.com$"
            "(.*\.)?wiktionary\.org$"
            "(.*\.)?askubuntu\.com$"
            "(.*\.)?docs\.aws\.amazon\.com$"
            "(.*\.)?support\.apple\.com$"
            "(.*\.)?docs\.microsoft\.com$"
            "(.*\.)?npmjs\.com$"
          ];
        };
      };
    };
  };
  persist.directories = singleton {
    directory = "/var/cache/searxng";
    mode = "0750";
    user = "searx";
    group = "searx";
  };
}
