{
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11"; };

  outputs = { self, nixpkgs }@inputs:
    let
      lib = nixpkgs.lib;
      mkHost = { zfs-root, pkgs, system, ... }:
        lib.nixosSystem {
          inherit system;
          modules = [
            ./modules
            (import ./configuration.nix { inherit zfs-root inputs pkgs lib; })
          ];
        };
    in {
      nixosConfigurations = {
        exampleHost = let
          system = "x86_64-linux";
          pkgs = nixpkgs.legacyPackages.${system};
        in mkHost (import ./hosts/exampleHost { inherit system pkgs; });
      };
    };
}
