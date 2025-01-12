# built on this commit https://github.com/bitwarden/clients/pull/12371/commits/4c78e3b1cf6936eaf352f9c6c01b85210d4832ed
# upgraded to electron 33 and fixed browser biometrics
{
  bitwarden-desktop,
  fetchFromGitHub,
  nodejs_20,
  rustPlatform,
  runCommand,
  patchutils_0_4_2,
  lib,
  electron_33,
  stdenv,
  buildNpmPackage,
  glib,
  gtk3,
  oo7,
  nord-to-catppuccin,
}:
let
  icon = "bitwarden";
  electron = electron_33;
  bitwardenDesktopNativeArch =
    {
      aarch64 = "arm64";
      x86_64 = "x64";
    }
    .${stdenv.hostPlatform.parsed.cpu.name}
      or (throw "bitwarden-desktop: unsupported CPU family ${stdenv.hostPlatform.parsed.cpu.name}");
in
# esbuild_0230 = esbuild.override {
#   buildGoModule =
#     args:
#     buildGoModule (
#       args
#       // rec {
#         version = "0.23.0";
#         src = fetchFromGitHub {
#           owner = "evanw";
#           repo = "esbuild";
#           rev = "v${version}";
#           hash = "sha256-AH4Y5ELPicAdJZY5CBf2byOxTzOyQFRh4XoqRUQiAQw=";
#         };
#       }
#     );
# };
# esbuild_0215 = esbuild.override {
#   buildGoModule =
#     args:
#     buildGoModule (
#       args
#       // rec {
#         version = "0.21.5";
#         src = fetchFromGitHub {
#           owner = "evanw";
#           repo = "esbuild";
#           rev = "v${version}";
#           hash = "sha256-FpvXWIlt67G8w3pBKZo/mcp57LunxDmRUaCU/Ne89B8=";
#         };
#       }
#     );
# };
bitwarden-desktop.override {
  buildNpmPackage =
    args:
    buildNpmPackage (
      args
      // rec {
        pname = "bitwardenapp";
        version = "4c78e3b1cf6936eaf352f9c6c01b85210d4832ed";
        src = fetchFromGitHub {
          owner = "bitwarden";
          repo = "clients";
          rev = "4c78e3b1cf6936eaf352f9c6c01b85210d4832ed";
          hash = "sha256-CTRq4H3aN6ETme2vO7TQKiL5kCDzi5+mt/BZa44mtDU=";
        };
        # patches = [
        #   # patches from upstreampkgs, but updated for newer versions
        #   # unfortunately couldn't build successfully due to esbuild issue mentioned later on
        #   ./no-biometrics-autosetup.patch
        #   ./lockjson.patch
        #   ./exe.patch
        #   ./skip-afterpack.patch
        # ];
        nodejs = nodejs_20;

        cargoDeps = rustPlatform.fetchCargoVendor {
          inherit pname version src;
          patches = map (
            patch:
            runCommand (builtins.baseNameOf patch) { nativeBuildInputs = [ patchutils_0_4_2 ]; } ''
              < ${patch} filterdiff -p1 --include=${lib.escapeShellArg args.cargoRoot}'/*' > $out
            ''
          ) args.patches;
          patchFlags = [ "-p4" ];
          sourceRoot = "${src.name}/${args.cargoRoot}";
          hash = "sha256-LptbBS76b4/PR/r3Ie3KaE89Bsb/Ba2bEF7yi94407Y=";
        };
        env = {
          ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
          # npm fails to find esbuild without this variable
          # ESBUILD_BINARY_PATH = "${lib.getExe esbuild_0230}";
          # building post angular upgrade revisions feel almost impossible
          # due to angular and vite wanting different versions of esbuild
          # it's better to wait stable release and someone more experienced package in upstreampkgs
        };
        makeCacheWritable = true;
        npmDepsHash = "sha256-UCM2133j39XZpQnetUIhsqWK+PNhW0kngSswwgH7S5U=";

        buildInputs = [
          glib
          gtk3
          # libsecret # don't need anymore, they've switched to oo7
          # https://github.com/bitwarden/clients/pull/11900/files
          oo7
        ];

        preBuild = ''
          ${lib.getExe nord-to-catppuccin}
          if [[ $(jq --raw-output '.devDependencies.electron' < package.json | grep -E --only-matching '^[0-9]+') != ${lib.escapeShellArg (lib.versions.major electron.version)} ]]; then
            echo 'ERROR: electron version mismatch'
            exit 1
          fi

          pushd apps/desktop/desktop_native/napi
          npm run build
          popd

          pushd apps/desktop/desktop_native/proxy
          cargo build --bin desktop_proxy --release
          popd
        '';

        postBuild = ''
          pushd apps/desktop

          # desktop_native/index.js loads a file of that name regardless of the libc being used
          mv desktop_native/napi/desktop_napi.* desktop_native/napi/desktop_napi.linux-${bitwardenDesktopNativeArch}-musl.node

          npm exec electron-builder -- \
            --dir \
            -c.electronDist=${electron.dist} \
            -c.electronVersion=${electron.version}

          popd

        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin
          cp -r apps/desktop/desktop_native/target/release/desktop_proxy $out/bin

          pushd apps/desktop/dist/linux-${lib.optionalString stdenv.hostPlatform.isAarch64 "arm64-"}unpacked
          mkdir -p $out/opt/Bitwarden
          cp -r locales resources{,.pak} $out/opt/Bitwarden
          popd

          makeWrapper '${lib.getExe electron}' "$out/bin/bitwarden" \
            --add-flags $out/opt/Bitwarden/resources/app.asar \
            --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3}}" \
            --set-default ELECTRON_IS_DEV 0 \
            --inherit-argv0

          # Extract the polkit policy file from the multiline string in the source code.
          # This may break in the future but its better than copy-pasting it manually.
          mkdir -p $out/share/polkit-1/actions/
          pushd apps/desktop/src/key-management/biometrics
          # newer version has changed to os-biometrics-linux.service.ts
          awk '/const polkitPolicy = `/{gsub(/^.*`/, ""); print; str=1; next} str{if (/`;/) str=0; gsub(/`;/, ""); print}' biometric.unix.main.ts > $out/share/polkit-1/actions/com.bitwarden.Bitwarden.policy
          popd

          pushd apps/desktop/resources/icons
          for icon in *.png; do
            dir=$out/share/icons/hicolor/"''${icon%.png}"/apps
            mkdir -p "$dir"
            cp "$icon" "$dir"/${icon}.png
          done
          popd

          runHook postInstall
        '';
      }
    );
}
