{
  cfg,
  lib,
  pkgs,
  ...
}:
with lib;
let
  common-args = ''
    # fix fcitx5
    dbus-user filter
    dbus-user.talk org.freedesktop.portal.Fcitx
    ignore dbus-user none
  '';
  # requires DE=flatpak env var
  fixURI = ''
    # fix opening link
    private-bin gdbus
    dbus-user.talk org.freedesktop.portal.Desktop
  '';
  # i don't want ugly font rendering and ugly non-apple emoji
  # even if it's privacy tradeoff
  fonts = ''
    noblacklist /etc/fonts
    whitelist /etc/fonts
    noblacklist ''${HOME}/.local/share/fonts
    whitelist ''${HOME}/.local/share/fonts
    noblacklist ''${HOME}/.config/fontconfig
    whitelist ''${HOME}/.config/fontconfig
  '';
in
{
  options = {
    tor-browser = mkEnableOption "tor-browser";
    signal-desktop = mkEnableOption "signal-desktop";
    vesktop = mkEnableOption "vesktop";
    vivaldi = mkEnableOption "vivaldi";
    netflix = mkEnableOption "netflix";
    uget = mkEnableOption "uget";
  };
  content = {
    programs.firejail.enable = true;
    environment.systemPackages = [
      (
        let
          packageNames = [
            "tor-browser"
            "signal-desktop"
            "vesktop"
            "vivaldi"
            "uget"
          ];
          packages = builtins.filter (pkg: pkg != null) (
            map (name: if builtins.getAttr name cfg then builtins.getAttr name pkgs else null) packageNames
          );
        in
        pkgs.runCommand "firejail-icons"
          {
            preferLocalBuild = true;
            allowSubstitutes = false;
            meta.priority = -1;
          }
          ''
            mkdir -p "$out/share/icons"
            ${concatStringsSep "\n" (
              map (pkg: ''
                tar -C "${pkg}" -c share/icons -h --mode=0755 -f - | tar -C "$out" -xf -
              '') packages
            )}
            find "$out/" -type f -print0 | xargs -0 chmod 0444
            find "$out/" -type d -print0 | xargs -0 chmod 0555
          ''
      )
    ];
  };
  extraConfig = [
    (mkIf (cfg.enable && cfg.tor-browser) {
      programs.firejail.wrappedBinaries.tor-browser = {
        executable = "${getExe pkgs.tor-browser}";
        desktop = "${pkgs.tor-browser}/share/applications/torbrowser.desktop";
        profile = pkgs.writeText "tor-browser.local" ''
          ${common-args}
          include tor-browser.profile
        '';
      };
    })
    (mkIf (cfg.enable && cfg.signal-desktop) {
      programs.firejail.wrappedBinaries.signal-desktop =
        let
          signal-desktop = pkgs.signal-desktop.overrideAttrs (_old: {
            # https://github.com/signalapp/Signal-Desktop/pull/7078 launches minimized in wayland
            # patch show:false between `async function createWindows` and `autoHideMenuBar`
            preInstall = ''
              sed -i '/async function createWindow/,/autoHideMenuBar:/s/show: false/show: true/' asar-contents/app/main.js
            '';
            postFixup = ''
              wrapProgram $out/bin/signal-desktop \
              --set DE flatpak \
              --add-flags '--wayland-text-input-version=3'
            '';
          });
        in
        {
          executable = "${getExe signal-desktop}";
          desktop = "${pkgs.signal-desktop}/share/applications/signal-desktop.desktop";
          profile = pkgs.writeText "signal-desktop.local" ''
            ${common-args}
            ${fixURI}
            ${fonts}
            include signal-desktop.profile
          '';
        };
    })
    (mkIf (cfg.enable && cfg.vesktop) {
      programs.firejail.wrappedBinaries.vesktop =
        let
          vesktop = pkgs.vesktop.overrideAttrs (old: {
            postFixup = ''
              ${old.postFixup or ""}
              wrapProgram $out/bin/vesktop \
              --set DE flatpak \
              --add-flags '--wayland-text-input-version=3'
            '';
          });
        in
        {
          executable = "${getExe vesktop}";
          desktop = "${pkgs.vesktop}/share/applications/vesktop.desktop";
          profile = pkgs.writeText "discord.local" ''
            ${common-args}
            ${fixURI}
            ${fonts}
            # whitelist vesktop config folder
            mkdir ''${HOME}/.config/vesktop
            whitelist ''${HOME}/.config/vesktop
            include discord.profile
          '';
        };
    })
    (mkIf (cfg.enable && cfg.vivaldi) {
      programs.firejail.wrappedBinaries.vivaldi =
        let
          vivaldi = pkgs.vivaldi.override {
            proprietaryCodecs = true;
            enableWidevine = true; # Wide*V*ine for chromium, Wide*v*ine for vivaldi
            commandLineArgs = "--wayland-text-input-version=3 --force-dark-mode";
          };
        in
        {
          executable = "${getExe vivaldi}";
          desktop = "${vivaldi}/share/applications/vivaldi-stable.desktop";
          profile = pkgs.writeText "vivaldi-stable.local" ''
            ${common-args}
            include vivaldi-stable.profile
          '';
        };
      # netflix 1080p and darkreader
      environment.etc."chromium/policies/managed/netflix.json".text = ''
        {
          "ExtensionInstallForcelist": ["mdlbikciddolbenfkgggdegphnhmnfcg", "eimadpbcbfnmbkopoojfekhnkhdbieeh"], 
          "ExtensionManifestV2Availability": 2
        }
      '';
    })
    (mkIf (cfg.enable && cfg.netflix) {
      modules.desktop.firejail.vivaldi = mkForce true;
      environment.systemPackages =
        let
          icon = pkgs.fetchurl {
            name = "netflix-icon-2016.png";
            url = "https://assets.nflxext.com/us/ffe/siteui/common/icons/nficon2016.png";
            sha256 = "sha256-c0H3uLCuPA2krqVZ78MfC1PZ253SkWZP3PfWGP2V7Yo=";
          };
        in
        [
          (pkgs.makeDesktopItem {
            name = "Netflix";
            desktopName = "Netflix";
            inherit icon;
            exec = "vivaldi --app=https://www.netflix.com --no-first-run --no-default-browser-check --no-crash-upload";
          })
        ];
    })
    (mkIf (cfg.enable && cfg.uget) {
      programs.firejail.wrappedBinaries.uget = {
        executable = "${getExe pkgs.uget}";
        desktop = "${pkgs.uget}/share/applications/uget-gtk.desktop";
        profile = pkgs.writeText "uget-gtk.local" ''
          ${common-args}
          ${fonts}
          include uget-gtk.profile
        '';
      };
    })
  ];
  userPersist.directories = [
    (mkIf cfg.vesktop ".config/vesktop")
    (mkIf cfg.vivaldi ".config/vivaldi")
    (mkIf cfg.signal-desktop ".config/Signal")
    (mkIf cfg.uget ".config/uGet")
  ];
}
