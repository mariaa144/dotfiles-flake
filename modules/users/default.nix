{ config, lib, ... }:
let
  cfg = config.zfs-root.users;
  inherit (lib) types mkDefault mkOption mkMerge;
  userOpts = { name, config, ... }: {
    options = {
      initialHashedPassword = mkOption {
        type = types.nullOr (types.passwdEntry types.str);
        default = null;
      };
      authorizedKeys = mkOption {
        type = types.listOf types.singleLineStr;
        default = [ ];
      };
      description = mkOption {
        type = types.passwdEntry types.str;
        default = "";
        example = "Alice Q. User";
      };
      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      packages = mkOption {
        type = types.listOf types.package;
        default = [ ];
      };
      group = mkOption {
        type = types.str;
        default = "users";
      };
      isSystemUser = mkOption {
        type = types.bool;
        default = false;
      };
      isNormalUser = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };
in {
  options.zfs-root.users = mkOption {
    default = { };
    type = types.attrsOf (types.submodule userOpts);
    example = {
      root = {
        initialHashedPassword = null;
        authorizedKeys = [ ];
      };
    };
  };
  config = {
    users.mutableUsers = false;
    users.users = lib.listToAttrs (map (u: {
      name = u;
      value = {
        inherit (cfg.${u})
          initialHashedPassword extraGroups packages isSystemUser isNormalUser;
        openssh.authorizedKeys.keys = cfg.${u}.authorizedKeys;
        description = mkDefault cfg.${u}.description;
        group = mkDefault cfg.${u}.group;
      };
    }) (lib.attrNames cfg));
  };
}
