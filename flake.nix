# Inputs must be defined here because they must be a static set. No calculations are allowed, meaning they can't be stored in other files.
{
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://berberman.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "berberman.cachix.org-1:UHGhodNXVruGzWrwJ12B1grPK/6Qnrx2c3TjKueQPds="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    latest.url = "github:nixos/nixpkgs";
    stable.url = "github:nixos/nixpkgs/nixos-24.11";
    small.url = "github:nixos/nixpkgs/nixos-unstable-small";
    rocm-update.url = "github:LunNova/nixpkgs/rocm-update";
    # Make sure to follow nixpkgs to unclutter lock file
    lix = {
      url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
      flake = false;
    };
    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.lix.follows = "lix";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix = {
      url = "github:nyawox/helix/patchy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    headscale = {
      url = "github:juanfont/headscale/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    berberman = {
      url = "github:berberman/flakes";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nvfetcher.follows = "nvfetcher";
    };
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    programsdb = {
      url = "github:wamserma/flake-programs-sqlite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    schizofox = {
      url = "github:schizofox/schizofox";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixtendo-switch = {
      url = "github:nyawox/nixtendo-switch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    psilocybin = {
      # url = "github:nyawox/psilocybin";
      url = "github:nyawox/psilocybin/playground";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    apple-fonts = {
      url = "github:Lyndeno/apple-fonts.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crowdsec = {
      url = "git+https://codeberg.org/kampka/nix-flake-crowdsec.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-eval-jobs = {
      url = "https://git.lix.systems/lix-project/nix-eval-jobs/archive/main.tar.gz";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
    flake-parts.url = "github:hercules-ci/flake-parts";
    taildrop-notifier.url = "github:nyawox/taildrop-notifier";
    niri-session-manager.url = "github:nyawox/niri-session-manager";
    # niri-session-manager.url = "/home/nyaa/Projects/niri-session-manager";
    impermanence.url = "github:nix-community/impermanence";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nur.url = "github:nix-community/nur";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    madness.url = "github:antithesishq/madness";
    zjstatus.url = "github:dj95/zjstatus";
  };

  outputs = args: import ./outputs.nix args;
}
