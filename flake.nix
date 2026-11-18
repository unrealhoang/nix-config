{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home manager
    home-manager = {
      # Track master: nixpkgs nixos-unstable currently reports 26.11, but HM's
      # next release branch (release-26.11) hasn't been cut yet, so master is
      # the matching branch. Switch to release-26.11 once it exists upstream.
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: Add any other flake you might need
    # hardware.url = "github:nixos/nixos-hardware";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    nix-colors = {
      url = "github:misterio77/nix-colors";
    };

    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
    };

    herdr-nix = {
      url = "github:herdrdev/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tgfs = {
      url = "github:unrealhoang/tgfs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do NOT override nixpkgs here: llm-agents' packages resolve helpers like
    # `installAgentSkills` out of the nixpkgs they are built against, and that
    # attribute only exists in a newer nixpkgs than this flake pins. Following
    # our nixpkgs makes the whole package set fail to evaluate with
    # "callPackageWith: Function called without required argument
    # installAgentSkills". Letting it use its own nixpkgs-unstable pin also
    # keeps its binaries substitutable from cache.numtide.com.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # niri compositor (do NOT override nixpkgs here — niri-flake ships
    # binaries via its own cache pinned to a specific nixpkgs)
    niri.url = "github:sodiboo/niri-flake";

    noctalia-shell = {
      # v5 is now the main line; the old `v5` pre-release branch was deleted
      # upstream (v4 moved to the `legacy-v4` branch).
      url = "github:noctalia-dev/noctalia-shell/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      impermanence,
      catppuccin,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    rec {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./pkgs { inherit pkgs; }
      );
      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        import ./shell.nix { inherit pkgs; }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        unrealPc = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            home-manager.nixosModules.home-manager
            impermanence.nixosModules.impermanence
            {
              home-manager.users.unreal = { ... }: {
                imports = [
                  ./home-manager/home.nix
                ];
              };
              home-manager.extraSpecialArgs = { inherit inputs outputs; };
            }
            # > Our main nixos configuration file <
            ./nixos/configuration.nix
          ];
        };
        hanode = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            home-manager.nixosModules.home-manager
            {
              home-manager.users.bing = import ./home-manager/hanode-bing.nix;
              home-manager.extraSpecialArgs = { inherit inputs outputs; };
            }
            # > Our main nixos configuration file <
            ./hanode/configuration.nix
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "unreal@unrealPc" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            ./home-manager/home.nix
          ];
        };
        "unreal@macAir" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            catppuccin.homeModules.catppuccin
            homeManagerModules.darwin-trampoline-apps
            # > Our main home-manager configuration file <
            ./home-manager/mac-air.nix
          ];
        };
        "unreal@macH2" = home-manager.lib.homeManagerConfiguration {
          pkgs =
            nixpkgs.legacyPackages.aarch64-darwin; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            catppuccin.homeModules.catppuccin
            homeManagerModules.darwin-trampoline-apps
            # > Our main home-manager configuration file <
            ./home-manager/mac-h2.nix
          ];
        };
      };
    };
}
