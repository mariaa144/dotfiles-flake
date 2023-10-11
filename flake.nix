{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }:
    let
      mkHost = hostName: system:
        nixpkgs.lib.nixosSystem {
          system = system;
          pkgs = nixpkgs.legacyPackages.${system};

          specialArgs = {
            # By default, the system will only use packages from the
            # stable channel.  You can selectively install packages
            # from the unstable channel. Such as
            # inherit (pkgs-unstable) hello;
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };

          modules = [
            # Root on ZFS related configuration
            ./modules

            # Configuration shared by all hosts
            (import ./configuration.nix)

            # Configuration per host
            (import ./hosts/${hostName})

            ({
              # Safety mechanism: refuse to build unless everything is
              # tracked by git
              system.configurationRevision = if (self ? rev) then
                self.rev
              else
                throw "refuse to build: git tree is dirty";

              system.stateVersion = "23.05";

              # import preconfigured profiles
              imports = [
                "${nixpkgs}/nixos/modules/installer/scan/not-detected.nix"
                # "${nixpkgs}/nixos/modules/profiles/hardened.nix"
              ];
            })

            # home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
            }
          ];
        };
    in {
      nixosConfigurations = {
        exampleHost = mkHost "exampleHost" "x86_64-linux";
      };
    };
}
