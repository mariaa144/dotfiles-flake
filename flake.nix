{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager }:
    let
      mkHost = hostName: system:
        nixpkgs.lib.nixosSystem {
          system = system;
          pkgs = nixpkgs.legacyPackages.${system};
          # nixpkgs.config.allowUnfree = false;
          #  config = { allowUnfree = true; };

          specialArgs = {
            # By default, the system will only use packages from the
            # stable channel.  You can selectively install packages
            # from the unstable channel.
            pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
          };

          modules = [
            ./modules

            (import ./configuration.nix)

            (import ./hosts/${hostName})

            ({
              system.configurationRevision = if (self ? rev) then
                self.rev
              else
                throw "refuse to build: git tree is dirty";
              system.stateVersion = "23.05";
              imports = [
                "${nixpkgs}/nixos/modules/installer/scan/not-detected.nix"
                "${nixpkgs}/nixos/modules/profiles/hardened.nix"
              ];
            })

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
        nexus = mkHost "nexus" "x86_64-linux";
        vm1-gnome = mkHost "vm1-gnome" "x86_64-linux";
        vm1-cinnamon = mkHost "vm1-cinnamon" "x86_64-linux";
        vm1-terminal = mkHost "vm1-terminal" "x86_64-linux";
      };
    };
}
