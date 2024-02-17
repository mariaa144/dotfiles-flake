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
            # from the unstable channel.  You can also add more
            # channels to pin package version.
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
                # "${nixpkgs}/nixos/modules/profiles/qemu-guest.nix"
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
        nexus = mkHost "nexus" "x86_64-linux";
        vm1-gnome = mkHost "vm1-gnome" "x86_64-linux";
        vm1-cinnamon = mkHost "vm1-cinnamon" "x86_64-linux";
        vm1-terminal = mkHost "vm1-terminal" "x86_64-linux";
      };
    };
}
