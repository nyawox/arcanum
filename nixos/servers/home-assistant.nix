{
  config,
  lib,
  pkgs,
  arcanum,
  hostname,
  ...
}:
with lib;
let
  tsProxyIP = "100.64.0.2"; # lokalhost ts ip
  wgProxyIP = "10.100.0.6"; # lokalhost wg ip
in
{
  extraConfig = [
    (mkIf (config.modules.servers.postgresql.enable && hostname == "localpost") {
      sops.secrets.postgres-hass = {
        sopsFile = "${arcanum.secretPath}/hass-secrets.yaml";
        owner = "postgres";
        group = "postgres";
        format = "yaml";
      };
      services.postgresql = {
        ensureDatabases = [ "hass" ];
        ensureUsers = singleton {
          name = "hass";
          ensureDBOwnership = true;
        };
      };
      systemd.services.postgresql.postStart = mkAfter ''
        db_password="$(<"${config.sops.secrets.postgres-hass.path}")"
        db_password="''${db_password//\'/\'\'}"
        $PSQL -tAc 'ALTER ROLE "hass" WITH PASSWORD '"'$db_password'"
      '';
    })
  ];
  content = {
    modules.networking.tailscale.tags = [ "tag:admin-home-assistant" ];
    sops.secrets."hass-secrets" = {
      sopsFile = "${arcanum.secretPath}/hass-secrets.yaml";
      owner = "hass";
      group = "hass";
      path = "/var/lib/hass/secrets.yaml";
      restartUnits = [ "home-assistant.service" ];
    };
    services.home-assistant = {
      enable = true;
      extraComponents = [
        ## Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"
        ##
        "bluetooth" # required for switchbot
        "switchbot"
        "mobile_app"
        "broadlink"
        "accuweather"
        "ollama"
        "androidtv"
      ];
      extraPackages =
        ps: with ps; [
          gtts
          pyatv
          pychromecast
          psycopg2
          aiohttp-fast-zlib
          pyqrcode # 2fa depends
          ibeacon-ble # silence error
          adb-shell
          speedtest-cli
        ];
      customComponents = with pkgs.home-assistant-custom-components; [
        smartir
        pkgs.hass-nature-remo
        pkgs.hass-cupertino
        pkgs.hass-tapo
        pkgs.hass-oidc-auth
      ];
      customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [
        bubble-card
        card-mod
        button-card
        apexcharts-card
        universal-remote-card
        pkgs.hass-kiosk-mode
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
        homeassistant = {
          name = "Home";
          unit_system = "metric";
          time_zone = "!secret hass_time_zone";
          customize = {
            "input_text.yjp_longitude".hidden = true;
            "input_text.yjp_latitude".hidden = true;
            "input_text.yjp_appid".hidden = true;
          };
        };
        # waiting for this https://github.com/home-assistant/frontend/pull/23204
        auth_oidc = {
          client_id = "hass";
          client_secret = "!secret hass_oidc_secret";
          discovery_url = "https://account.${arcanum.domain}/oauth2/openid/hass/.well-known/openid-configuration";
          display_name = "${arcanum.serviceName} Account";
          id_token_signing_alg = "ES256";
          features.automatic_person_creation = true;
          claims = {
            display_name = "preferred_username";
            username = "preferred_username";
            groups = "hass_role";
          };
          roles.admin = "admin";
          roles.user = "user";
        };
        recorder.db_url = "!secret postgres_url";
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [
            wgProxyIP
            tsProxyIP
          ];
        };
        bluetooth = { };
        frontend = {
          themes = "!include_dir_merge_named themes";
        };
        mobile_app = { };
        smartir = { };
        prometheus = { };
        cupertino = { };
        light = {
          platform = "template";
          lights.bedroom = {
            friendly_name = "Bedroom Light";
            turn_on = [
              {
                service = "rest_command.send_ir_signal";
                data = {
                  signal = ''
                    {"format":"us","freq":38,"data":[8909,4513,526,1717,510,586,528,583,526,603,511,588,527,584,527,603,510,608,508,588,526,1702,528,1699,526,1697,531,1697,530,1697,528,1699,526,1702,530,586,526,585,526,605,509,587,526,603,511,587,526,586,526,607,511,1699,531,1696,528,1700,530,1697,528,1700,526,1701,526,1701,526,1702,526]}
                  '';
                };
              }
            ];
            turn_off = [
              {
                service = "rest_command.send_ir_signal";
                data = {
                  signal = ''
                    {"format":"us","freq":38,"data":[8909,4513,529,1699,527,584,528,601,511,588,526,585,529,602,509,588,526,590,526,585,529,1699,528,1716,511,1699,526,1718,509,1700,528,1700,526,1702,529,1698,528,601,511,587,526,1717,511,586,526,585,529,603,510,590,526,586,529,1699,526,1717,511,585,526,1702,526,1698,528,1699,529,1699,528]}
                  '';
                };
              }
            ];
            set_level = {
              alias = "Set Bedroom Light Brightness";
              sequence = [
                {
                  service = "input_number.set_value";
                  data_template = {
                    entity_id = "input_number.bedroom_target_level";
                    value = "{{ (brightness / 8.5) | round(0, 'floor') }}";
                  };
                }
                {
                  service = "input_number.set_value";
                  data_template = {
                    entity_id = "input_number.bedroom_steps";
                    value = ''
                      {% set current = states('input_number.bedroom_light_level') | int %}
                      {% set target = states('input_number.bedroom_target_level') | int %}
                      {{ target - current }}
                    '';
                  };
                }
                {
                  service = "script.turn_on";
                  data_template = {
                    entity_id = "script.adjust_brightness_up";
                    variables = {
                      steps = "{{ states('input_number.bedroom_steps') | int if states('input_number.bedroom_steps') | int > 0 else 0 }}";
                    };
                  };
                }
                {
                  service = "script.turn_on";
                  data_template = {
                    entity_id = "script.adjust_brightness_down";
                    variables = {
                      steps = "{{ -1 * (states('input_number.bedroom_steps') | int) if states('input_number.bedroom_steps') | int < 0 else 0 }}";
                    };
                  };
                }
                {
                  service = "input_number.set_value";
                  data_template = {
                    entity_id = "input_number.bedroom_light_level";
                    value = "{{ states('input_number.bedroom_target_level') | int }}";
                  };
                }
              ];
            };
            set_temperature = {
              alias = "Set Bedroom Light Temperature";
              sequence = [
                {
                  service = "input_number.set_value";
                  data_template = {
                    entity_id = "input_number.bedroom_temp_target_level";
                    value = ''
                      {% set min_temp = 153 %}
                      {% set max_temp = 500 %}
                      {% set levels = 31 %}
                      {% set temp = color_temp | int %}
                      {% set clamped_temp = [min_temp, temp, max_temp] | sort %}
                      {{ (((max_temp - clamped_temp[1]) / (max_temp - min_temp)) * (levels - 1)) | float }}
                    '';
                  };
                }
                {
                  service = "input_number.set_value";
                  data_template = {
                    entity_id = "input_number.bedroom_temp_steps";
                    value = ''
                      {% set current = states('input_number.bedroom_light_temp_level') | int %}
                      {% set target = states('input_number.bedroom_temp_target_level') | int %}
                      {{ target - current }}
                    '';
                  };
                }
                {
                  service = "script.turn_on";
                  data_template = {
                    entity_id = "script.adjust_temp_up";
                    variables = {
                      steps = "{{ states('input_number.bedroom_temp_steps') | int if states('input_number.bedroom_temp_steps') | int > 0 else 0 }}";
                    };
                  };
                }
                {
                  service = "script.turn_on";
                  data_template = {
                    entity_id = "script.adjust_temp_down";
                    variables = {
                      steps = "{{ -1 * (states('input_number.bedroom_temp_steps') | int) if states('input_number.bedroom_temp_steps') | int < 0 else 0 }}";
                    };
                  };
                }
                {
                  service = "input_number.set_value";
                  data_template = {
                    entity_id = "input_number.bedroom_light_temp_level";
                    value = "{{ states('input_number.bedroom_temp_target_level') | int }}";
                  };
                }
              ];
            };
          };
        };
        input_number = {
          bedroom_light_level = {
            name = "Bedroom Light Level";
            min = 0;
            max = 30;
            step = 1;
          };
          bedroom_target_level = {
            name = "Bedroom Target Level";
            min = 0;
            max = 30;
            step = 1;
          };
          bedroom_light_temp_level = {
            name = "Bedroom Light Temperature Level";
            min = 0;
            max = 30;
            step = 1;
          };
          bedroom_temp_target_level = {
            name = "Bedroom Temperature Target Level";
            initial = 0;
            min = 0;
            max = 30;
            step = 1;
          };
          bedroom_steps = {
            name = "Bedroom Brightness Steps";
            initial = 0;
            min = -30;
            max = 30;
            step = 1;
          };
          bedroom_temp_steps = {
            name = "Bedroom Temperature Steps";
            initial = 0;
            min = -30;
            max = 30;
            step = 1;
          };
        };
        script = {
          adjust_brightness_up = {
            alias = "Increase Bedroom Light Brightness";
            sequence = {
              repeat = {
                count = "{{ steps }}";
                sequence = [
                  {
                    service = "rest_command.send_ir_signal";
                    data = {
                      signal = ''
                        {"format":"us","freq":38,"data":[8905,4515,526,1698,529,587,526,585,526,586,528,602,510,588,527,585,526,591,526,585,529,1699,526,1718,508,1700,528,1700,526,1698,528,1700,527,1701,528,1699,528,603,511,1698,528,603,508,588,526,586,528,584,528,605,511,587,527,1716,511,586,526,1700,526,1717,511,1697,528,1700,527,1700,529]}
                      '';
                    };
                  }
                ];
              };
            };
          };
          adjust_brightness_down = {
            alias = "Decrease Bedroom Light Brightness";
            sequence = {
              repeat = {
                count = "{{ steps }}";
                sequence = [
                  {
                    service = "rest_command.send_ir_signal";
                    data = {
                      signal = ''
                        {"format":"us","freq":38,"data":[8908,4512,528,1700,526,586,528,601,511,603,511,586,526,586,528,601,510,608,511,586,526,1717,511,1697,528,1700,526,1718,510,1698,528,1700,526,1702,528,588,526,586,528,1715,511,586,526,586,528,601,511,588,526,590,528,1699,526,1717,511,586,526,1701,526,1697,528,1700,528,1699,529,1699,528]}
                      '';
                    };
                  }
                ];
              };
            };
          };
          adjust_brightness_light_mode = {
            alias = "Bedroom Light Mode";
            icon = "mdi:lightbulb-on";
            sequence = [
              {
                service = "rest_command.send_ir_signal";
                data = {
                  signal = ''
                    {"format":"us","freq":38,"data":[8909,4514,526,1701,526,603,511,587,526,585,529,587,526,585,529,602,509,592,526,585,529,1699,528,1699,526,1702,526,1698,528,1699,528,1700,528,1720,510,1698,528,1699,528,601,513,1698,528,603,511,585,526,586,528,607,511,585,529,601,510,1700,528,603,510,1697,531,1697,528,1699,528,1702,526]}                        
                  '';
                };
              }
              {
                service = "input_number.set_value";
                data_template = {
                  entity_id = "input_number.bedroom_light_level";
                  value = 30;
                };
              }
              # the signal above only set the brightness to max
              {
                delay = {
                  seconds = 2;
                };
              }
              {
                action = "light.turn_on";
                data = {
                  kelvin = 6500;
                  brightness_pct = 100;
                };
                target = {
                  entity_id = "light.bedroom";
                };
              }
            ];
          };
          adjust_brightness_night_mode = {
            alias = "Bedroom Night Mode";
            icon = "mdi:lightbulb-night";
            sequence = [
              {
                action = "rest_command.send_ir_signal";
                data = {
                  signal = ''
                    {"format":"us","freq":38,"data":[8905,4513,529,1700,526,586,528,601,511,603,512,584,528,601,511,603,510,590,526,586,528,1698,528,1699,530,1697,529,1698,526,1701,526,1700,526,1720,511,585,529,1698,528,1699,528,584,528,603,510,586,527,584,528,608,510,1697,531,585,526,585,528,1699,528,1699,526,1701,529,1698,526,1701,528]}
                  '';
                };
              }
              {
                service = "input_number.set_value";
                data_template = {
                  entity_id = "input_number.bedroom_light_level";
                  value = 0;
                };
              }
              {
                action = "input_number.set_value";
                data_template = {
                  entity_id = "input_number.bedroom_light_temp_level";
                  value = 0;
                };
              }
              {
                action = "light.turn_on";
                data = {
                  kelvin = 2000;
                  brightness_pct = 1;
                };
                target = {
                  entity_id = "light.bedroom";
                };
              }
            ];
          };
          adjust_temp_up = {
            alias = "Increase Bedroom Light Temperature";
            sequence = {
              repeat = {
                count = "{{ steps }}";
                sequence = [
                  {
                    service = "rest_command.send_ir_signal";
                    data = {
                      signal = ''
                        {"format":"us","freq":38,"data":[8906,4515,526,1701,526,585,526,603,511,588,526,585,526,605,509,587,526,590,528,601,511,1718,511,1716,511,1697,528,1699,530,1697,526,1701,526,1706,526,585,526,1702,526,603,512,586,525,586,528,601,511,588,526,589,527,1701,528,583,528,1700,529,1698,529,1700,526,1697,528,1700,528,1700,528]}                      
                      '';
                    };
                  }
                ];
              };
            };
          };
          adjust_temp_down = {
            alias = "Decrease Bedroom Light Temperature";
            sequence = {
              repeat = {
                count = "{{ steps }}";
                sequence = [
                  {
                    service = "rest_command.send_ir_signal";
                    data = {
                      signal = ''
                        {"format":"us","freq":38,"data":[8912,4511,528,1699,529,600,511,588,526,586,528,600,511,588,526,585,529,587,529,603,511,1697,529,1699,529,1699,526,1698,529,1699,529,1715,511,1702,528,601,511,1701,526,585,531,1697,526,586,529,601,510,604,510,590,527,1697,530,587,525,1717,511,585,526,1717,511,1697,530,1697,528,1700,528]}
                      '';
                    };
                  }
                ];
              };
            };
          };
          meow_nightlight = {
            alias = "Night";
            icon = "mdi:lightbulb-night";
            sequence = [
              {
                action = "script.adjust_brightness_night_mode";
              }
            ];
          };
          meow_daylight = {
            alias = "Day";
            icon = "mdi:lightbulb-on";
            sequence = [
              {
                action = "script.adjust_brightness_light_mode";
              }
            ];
          };
          meow_turn_off_light = {
            alias = "Off";
            icon = "mdi:lightbulb-off";
            sequence = [
              {
                action = "light.turn_off";
                target = {
                  entity_id = "light.bedroom";
                };
              }
            ];
          };
          lock_front_door = {
            alias = "Lock front door";
            icon = "mdi:door-closed-lock";
            sequence = [
              {
                action = "lock.lock";
                target = {
                  entity_id = "lock.lock_d530";
                };
              }
            ];
          };
          unlock_front_door = {
            alias = "Unlock front door";
            icon = "mdi:door-open";
            sequence = [
              {
                action = "lock.unlock";
                target = {
                  entity_id = "lock.lock_d530";
                };
              }
            ];
          };
          meow_ac_instant_cooling = {
            alias = "Instant Cooling";
            icon = "mdi:snowflake";
            sequence = [
              {
                action = "climate.turn_on";
                target = {
                  entity_id = "climate.ac_remo_mini";
                };
              }
              {
                action = "climate.set_temperature";
                data = {
                  temperature = 16;
                  hvac_mode = "cool";
                };
                target = {
                  entity_id = "climate.ac_remo_mini";
                };
              }
              {
                action = "climate.set_swing_mode";
                data = {
                  swing_mode = "⥮5";
                };
                target = {
                  entity_id = "climate.ac_remo_mini";
                };
              }
              {
                action = "climate.set_fan_mode";
                data = {
                  fan_mode = "4";
                };
                target = {
                  entity_id = "climate.ac_remo_mini";
                };
              }
            ];
          };
        };
        logger = {
          default = "INFO";
          logs = {
            custom_components.nature_remo = "debug";
          };
        };
        rest_command = {
          send_ir_signal = {
            # sadly not working with avahi hostname.local
            url = "http://192.168.0.112/messages"; # nature remo mini local api
            method = "POST";
            headers = {
              X-Requested-With = "local";
            };
            payload = "{{ signal }}";
          };
        };
        input_text = {
          yjp_longitude = {
            initial = "!secret yjp_longitude";
          };
          yjp_latitude = {
            initial = "!secret yjp_latitude";
          };
          yjp_appid = {
            initial = "!secret yjp_appid";
          };
        };
        rest =
          let
            mkSensor = forecastIndex: [
              {
                unique_id = "yjpweather_forecast_${toString forecastIndex}_rainfall";
                name = "Rainfall precipitation in ${toString (forecastIndex * 10)} Minutes";
                unit_of_measurement = "mm";
                value_template = ''
                  {% if value_json.Feature[0].Property.WeatherList.Weather[${toString forecastIndex}] %}
                    {{ value_json.Feature[0].Property.WeatherList.Weather[${toString forecastIndex}].Rainfall }}
                  {% endif %}
                '';
              }
              {
                unique_id = "yjpweather_forecast_${toString forecastIndex}_date";
                name = "${toString (forecastIndex * 10)}Min Rainfall Date";
                value_template = ''
                  {% if value_json.Feature[0].Property.WeatherList.Weather[${toString forecastIndex}] %}
                    {{ value_json.Feature[0].Property.WeatherList.Weather[${toString forecastIndex}].Date }}
                  {% endif %}
                '';
              }
            ];

            forecastSensors = builtins.concatLists (builtins.genList mkSensor 7);
          in
          [
            {
              resource_template = "https://map.yahooapis.jp/weather/V1/place?coordinates={{ states.input_text.yjp_longitude.state }},{{ states.input_text.yjp_latitude.state }}&appid={{ states.input_text.yjp_appid.state }}&output=json";
              method = "GET";
              headers = {
                Content-Type = "application/json";
              };
              scan_interval = 60;
              sensor = forecastSensors ++ [
                {
                  unique_id = "yjpweather_rainfall_data";
                  name = "Rainfall Precipitation Data";
                  value_template = "OK";
                  json_attributes_path = "$.Feature[0].Property.WeatherList";
                  json_attributes = [
                    "Weather"
                  ];
                }
              ];
            }
          ];
        climate = singleton {
          platform = "smartir";
          name = "Neko AC";
          device_code = 1129;
          controller_data = "remote.rm_mini";
        };
        input_boolean = {
          hide_header = {
            name = "Hide Header on Mobile";
            initial = "on";
            icon = "mdi:toggle-switch";
          };
          lovelace_settings_popup = {
            name = "Track lovelace settings popup open stat";
            initial = "off";
          };
        };
        "automation manual" = [
          {
            alias = "Persist Bedroom Light state across reboot";
            trigger = [
              {
                platform = "homeassistant";
                event = "start";
              }
            ];
            action = [
              {
                service = "light.turn_on";
                target = {
                  entity_id = "light.bedroom";
                };
                data_template = {
                  brightness = "{{ (states('input_number.bedroom_light_level') | int * 8.5) | int }}";
                  color_temp = "{{ 500 - ((states('input_number.bedroom_light_temp_level') | int / 30) * (500 - 153)) | float }}";
                };
              }
            ];
          }
          {
            alias = "Set Default Theme on startup";
            trigger = [
              {
                platform = "homeassistant";
                event = "start";
              }
            ];
            action = [
              {
                service = "frontend.set_theme";
                data = {
                  name = "Catppuccin Mocha";
                };
              }
            ];
          }
        ];
        "automation ui" = "!include automations.yaml";
        "scene ui" = "!include scenes.yaml";
      };
    };
    # prevent home-assistant fail to load when UI automations aren't defined yet
    systemd.tmpfiles.rules = [
      "f ${config.services.home-assistant.configDir}/automations.yaml 0755 hass hass"
      "f ${config.services.home-assistant.configDir}/scenes.yaml 0755 hass hass"
      "C ${config.services.home-assistant.configDir}/themes 0755 hass hass - ${pkgs.catppuccin-home-assistant}/themes"
    ];
  };
  persist.directories = singleton {
    directory = "/var/lib/hass";
    user = "hass";
    group = "hass";
  };
}
