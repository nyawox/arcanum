{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      config,
      ...
    }:
    let
      packages = {
        default = packages.arcanum;
        arcanum = craneLib.buildPackage build-attrs // {
          meta.mainProgram = "arcanum";
        };
      };

      toolchain =
        with inputs.fenix.packages.${system};
        combine [
          latest.rustc
          latest.cargo
          latest.clippy
          latest.rust-analysis
          latest.rust-src
          latest.rustfmt
        ];

      craneLib = (inputs.crane.mkLib pkgs).overrideToolchain toolchain;

      build-deps = with pkgs; [
        gcc
        inputs.nix-eval-jobs.packages.${pkgs.system}.nix-eval-jobs
        nix # lix
      ];

      unfilteredRoot = ./.; # The original, unfiltered source

      src = pkgs.lib.fileset.toSource {
        root = unfilteredRoot;
        fileset = pkgs.lib.fileset.unions [
          # Default files from crane (Rust and cargo files)
          (craneLib.fileset.commonCargoSources unfilteredRoot)
        ];
      };

      build-attrs = {
        inherit src;
        buildInputs = build-deps;
      };

      deps-only = craneLib.buildDepsOnly ({ } // build-attrs);

      checks = {
        clippy = craneLib.cargoClippy (
          {
            cargoArtifacts = deps-only;
            cargoClippyExtraArgs = "--all-features -- --deny warnings";
          }
          // build-attrs
        );

        rust-fmt = craneLib.cargoFmt ({ inherit src; } // build-attrs);

        rust-tests = craneLib.cargoNextest (
          {
            cargoArtifacts = deps-only;
            partitions = 1;
            partitionType = "count";
          }
          // build-attrs
        );
      };

    in
    {
      inherit checks packages;
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          nvidia.acceptLicense = true;
        };
        overlays = [
          inputs.lix-module.overlays.default
          inputs.nur.overlays.default
          inputs.berberman.overlays.default
          inputs.niri.overlays.niri
          inputs.nix-minecraft.overlay
          inputs.fenix.overlays.default
          (_final: prev: {
            inherit (inputs.nix-eval-jobs.packages.${pkgs.system}) nix-eval-jobs;
            firejail = prev.firejail.overrideAttrs (_old: {
              pname = "firejail-unstable";
              version = "landlock-split-unstable-2025-01-21";

              src = prev.fetchFromGitHub {
                owner = "netblue30";
                repo = "firejail";
                rev = "bd946e3594f27190b4a948444c0c1622d29a60f2";
                hash = "sha256-9ZQYyXQ2IV5ZTxlnVSi2o7X/iKAclRYK2a+Q3f1qagA=";
              };
            });
            # pgsql 17 support
            prometheus-postgres-exporter = prev.prometheus-postgres-exporter.overrideAttrs (_old: {
              name = "prometheus-postgres-exporter-unstable";
              version = "0.16.0-unstable-2025-01-13";

              src = prev.fetchFromGitHub {
                owner = "prometheus-community";
                repo = "postgres_exporter";
                rev = "7d4c278221e95ddbc62108973e5828a3ffaa2eb8";
                hash = "sha256-6WH6Yls172untyxNrW2pwXMFgz35qyrUpML5KU/n/+k=";
              };
              vendorHash = "sha256-y0Op+FxzOCFmZteHOuqnOcqQlQ0t10Xf+3mSsQEJiPg=";
            });
          })
          inputs.self.overlays.default
        ];
      };
      pkgsDirectory = ./pkgs/by-name;
      overlayAttrs = config.packages;
      treefmt = {
        programs = {
          nixfmt-rfc-style.enable = true;
          deadnix.enable = true;
          statix.enable = true;
          prettier.enable = true;
          beautysh.enable = true;
          yamlfmt.enable = true;
          rustfmt = {
            enable = true;
            edition = "2024";
          };
        };
        settings.global.excludes = [
          "secrets/*"
          "remoteinstall"
          "localinstall"
        ];
        flakeFormatter = true;
        projectRootFile = "flake.nix";
      };
      # Not to be confused with capital S "devShells"
      devshells.default = {
        packages =
          with pkgs;
          [
            config.treefmt.build.wrapper
            nix-init # generate package deriviations from urls automatically
            nix-update # update package hashes
            ssh-to-age
            inputs.latest.legacyPackages.${pkgs.system}.nixfmt-rfc-style
            deadnix
            statix
            git-agecrypt
            github-cli
            toolchain
          ]
          ++ build-deps;
        #TODO Make a better interface, preferably TUI to manage systems
        commands = [
          {
            name = "cleanup";
            help = "Clean & optimize nix store. it can take a long time";
            command = "sudo -- sh -c 'nix-collect-garbage -d; nix-store --optimize'";
            category = "cleanup";
          }
          {
            name = "format";
            help = "Format nix codes";
            command = "nix fmt";
            category = "misc";
          }
          {
            name = "install-sops";
            help = "Install sops age key on .config/sops to decrypt secrets";
            command = "mkdir -p /home/$USER/.config/sops/age; sudo ssh-to-age -private-key -i /etc/ssh/id_ed25519_age >> /home/$USER/.config/sops/age/keys.txt; sudo chown -R $USER:users /home/$USER/.config/sops/";
            category = "misc";
          }
          {
            name = "install-sops-home";
            help = "Install sops home age key on .config/sops to decrypt secrets";
            command = "mkdir -p /home/$USER/.config/sops/age; ssh-to-age -private-key -i /home/$USER/.ssh/id_ed25519_age >> /home/$USER/.config/sops/age/keys.txt; sudo chown -R $USER:users /home/$USER/.config/sops/";
            category = "misc";
          }
          {
            name = "rm-sops";
            help = "Remove sops age key from .config/sops";
            command = "sudo rm /home/$USER/.config/sops/age/keys.txt";
            category = "misc";
          }
          {
            name = "update";
            help = "Update all flake inputs and commit lock file";
            command = "nix flake update --commit-lock-file";
          }
          {
            name = "iso";
            help = "Build NixOS minimal install ISO for amd64";
            command = "nom build .#nixosConfigurations.iso.config.system.build.isoImage";
          }
          {
            name = "isoarm";
            help = "Build NixOS minimal install ISO for aarch64";
            command = "nom build .#nixosConfigurations.isoarm.config.system.build.isoImage";
          }
        ];
      };
    };
}
