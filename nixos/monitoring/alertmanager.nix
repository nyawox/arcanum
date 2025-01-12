{
  config,
  lib,
  arcanum,
  ...
}:
with lib;
let
  # TODO: HA Cluster
  port = 9844;
in
{
  content = {
    arcanum.sysUsers = [ "alertmanager" ];
    sops.secrets.alertmanager-env = {
      sopsFile = "${arcanum.secretPath}/alertmanager-secrets.yaml";
      owner = "alertmanager";
      group = "alertmanager";
      format = "yaml";
      restartUnits = [ "alertmanager.service" ];
    };
    services.prometheus = {
      alertmanagers = singleton {
        scheme = "http";
        path_prefix = "/";
        static_configs = singleton {
          targets = singleton "localpost.${arcanum.internal}:${toString port}";
        };
      };
      alertmanager = {
        enable = true;
        environmentFile = config.sops.secrets.alertmanager-env.path;
        listenAddress = "0.0.0.0";
        webExternalUrl = "https://alerts.${arcanum.domain}";
        inherit port;
        configuration = {
          route = {
            group_by = [
              "alertname"
              "alias"
            ];
            group_wait = "30s";
            group_interval = "5m";
            repeat_interval = "6h";
            receiver = "email";
            routes = singleton {
              receiver = "pushover";
              matchers = [ ''severity="critical"'' ];
            };
          };
          receivers = [
            {
              name = "email";
              email_configs = singleton {
                to = "$EMAIL_DEST";
                from = "notifications@${arcanum.domain}";
                smarthost = "mail.${arcanum.domain}:587";
                send_resolved = true;
                auth_username = "notifications@${arcanum.domain}";
                auth_password = "$EMAIL_PWD";
                require_tls = true;
              };
            }
            {
              name = "pushover";
              pushover_configs = singleton {
                user_key = "$PUSHOVER_KEY";
                token = "$PUSHOVER_TOKEN";
                sound = "ding";
                send_resolved = true;
              };
            }
          ];
        };
      };
      # borrowed from https://samber.github.io/awesome-prometheus-alerts/rules.htm
      rules = [
        (builtins.toJSON {
          groups = [
            # ██████╗░██████╗░░█████╗░███╗░░░███╗███████╗████████╗██╗░░██╗███████╗██╗░░░██╗░██████╗
            # ██╔══██╗██╔══██╗██╔══██╗████╗░████║██╔════╝╚══██╔══╝██║░░██║██╔════╝██║░░░██║██╔════╝
            # ██████╔╝██████╔╝██║░░██║██╔████╔██║█████╗░░░░░██║░░░███████║█████╗░░██║░░░██║╚█████╗░
            # ██╔═══╝░██╔══██╗██║░░██║██║╚██╔╝██║██╔══╝░░░░░██║░░░██╔══██║██╔══╝░░██║░░░██║░╚═══██╗
            # ██║░░░░░██║░░██║╚█████╔╝██║░╚═╝░██║███████╗░░░██║░░░██║░░██║███████╗╚██████╔╝██████╔╝
            # ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═╝╚══════╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝░╚═════╝░╚═════╝░
            {
              name = "Prometheus";
              rules = [
                {
                  alert = "PrometheusJobMissing";
                  expr = "absent(up{job=\"prometheus\"})";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus job missing (instance {{ $labels.instance }})";
                    description = "A Prometheus job has disappeared\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTargetMissing";
                  expr = "up == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus target missing (instance {{ $labels.instance }})";
                    description = "A Prometheus target has disappeared. An exporter might be crashed.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusAllTargetsMissing";
                  expr = "sum by (job) (up) == 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus all targets missing (instance {{ $labels.instance }})";
                    description = "A Prometheus job does not have living target anymore.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTargetMissingWithWarmupTime";
                  expr = "sum by (instance, job) ((up == 0) * on (instance) group_right(job) (node_time_seconds - node_boot_time_seconds > 600))";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus target missing with warmup time (instance {{ $labels.instance }})";
                    description = "Allow a job time to start up (10 minutes) before alerting that it's down.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusConfigurationReloadFailure";
                  expr = "prometheus_config_last_reload_successful != 1";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus configuration reload failure (instance {{ $labels.instance }})";
                    description = "Prometheus configuration reload error\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTooManyRestarts";
                  expr = "changes(process_start_time_seconds{job=~\"prometheus|pushgateway|alertmanager\"}[15m]) > 2";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus too many restarts (instance {{ $labels.instance }})";
                    description = "Prometheus has restarted more than twice in the last 15 minutes. It might be crashlooping.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusAlertmanagerJobMissing";
                  expr = "absent(up{job=\"alertmanager\"})";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus AlertManager job missing (instance {{ $labels.instance }})";
                    description = "A Prometheus AlertManager job has disappeared\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusAlertmanagerConfigurationReloadFailure";
                  expr = "alertmanager_config_last_reload_successful != 1";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus AlertManager configuration reload failure (instance {{ $labels.instance }})";
                    description = "AlertManager configuration reload error\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusAlertmanagerConfigNotSynced";
                  expr = "count(count_values(\"config_hash\", alertmanager_config_hash)) > 1";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus AlertManager config not synced (instance {{ $labels.instance }})";
                    description = "Configurations of AlertManager cluster instances are out of sync\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusNotConnectedToAlertmanager";
                  expr = "prometheus_notifications_alertmanagers_discovered < 1";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus not connected to alertmanager (instance {{ $labels.instance }})";
                    description = "Prometheus cannot connect the alertmanager\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusRuleEvaluationFailures";
                  expr = "increase(prometheus_rule_evaluation_failures_total[3m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus rule evaluation failures (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} rule evaluation failures, leading to potentially ignored alerts.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTemplateTextExpansionFailures";
                  expr = "increase(prometheus_template_text_expansion_failures_total[3m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus template text expansion failures (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} template text expansion failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusRuleEvaluationSlow";
                  expr = "prometheus_rule_group_last_duration_seconds > prometheus_rule_group_interval_seconds";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus rule evaluation slow (instance {{ $labels.instance }})";
                    description = "Prometheus rule evaluation took more time than the scheduled interval. It indicates a slower storage backend access or too complex query.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusNotificationsBacklog";
                  expr = "min_over_time(prometheus_notifications_queue_length[10m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus notifications backlog (instance {{ $labels.instance }})";
                    description = "The Prometheus notification queue has not been empty for 10 minutes\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusAlertmanagerNotificationFailing";
                  expr = "rate(alertmanager_notifications_failed_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus AlertManager notification failing (instance {{ $labels.instance }})";
                    description = "Alertmanager is failing sending notifications\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTargetEmpty";
                  expr = "prometheus_sd_discovered_targets == 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus target empty (instance {{ $labels.instance }})";
                    description = "Prometheus has no target in service discovery\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTargetScrapingSlow";
                  expr = "prometheus_target_interval_length_seconds{quantile=\"0.9\"} / on (interval, instance, job) prometheus_target_interval_length_seconds{quantile=\"0.5\"} > 1.05";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus target scraping slow (instance {{ $labels.instance }})";
                    description = "Prometheus is scraping exporters slowly since it exceeded the requested interval time. Your Prometheus server is under-provisioned.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusLargeScrape";
                  expr = "increase(prometheus_target_scrapes_exceeded_sample_limit_total[10m]) > 10";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus large scrape (instance {{ $labels.instance }})";
                    description = "Prometheus has many scrapes that exceed the sample limit\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTargetScrapeDuplicate";
                  expr = "increase(prometheus_target_scrapes_sample_duplicate_timestamp_total[5m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus target scrape duplicate (instance {{ $labels.instance }})";
                    description = "Prometheus has many samples rejected due to duplicate timestamps but different values\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbCheckpointCreationFailures";
                  expr = "increase(prometheus_tsdb_checkpoint_creations_failed_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB checkpoint creation failures (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} checkpoint creation failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbCheckpointDeletionFailures";
                  expr = "increase(prometheus_tsdb_checkpoint_deletions_failed_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB checkpoint deletion failures (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} checkpoint deletion failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbCompactionsFailed";
                  expr = "increase(prometheus_tsdb_compactions_failed_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB compactions failed (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} TSDB compactions failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbHeadTruncationsFailed";
                  expr = "increase(prometheus_tsdb_head_truncations_failed_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB head truncations failed (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} TSDB head truncation failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbReloadFailures";
                  expr = "increase(prometheus_tsdb_reloads_failures_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB reload failures (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} TSDB reload failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbWalCorruptions";
                  expr = "increase(prometheus_tsdb_wal_corruptions_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB WAL corruptions (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} TSDB WAL corruptions\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTsdbWalTruncationsFailed";
                  expr = "increase(prometheus_tsdb_wal_truncations_failed_total[1m]) > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Prometheus TSDB WAL truncations failed (instance {{ $labels.instance }})";
                    description = "Prometheus encountered {{ $value }} TSDB WAL truncation failures\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PrometheusTimeseriesCardinality";
                  expr = "label_replace(count by(__name__) ({__name__=~\".+\"}), \"name\", \"$1\", \"__name__\", \"(.+)\") > 10000";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Prometheus timeseries cardinality (instance {{ $labels.instance }})";
                    description = "The \"{{ $labels.name }}\" timeseries cardinality is getting very high: {{ $value }}\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
              ];
            }
            # ███╗░░██╗░█████╗░██████╗░███████╗  ███████╗██╗░░██╗██████╗░░█████╗░██████╗░████████╗███████╗██████╗░
            # ████╗░██║██╔══██╗██╔══██╗██╔════╝  ██╔════╝╚██╗██╔╝██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗
            # ██╔██╗██║██║░░██║██║░░██║█████╗░░  █████╗░░░╚███╔╝░██████╔╝██║░░██║██████╔╝░░░██║░░░█████╗░░██████╔╝
            # ██║╚████║██║░░██║██║░░██║██╔══╝░░  ██╔══╝░░░██╔██╗░██╔═══╝░██║░░██║██╔══██╗░░░██║░░░██╔══╝░░██╔══██╗
            # ██║░╚███║╚█████╔╝██████╔╝███████╗  ███████╗██╔╝╚██╗██║░░░░░╚█████╔╝██║░░██║░░░██║░░░███████╗██║░░██║
            # ╚═╝░░╚══╝░╚════╝░╚═════╝░╚══════╝  ╚══════╝╚═╝░░╚═╝╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝
            {
              name = "node";
              rules = [
                {
                  alert = "HostDown";
                  expr = "up{job=\"nodes\"} == 0";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "({{ $labels.instance }}) is down";
                    description = "The host {{ $labels.instance }} is down for more than 5 minutes..";
                  };
                }
                {
                  alert = "HostOutOfMemory";
                  expr = "(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100 < 10) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host out of memory (instance {{ $labels.instance }})";
                    description = "Node memory is filling up (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostMemoryUnderMemoryPressure";
                  expr = "(rate(node_vmstat_pgmajfault[1m]) > 1000) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host memory under memory pressure (instance {{ $labels.instance }})";
                    description = "The node is under heavy memory pressure. High rate of major page faults\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostMemoryIsUnderutilized";
                  expr = "(100 - (avg_over_time(node_memory_MemAvailable_bytes[30m]) / node_memory_MemTotal_bytes * 100) < 20) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "1w";
                  labels = {
                    severity = "info";
                  };
                  annotations = {
                    summary = "Host Memory is underutilized (instance {{ $labels.instance }})";
                    description = "Node memory is < 20% for 1 week. Consider reducing memory space. (instance {{ $labels.instance }})\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualNetworkThroughputIn";
                  expr = "(sum by (instance) (rate(node_network_receive_bytes_total[2m])) / 1024 / 1024 > 100) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual network throughput in (instance {{ $labels.instance }})";
                    description = "Host network interfaces are probably receiving too much data (> 100 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualNetworkThroughputOut";
                  expr = "(sum by (instance) (rate(node_network_transmit_bytes_total[2m])) / 1024 / 1024 > 100) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual network throughput out (instance {{ $labels.instance }})";
                    description = "Host network interfaces are probably sending too much data (> 100 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualDiskReadRate";
                  expr = "(sum by (instance) (rate(node_disk_read_bytes_total[2m])) / 1024 / 1024 > 50) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual disk read rate (instance {{ $labels.instance }})";
                    description = "Disk is probably reading too much data (> 50 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualDiskWriteRate";
                  expr = "(sum by (instance) (rate(node_disk_written_bytes_total[2m])) / 1024 / 1024 > 50) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual disk write rate (instance {{ $labels.instance }})";
                    description = "Disk is probably writing too much data (> 50 MB/s)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostOutOfDiskSpace";
                  expr = "((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) node_filesystem_readonly == 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host out of disk space (instance {{ $labels.instance }})";
                    description = "Disk is almost full (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostDiskWillFillIn24Hours";
                  expr = "((node_filesystem_avail_bytes * 100) / node_filesystem_size_bytes < 10 and ON (instance, device, mountpoint) predict_linear(node_filesystem_avail_bytes{fstype!~\"tmpfs\"}[1h], 24 * 3600) < 0 and ON (instance, device, mountpoint) node_filesystem_readonly == 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host disk will fill in 24 hours (instance {{ $labels.instance }})";
                    description = "Filesystem is predicted to run out of space within the next 24 hours at current write rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostOutOfInodes";
                  expr = "(node_filesystem_files_free{fstype!=\"msdosfs\"} / node_filesystem_files{fstype!=\"msdosfs\"} * 100 < 10 and ON (instance, device, mountpoint) node_filesystem_readonly == 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host out of inodes (instance {{ $labels.instance }})";
                    description = "Disk is almost running out of available inodes (< 10% left)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostFilesystemDeviceError";
                  expr = "node_filesystem_device_error == 1";
                  for = "5m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Host filesystem device error (instance {{ $labels.instance }})";
                    description = "{{ $labels.instance }}: Device error with the {{ $labels.mountpoint }} filesystem\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostInodesWillFillIn24Hours";
                  expr = "(node_filesystem_files_free{fstype!=\"msdosfs\"} / node_filesystem_files{fstype!=\"msdosfs\"} * 100 < 10 and predict_linear(node_filesystem_files_free{fstype!=\"msdosfs\"}[1h], 24 * 3600) < 0 and ON (instance, device, mountpoint) node_filesystem_readonly{fstype!=\"msdosfs\"} == 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host inodes will fill in 24 hours (instance {{ $labels.instance }})";
                    description = "Filesystem is predicted to run out of inodes within the next 24 hours at current write rate\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualDiskReadLatency";
                  expr = "(rate(node_disk_read_time_seconds_total[1m]) / rate(node_disk_reads_completed_total[1m]) > 0.1 and rate(node_disk_reads_completed_total[1m]) > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual disk read latency (instance {{ $labels.instance }})";
                    description = "Disk latency is growing (read operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualDiskWriteLatency";
                  expr = "(rate(node_disk_write_time_seconds_total[1m]) / rate(node_disk_writes_completed_total[1m]) > 0.1 and rate(node_disk_writes_completed_total[1m]) > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual disk write latency (instance {{ $labels.instance }})";
                    description = "Disk latency is growing (write operations > 100ms)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostHighCpuLoad";
                  expr = "(sum by (instance) (avg by (mode, instance) (rate(node_cpu_seconds_total{mode!=\"idle\"}[2m]))) > 0.8) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host high CPU load (instance {{ $labels.instance }})";
                    description = "CPU load is > 80%\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostCpuStealNoisyNeighbor";
                  expr = "(avg by(instance) (rate(node_cpu_seconds_total{mode=\"steal\"}[5m])) * 100 > 10) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host CPU steal noisy neighbor (instance {{ $labels.instance }})";
                    description = "CPU steal is > 10%. A noisy neighbor is killing VM performances or a spot instance may be out of credit.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostCpuHighIowait";
                  expr = "(avg by (instance) (rate(node_cpu_seconds_total{mode=\"iowait\"}[5m])) * 100 > 10) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host CPU high iowait (instance {{ $labels.instance }})";
                    description = "CPU iowait > 10%. A high iowait means that you are disk or network bound.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostUnusualDiskIo";
                  expr = "(rate(node_disk_io_time_seconds_total[1m]) > 0.5) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host unusual disk IO (instance {{ $labels.instance }})";
                    description = "Time spent in IO is too high on {{ $labels.instance }}. Check storage for issues.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostSwapIsFillingUp";
                  expr = "((1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100 > 80) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host swap is filling up (instance {{ $labels.instance }})";
                    description = "Swap is filling up (>80%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostSystemdServiceCrashed";
                  expr = "(node_systemd_unit_state{state=\"failed\"} == 1) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host systemd service crashed (instance {{ $labels.instance }})";
                    description = "systemd service crashed\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostPhysicalComponentTooHot";
                  expr = "((node_hwmon_temp_celsius * ignoring(label) group_left(instance, job, node, sensor) node_hwmon_sensor_label{label!=\"tctl\"} > 75)) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host physical component too hot (instance {{ $labels.instance }})";
                    description = "Physical hardware component too hot\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostNodeOvertemperatureAlarm";
                  expr = "((node_hwmon_temp_crit_alarm_celsius == 1) or (node_hwmon_temp_alarm == 1)) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Host node overtemperature alarm (instance {{ $labels.instance }})";
                    description = "Physical node temperature alarm triggered\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostRaidArrayGotInactive";
                  expr = "(node_md_state{state=\"inactive\"} > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Host RAID array got inactive (instance {{ $labels.instance }})";
                    description = "RAID array {{ $labels.device }} is in a degraded state due to one or more disk failures. The number of spare drives is insufficient to fix the issue automatically.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostRaidDiskFailure";
                  expr = "(node_md_disks{state=\"failed\"} > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host RAID disk failure (instance {{ $labels.instance }})";
                    description = "At least one device in RAID array on {{ $labels.instance }} failed. Array {{ $labels.md_device }} needs attention and possibly a disk swap\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostKernelVersionDeviations";
                  expr = "(count(sum(label_replace(node_uname_info, \"kernel\", \"$1\", \"release\", \"([0-9]+.[0-9]+.[0-9]+).*\")) by (kernel)) > 1) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "6h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host kernel version deviations (instance {{ $labels.instance }})";
                    description = "Different kernel versions are running\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostOomKillDetected";
                  expr = "(increase(node_vmstat_oom_kill[1m]) > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host OOM kill detected (instance {{ $labels.instance }})";
                    description = "OOM kill detected\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostEdacCorrectableErrorsDetected";
                  expr = "(increase(node_edac_correctable_errors_total[1m]) > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "info";
                  };
                  annotations = {
                    summary = "Host EDAC Correctable Errors detected (instance {{ $labels.instance }})";
                    description = "Host {{ $labels.instance }} has had {{ printf \"%.0f\" $value }} correctable memory errors reported by EDAC in the last 5 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostEdacUncorrectableErrorsDetected";
                  expr = "(node_edac_uncorrectable_errors_total > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host EDAC Uncorrectable Errors detected (instance {{ $labels.instance }})";
                    description = "Host {{ $labels.instance }} has had {{ printf \"%.0f\" $value }} uncorrectable memory errors reported by EDAC in the last 5 minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostNetworkReceiveErrors";
                  expr = "(rate(node_network_receive_errs_total[2m]) / rate(node_network_receive_packets_total[2m]) > 0.01) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host Network Receive Errors (instance {{ $labels.instance }})";
                    description = "Host {{ $labels.instance }} interface {{ $labels.device }} has encountered {{ printf \"%.0f\" $value }} receive errors in the last two minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostNetworkTransmitErrors";
                  expr = "(rate(node_network_transmit_errs_total[2m]) / rate(node_network_transmit_packets_total[2m]) > 0.01) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host Network Transmit Errors (instance {{ $labels.instance }})";
                    description = "Host {{ $labels.instance }} interface {{ $labels.device }} has encountered {{ printf \"%.0f\" $value }} transmit errors in the last two minutes.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostNetworkInterfaceSaturated";
                  expr = "((rate(node_network_receive_bytes_total{device!~\"^tap.*|^vnet.*|^veth.*|^tun.*\"}[1m]) + rate(node_network_transmit_bytes_total{device!~\"^tap.*|^vnet.*|^veth.*|^tun.*\"}[1m])) / node_network_speed_bytes{device!~\"^tap.*|^vnet.*|^veth.*|^tun.*\"} > 0.8 < 10000) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "1m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host Network Interface Saturated (instance {{ $labels.instance }})";
                    description = "The network interface \"{{ $labels.device }}\" on \"{{ $labels.instance }}\" is getting overloaded.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostNetworkBondDegraded";
                  expr = "((node_bonding_active - node_bonding_slaves) != 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host Network Bond Degraded (instance {{ $labels.instance }})";
                    description = "Bond \"{{ $labels.device }}\" degraded on \"{{ $labels.instance }}\".\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostConntrackLimit";
                  expr = "(node_nf_conntrack_entries / node_nf_conntrack_entries_limit > 0.8) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "5m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host conntrack limit (instance {{ $labels.instance }})";
                    description = "The number of conntrack is approaching limit\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostClockSkew";
                  expr = "((node_timex_offset_seconds > 0.05 and deriv(node_timex_offset_seconds[5m]) >= 0) or (node_timex_offset_seconds < -0.05 and deriv(node_timex_offset_seconds[5m]) <= 0)) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "10m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Host clock skew (instance {{ $labels.instance }})";
                    description = "Clock skew detected. Clock is out of sync. Ensure NTP is configured correctly on this host.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "HostRequiresReboot";
                  expr = "(node_reboot_required > 0) * on(instance) group_left (nodename) node_uname_info{nodename=~\".+\"}";
                  for = "4h";
                  labels = {
                    severity = "info";
                  };
                  annotations = {
                    summary = "Host requires reboot (instance {{ $labels.instance }})";
                    description = "{{ $labels.instance }} requires a reboot.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
              ];
            }
            # ██████╗░░█████╗░░██████╗████████╗░██████╗░██████╗░███████╗░██████╗░██████╗░██╗░░░░░
            # ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝░██╔══██╗██╔════╝██╔════╝██╔═══██╗██║░░░░░
            # ██████╔╝██║░░██║╚█████╗░░░░██║░░░██║░░██╗░██████╔╝█████╗░░╚█████╗░██║██╗██║██║░░░░░
            # ██╔═══╝░██║░░██║░╚═══██╗░░░██║░░░██║░░╚██╗██╔══██╗██╔══╝░░░╚═══██╗╚██████╔╝██║░░░░░
            # ██║░░░░░╚█████╔╝██████╔╝░░░██║░░░╚██████╔╝██║░░██║███████╗██████╔╝░╚═██╔═╝░███████╗
            # ╚═╝░░░░░░╚════╝░╚═════╝░░░░╚═╝░░░░╚═════╝░╚═╝░░╚═╝╚══════╝╚═════╝░░░░╚═╝░░░╚══════╝
            {
              name = "PostgresExporter";
              rules = [
                {
                  alert = "PostgresqlDown";
                  expr = "pg_up == 0";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql down (instance {{ $labels.instance }})";
                    description = "Postgresql instance is down\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlRestarted";
                  expr = "time() - pg_postmaster_start_time_seconds < 60";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql restarted (instance {{ $labels.instance }})";
                    description = "Postgresql restarted\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlExporterError";
                  expr = "pg_exporter_last_scrape_error > 0";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql exporter error (instance {{ $labels.instance }})";
                    description = "Postgresql exporter is showing errors. A query may be buggy in query.yaml\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlTableNotAutoVacuumed";
                  expr = "(pg_stat_user_tables_last_autovacuum > 0) and (time() - pg_stat_user_tables_last_autovacuum) > 60 * 60 * 24 * 10";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql table not auto vacuumed (instance {{ $labels.instance }})";
                    description = "Table {{ $labels.relname }} has not been auto vacuumed for 10 days\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlTableNotAutoAnalyzed";
                  expr = "(pg_stat_user_tables_last_autoanalyze > 0) and (time() - pg_stat_user_tables_last_autoanalyze) > 24 * 60 * 60 * 10";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql table not auto analyzed (instance {{ $labels.instance }})";
                    description = "Table {{ $labels.relname }} has not been auto analyzed for 10 days\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlTooManyConnections";
                  expr = "sum by (instance, job, server) (pg_stat_activity_count) > min by (instance, job, server) (pg_settings_max_connections * 0.8)";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql too many connections (instance {{ $labels.instance }})";
                    description = "PostgreSQL instance has too many connections (> 80%).\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlDeadLocks";
                  expr = "increase(pg_stat_database_deadlocks{datname!~\"template.*|postgres\"}[1m]) > 5";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql dead locks (instance {{ $labels.instance }})";
                    description = "PostgreSQL has dead-locks\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlHighRollbackRate";
                  expr = "sum by (namespace,datname) ((rate(pg_stat_database_xact_rollback{datname!~\"template.*|postgres\",datid!=\"0\"}[3m])) / ((rate(pg_stat_database_xact_rollback{datname!~\"template.*|postgres\",datid!=\"0\"}[3m])) + (rate(pg_stat_database_xact_commit{datname!~\"template.*|postgres\",datid!=\"0\"}[3m])))) > 0.02";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql high rollback rate (instance {{ $labels.instance }})";
                    description = "Ratio of transactions being aborted compared to committed is > 2 %\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlCommitRateLow";
                  expr = "rate(pg_stat_database_xact_commit[1m]) < 10";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql commit rate low (instance {{ $labels.instance }})";
                    description = "Postgresql seems to be processing very few transactions\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlLowXidConsumption";
                  expr = "rate(pg_txid_current[1m]) < 5";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql low XID consumption (instance {{ $labels.instance }})";
                    description = "Postgresql seems to be consuming transaction IDs very slowly\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlHighRateStatementTimeout";
                  expr = "rate(postgresql_errors_total{type=\"statement_timeout\"}[1m]) > 3";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql high rate statement timeout (instance {{ $labels.instance }})";
                    description = "Postgres transactions showing high rate of statement timeouts\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlHighRateDeadlock";
                  expr = "increase(postgresql_errors_total{type=\"deadlock_detected\"}[1m]) > 1";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql high rate deadlock (instance {{ $labels.instance }})";
                    description = "Postgres detected deadlocks\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlUnusedReplicationSlot";
                  expr = "pg_replication_slots_active == 0";
                  for = "1m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql unused replication slot (instance {{ $labels.instance }})";
                    description = "Unused Replication Slots\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlTooManyDeadTuples";
                  expr = "((pg_stat_user_tables_n_dead_tup > 10000) / (pg_stat_user_tables_n_live_tup + pg_stat_user_tables_n_dead_tup)) >= 0.1";
                  for = "2m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql too many dead tuples (instance {{ $labels.instance }})";
                    description = "PostgreSQL dead tuples is too large\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlConfigurationChanged";
                  expr = "{__name__=~\"pg_settings_.*\"} != ON(__name__, instance) {__name__=~\"pg_settings_([^t]|t[^r]|tr[^a]|tra[^n]|tran[^s]|trans[^a]|transa[^c]|transac[^t]|transact[^i]|transacti[^o]|transactio[^n]|transaction[^_]|transaction_[^r]|transaction_r[^e]|transaction_re[^a]|transaction_rea[^d]|transaction_read[^_]|transaction_read_[^o]|transaction_read_o[^n]|transaction_read_on[^l]|transaction_read_onl[^y]).*\"} OFFSET 5m";
                  for = "0m";
                  labels = {
                    severity = "info";
                  };
                  annotations = {
                    summary = "Postgresql configuration changed (instance {{ $labels.instance }})";
                    description = "Postgres Database configuration change has occurred\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlSslCompressionActive";
                  expr = "sum(pg_stat_ssl_compression) > 0";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql SSL compression active (instance {{ $labels.instance }})";
                    description = "Database connections with SSL compression enabled. This may add significant jitter in replication delay. Replicas should turn off SSL compression via `sslcompression=0` in `recovery.conf`.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlTooManyLocksAcquired";
                  expr = "((sum (pg_locks_count)) / (pg_settings_max_locks_per_transaction * pg_settings_max_connections)) > 0.20";
                  for = "2m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Postgresql too many locks acquired (instance {{ $labels.instance }})";
                    description = "Too many locks acquired on the database. If this alert happens frequently, we may need to increase the postgres setting max_locks_per_transaction.\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlBloatIndexHigh(>80%)";
                  expr = "pg_bloat_btree_bloat_pct > 80 and on (idxname) (pg_bloat_btree_real_size > 100000000)";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql bloat index high (> 80%) (instance {{ $labels.instance }})";
                    description = "The index {{ $labels.idxname }} is bloated. You should execute `REINDEX INDEX CONCURRENTLY {{ $labels.idxname }};`\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlBloatTableHigh(>80%)";
                  expr = "pg_bloat_table_bloat_pct > 80 and on (relname) (pg_bloat_table_real_size > 200000000)";
                  for = "1h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql bloat table high (> 80%) (instance {{ $labels.instance }})";
                    description = "The table {{ $labels.relname }} is bloated. You should execute `VACUUM {{ $labels.relname }};`\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "PostgresqlInvalidIndex";
                  expr = "pg_general_index_info_pg_relation_size{indexrelname=~\".*ccnew.*\"}";
                  for = "6h";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Postgresql invalid index (instance {{ $labels.instance }})";
                    description = "The table {{ $labels.relname }} has an invalid index: {{ $labels.indexrelname }}. You should execute `DROP INDEX {{ $labels.indexrelname }};`\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
              ];
            }
            # ███╗░░░███╗██╗███╗░░██╗██╗░█████╗░
            # ████╗░████║██║████╗░██║██║██╔══██╗
            # ██╔████╔██║██║██╔██╗██║██║██║░░██║
            # ██║╚██╔╝██║██║██║╚████║██║██║░░██║
            # ██║░╚═╝░██║██║██║░╚███║██║╚█████╔╝
            # ╚═╝░░░░░╚═╝╚═╝╚═╝░░╚══╝╚═╝░╚════╝░
            {
              name = "Minio";
              rules = [
                {
                  alert = "MinioClusterDiskOffline";
                  expr = "minio_cluster_drive_offline_total > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Minio cluster disk offline (instance {{ $labels.instance }})";
                    description = "Minio cluster disk is offline\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "MinioNodeDiskOffline";
                  expr = "minio_cluster_nodes_offline_total > 0";
                  for = "0m";
                  labels = {
                    severity = "critical";
                  };
                  annotations = {
                    summary = "Minio node disk offline (instance {{ $labels.instance }})";
                    description = "Minio cluster node disk is offline\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
                {
                  alert = "MinioDiskSpaceUsage";
                  expr = "disk_storage_available / disk_storage_total * 100 < 10";
                  for = "0m";
                  labels = {
                    severity = "warning";
                  };
                  annotations = {
                    summary = "Minio disk space usage (instance {{ $labels.instance }})";
                    description = "Minio available free space is low (< 10%)\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
                  };
                }
              ];
            }
          ];
        })
      ];
    };
  };
}
