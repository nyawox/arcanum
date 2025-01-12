{
  arcanum,
  ...
}:
{
  content = {
    services.homepage-dashboard = {
      enable = true;
      openFirewall = false;
      bookmarks = [
        {
          "Search Engine" = [
            {
              Search = [
                {
                  abbr = "S";
                  href = "https://search.${arcanum.domain}";
                  icon = "searxng.svg";
                }
              ];
            }
            {
              "NixOS Search" = [
                {
                  abbr = "NS";
                  href = "https://search.nixos.org/packages";
                  icon = "nixos.svg";
                }
              ];
            }
            {
              Google = [
                {
                  abbr = "G";
                  href = "https://www.google.com";
                  icon = "google.svg";
                }
              ];
            }
            {
              "Yandex Image" = [
                {
                  abbr = "YI";
                  href = "https://yandex.ru/images/";
                  icon = "yandex.svg";
                }
              ];
            }
          ];
        }
        {
          Developer = [
            {
              Github = [
                {
                  abbr = "GH";
                  href = "https://github.com/";
                  icon = "github.svg";
                }
              ];
            }
            {
              Codeberg = [
                {
                  abbr = "CDB";
                  href = "https://codeberg.org";
                  icon = "codeberg.svg";
                }
              ];
            }
            {
              AWS = [
                {
                  abbr = "AWS";
                  href = "https://console.aws.amazon.com/";
                  icon = "aws.svg";
                }
              ];
            }
            {
              "NixOS Wiki" = [
                {
                  abbr = "NW";
                  href = "https://wiki.nixos.org/";
                  icon = "nixos.svg";
                }
              ];
            }
            {
              "Nixpkgs Pull Request Tracker" = [
                {
                  abbr = "NPR";
                  href = "https://nixpk.gs/pr-tracker.html";
                  icon = "nixos.svg";
                }
              ];
            }
            {
              "Nixpkgs" = [
                {
                  abbr = "NP";
                  href = "https://github.com/NixOS/nixpkgs";
                  icon = "nixos.svg";
                }
              ];
            }
            {
              "Arch Wiki" = [
                {
                  abbr = "AW";
                  href = "https://wiki.archlinux.org/";
                  icon = "arch-linux.svg";
                }
              ];
            }
            {
              "ChatGPT" = [
                {
                  abbr = "CG";
                  href = "https://chat.openai.com/";
                  icon = "openai.svg";
                }
              ];
            }
          ];
        }
        {
          Social = [
            {
              Reddit = [
                {
                  abbr = "RE";
                  href = "https://reddit.com/";
                  icon = "reddit.svg";
                }
              ];
            }
            {
              Twitter = [
                {
                  abbr = "X";
                  href = "https://xcancel.com/";
                  icon = "twitter.svg";
                }
              ];
            }
            {
              Instagram = [
                {
                  abbr = "INS";
                  href = "https://www.instagram.com/";
                  icon = "instagram.svg";
                }
              ];
            }
            {
              "Proton Mail" = [
                {
                  abbr = "PM";
                  href = "https://account.proton.me/mail";
                  icon = "proton-mail.svg";
                }
              ];
            }
          ];
        }
        {
          Entertainment = [
            {
              YouTube = [
                {
                  abbr = "YT";
                  href = "https://youtube.com/";
                  icon = "youtube.svg";
                }
              ];
            }
            {
              Twitch = [
                {
                  abbr = "TW";
                  href = "https://www.twitch.tv/";
                  icon = "twitch.svg";
                }
              ];
            }
            {
              Netflix = [
                {
                  abbr = "NT";
                  href = "https://www.netflix.com/";
                  icon = "netflix.svg";
                }
              ];
            }
            {
              "Prime Video" = [
                {
                  abbr = "PV";
                  href = "https://www.amazon.co.jp/gp/video/getstarted";
                  icon = "amazon.svg";
                }
              ];
            }
          ];
        }
      ];
      services = [
        {
          Home = [
            {
              "Smart Home" = {
                href = "https://hass.${arcanum.domain}/";
                icon = "home-assistant.svg";
              };
            }
            {
              Recipes = {
                href = "https://recipes.${arcanum.domain}";
                icon = "mealie.svg";
              };
            }
          ];
        }
        {
          Network = [
            {
              VPN = {
                href = "https://hs.${arcanum.domain}/admin";
                icon = "tailscale.svg";
              };
            }
            {
              "DNS 1" = {
                href = "https://adguard.${arcanum.domain}";
                icon = "adguard-home.svg";
              };
            }
            {
              "DNS 2" = {
                href = "https://adguard-2.${arcanum.domain}";
                icon = "adguard-home.svg";
              };
            }
          ];
        }
        {
          Personal = [
            {
              Mail = {
                href = "https://mail.${arcanum.domain}";
                icon = "snappymail.svg";
              };
            }
            {
              Books = {
                href = "https://books.${arcanum.domain}";
                icon = "stump.svg";
              };
            }
            {
              Documents = {
                href = "https://docs.${arcanum.domain}";
                icon = "paperless-ngx.svg";
              };
            }
            {
              "Block Storage" = {
                href = "https://minio.${arcanum.domain}";
                icon = "minio-light.svg";
              };
            }
            {
              "Calendar" = {
                href = "https://cal.${arcanum.domain}/.web";
                icon = "radicale.svg";
              };
            }
          ];
        }
        {
          Monitoring = [
            {
              Grafana = {
                href = "https://grafana.${arcanum.domain}/";
                icon = "grafana.svg";
              };
            }
            {
              Prometheus = {
                href = "https://prometheus.${arcanum.domain}/";
                icon = "prometheus.svg";
              };
            }
            {
              "Alert Manager" = {
                href = "https://alerts.${arcanum.domain}/";
                icon = "alertmanager.svg";
              };
            }
            {
              Healthchecks = {
                href = "https://health.${arcanum.domain}/";
                icon = "healthchecks.svg";
              };
            }
          ];
        }
        {
          Tools = [
            {
              Git = {
                href = "https://git.${arcanum.domain}";
                icon = "forgejo.svg";
              };
            }
            {
              Passwords = {
                href = "https://vault.${arcanum.domain}/";
                icon = "vaultwarden.svg";
              };
            }
            {
              LLM = {
                href = "https://llm.${arcanum.domain}/";
                icon = "ollama.svg";
              };
            }
          ];
        }
      ];
      widgets = [
        {
          logo.icon = "https://cdn.discordapp.com/emojis/932325302108053525.webp";
        }
        { resources = false; }
        {
          datetime = {
            text_size = "3x1";
            format = {
              timeStyle = "short";
              dateStyle = "short";
              hourCycle = "h23";
            };
          };
        }
        {
          search = {
            provider = "custom";
            url = "https://search.${arcanum.domain}/search?q=";
            focus = false;
            target = "_blank";
          };
        }
        {
          openmeteo = {
            label = "Weather";
            timezone = "Asia/Tokyo";
            units = "metric";
            cache = 5; # Time in minutes to cache API responses, to stay within limits
          };
        }
      ];
      settings = {
        title = "Homepage";
        background = {
          image = "https://unsplash.com/photos/rTZW4f02zY8/download?ixid=M3wxMjA3fDB8MXxzZWFyY2h8Mnx8Y29zbW9zfGVufDB8fHx8MTczNjA2NzU2N3ww&force=true&w=2400";
          blur = "sm";
          opacity = 80;
        };
        cardBlur = "xl";
        theme = "dark";
        color = "rose";
        favicon = "https://cdn.discordapp.com/emojis/932325302108053525.webp";
        hideVersion = "false";
        headerStyle = "underlined";
      };
    };
  };
}
