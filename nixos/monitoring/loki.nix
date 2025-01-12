{
  config,
  lib,
  pkgs,
  arcanum,
  ...
}:
with lib;
let
  redis-endpoint = "localpost.${arcanum.internal}:6378";
  s3-endpoint = "https://s3.${arcanum.domain}";
  policy-json = pkgs.writeTextFile {
    name = "policy.json";
    text = ''
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Action": [
              "s3:ListBucket",
              "s3:PutObject",
              "s3:GetObject",
              "s3:DeleteObject"
            ],
            "Resource": [
              "arn:aws:s3:::loki",
              "arn:aws:s3:::loki/*"
            ]
          }
        ]
      }
    '';
  };
in
{
  extraConfig = [
    # minio in another host
    (mkIf config.modules.servers.minio.enable {
      modules.servers.minio.buckets = [
        {
          name = "loki";
          policy = policy-json;
        }
      ];
    })
    # redis cache. no need to backup
    (mkIf config.modules.servers.redis.enable {
      sops.secrets.loki-redis-password = {
        sopsFile = "${arcanum.secretPath}/loki-secrets.yaml";
        owner = "redis-loki";
        group = "redis-loki";
        format = "yaml";
      };
      services.redis.servers.loki = {
        enable = true;
        bind = "0.0.0.0";
        port = 6378;
        openFirewall = false;
        logLevel = "debug";
        requirePassFile = config.sops.secrets.loki-redis-password.path;
      };
      environment.persistence."/persist".directories = singleton {
        directory = "/var/lib/redis-loki";
        user = "redis-loki";
        group = "redis-loki";
        mode = "750";
      };
    })
  ];
  content = {
    sops.secrets.loki-secrets = {
      sopsFile = "${arcanum.secretPath}/loki-secrets.yaml";
      owner = "loki";
      group = "loki";
      format = "yaml";
    };
    systemd.services.loki.serviceConfig.EnvironmentFile = config.sops.secrets.loki-secrets.path;
    services.loki = {
      enable = true;
      extraFlags = [ "--config.expand-env=true" ];
      configuration = {
        server.http_listen_port = 3154;
        analytics.reporting_enabled = false;
        auth_enabled = false;
        common = {
          ring = {
            instance_addr = "127.0.0.1";
            kvstore.store = "inmemory";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };
        ingester = {
          chunk_encoding = "snappy";
          chunk_target_size = 5242880; # 5MiB
          max_chunk_age = "12h";
          chunk_idle_period = "4h";
        };

        querier = {
          query_ingesters_within = "24h"; # double the `max_chunk_age`
          max_concurrent = 2;
        };
        chunk_store_config.chunk_cache_config.redis = {
          endpoint = redis-endpoint;
          timeout = "1000s";
          expiration = "0s";
          password = ''''${REDIS_PASSWORD}'';
        };
        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "15m";
          retention_enabled = true;
          delete_request_store = "aws";
        };
        limits_config = {
          retention_period = "130d";
          max_query_parallelism = 2;
          max_query_series = 2000; # for postfix
          split_instant_metric_queries_by_interval = "10m";
          split_queries_by_interval = "24h";
          max_global_streams_per_user = 0;
          query_timeout = "10m";
        };
        query_range = {
          align_queries_with_step = true;
          cache_index_stats_results = true;
          cache_results = true;
          cache_volume_results = true;
          cache_series_results = true;
          cache_instant_metric_results = true;
          instant_metric_query_split_align = true;

          instant_metric_results_cache.cache.redis = {
            endpoint = redis-endpoint;
            timeout = "1000s";
            password = ''''${REDIS_PASSWORD}'';
          };
          series_results_cache.cache.redis = {
            endpoint = redis-endpoint;
            timeout = "1000s";
            password = ''''${REDIS_PASSWORD}'';
          };
          index_stats_results_cache.cache.redis = {
            endpoint = redis-endpoint;
            timeout = "1000s";
            password = ''''${REDIS_PASSWORD}'';
          };
          results_cache.cache.redis = {
            endpoint = redis-endpoint;
            timeout = "1000s";
            password = ''''${REDIS_PASSWORD}'';
          };
          volume_results_cache.cache.redis = {
            endpoint = redis-endpoint;
            timeout = "1000s";
            password = ''''${REDIS_PASSWORD}'';
          };
        };
        schema_config = {
          configs = [
            {
              from = "2024-12-21";
              store = "tsdb";
              object_store = "s3";
              schema = "v13";
              index = {
                prefix = "index_";
                period = "24h";
              };
            }
          ];
        };
        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/index";
            cache_location = "/var/lib/loki/index_cache";
          };
          aws = {
            endpoint = s3-endpoint;
            bucketnames = "loki";
            region = "us-east-1";
            access_key_id = ''''${MINIO_ACCESS_KEY}'';
            secret_access_key = ''''${MINIO_SECRET_KEY}'';
            s3forcepathstyle = true;
          };
          index_queries_cache_config.redis = {
            endpoint = redis-endpoint;
            timeout = "1000ms";
            password = ''''${REDIS_PASSWORD}'';
          };
        };
      };
    };
  };
  persist.directories = singleton {
    directory = "/var/lib/loki";
    user = "loki";
    group = "loki";
    mode = "0700";
  };
}
