{
  ## ensure a successful installation by pinning nixpkgs to a known
  ## good revision
  inputs.nixpkgs.url =
    "github:nixos/nixpkgs/3d302c67ab8647327dba84fbdb443cdbf0e82744";
  ## after reboot, you can track latest stable by using
  #inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
  ## or track rolling release by using
  #inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }@inputs:
    let
      lib = nixpkgs.lib;
      mkHost = { my-config, zfs-root, pkgs, system, ... }:
        lib.nixosSystem {
          inherit system;
          modules = [
            ./modules
            (import ./configuration.nix {
              inherit my-config zfs-root inputs pkgs lib;
            })
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
