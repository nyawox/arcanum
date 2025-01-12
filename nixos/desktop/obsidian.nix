{
  config,
  pkgs,
  lib,
  arcanum,
  ...
}:
let
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
              "arn:aws:s3:::obsidian",
              "arn:aws:s3:::obsidian/*"
            ]
          }
        ]
      }
    '';
  };
in
{
  extraConfig = [
    (lib.mkIf config.modules.servers.minio.enable {
      modules.servers.minio.buckets = [
        {
          name = "obsidian";
          policy = policy-json;
        }
      ];
    })
  ];
  content = {
    environment.systemPackages = lib.singleton (
      pkgs.obsidian.overrideAttrs (_old: {
        postFixup = ''
          wrapProgram $out/bin/obsidian \
          --set DE flatpak \
          --add-flags '--wayland-text-input-version=3'
        '';
      })
    );
    # Bind mount readme to obsidian vault
    fileSystems."/persist/home/${arcanum.username}/Documents/personal-vault/readmes/arcanum.md" = {
      device = "/persist/arcanum/README.md";
      options = [
        "bind"
        "nofail"
      ];
    };
    systemd.tmpfiles.rules = lib.singleton "d /home/${arcanum.username}/Documents/personal-vault/readmes 0750 ${arcanum.username} users -";
  };
  userPersist.directories = lib.singleton ".config/obsidian";
}
