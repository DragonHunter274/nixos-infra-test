{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.syncthingDeclarative;

  # Helper to generate folder config
  mkFolderConfig = name: folderCfg: {
    path = folderCfg.path;
    devices = folderCfg.devices;
    ignorePerms = folderCfg.ignorePerms;
    type = folderCfg.type;
    rescanIntervalS = folderCfg.rescanInterval;
    fsWatcherEnabled = folderCfg.watch;
    versioning = mkIf (folderCfg.versioning != null) folderCfg.versioning;
  };

in
{
  options.services.syncthingDeclarative = {
    enable = mkEnableOption "declarative Syncthing configuration";

    user = mkOption {
      type = types.str;
      default = "syncthing"; # Fixed: Use a literal default instead of referencing config
      description = "User account under which Syncthing runs";
    };

    group = mkOption {
      type = types.str;
      default = "syncthing"; # Fixed: Use a literal default instead of referencing config
      description = "Group under which Syncthing runs";
    };

    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/syncthing"; # Fixed: Use a literal default instead of referencing config
      description = "Path to Syncthing's data directory";
    };

    secrets = {
      enable = mkEnableOption "sops-nix integration for Syncthing secrets" // {
        default = true;
      };

      sopsFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = literalExpression "./secrets/secrets.yaml";
        description = ''
          Path to the sops file containing Syncthing secrets.
          If null, will use the default sops file.
        '';
      };

      keyPath = mkOption {
        type = types.str;
        default = "syncthing/key.pem";
        description = "Path within the sops file to the key.pem secret";
      };

      certPath = mkOption {
        type = types.str;
        default = "syncthing/cert.pem";
        description = "Path within the sops file to the cert.pem secret";
      };

      owner = mkOption {
        type = types.str;
        default = cfg.user;
        description = "Owner of the secret files";
      };

      group = mkOption {
        type = types.str;
        default = cfg.group;
        description = "Group of the secret files";
      };
    };

    keyFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/syncthing/key.pem";
      description = ''
        Path to the Syncthing key file. 
        Only use this if you're managing secrets manually (not using sops integration).
      '';
    };

    certFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/run/secrets/syncthing/cert.pem";
      description = ''
        Path to the Syncthing cert file.
        Only use this if you're managing secrets manually (not using sops integration).
      '';
    };

    noDefaultFolder = mkOption {
      type = types.bool;
      default = true;
      description = "Don't create default ~/Sync folder";
    };

    devices = mkOption {
      default = { };
      description = "Syncthing devices to sync with";
      type = types.attrsOf (
        types.submodule {
          options = {
            id = mkOption {
              type = types.str;
              description = "Device ID";
            };
            addresses = mkOption {
              type = types.listOf types.str;
              default = [ "dynamic" ];
              description = "Device addresses";
            };
            introducer = mkOption {
              type = types.bool;
              default = false;
              description = "Whether this device is an introducer";
            };
          };
        }
      );
    };

    folders = mkOption {
      default = { };
      description = "Syncthing folders to share";
      type = types.attrsOf (
        types.submodule {
          options = {
            path = mkOption {
              type = types.str;
              description = "Path to the folder";
            };

            devices = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "List of device names to share this folder with";
            };

            type = mkOption {
              type = types.enum [
                "sendreceive"
                "sendonly"
                "receiveonly"
              ];
              default = "sendreceive";
              description = "Folder type";
            };

            ignorePerms = mkOption {
              type = types.bool;
              default = false;
              description = "Ignore permission changes";
            };

            user = mkOption {
              type = types.str;
              default = cfg.user;
              description = "User owner of the folder";
            };

            group = mkOption {
              type = types.str;
              default = cfg.group;
              description = "Group owner of the folder";
            };

            createFolder = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to automatically create and manage folder ownership via tmpfiles";
            };

            rescanInterval = mkOption {
              type = types.int;
              default = 3600;
              description = "Rescan interval in seconds";
            };

            watch = mkOption {
              type = types.bool;
              default = true;
              description = "Enable filesystem watcher";
            };

            versioning = mkOption {
              type = types.nullOr (
                types.submodule {
                  options = {
                    type = mkOption {
                      type = types.enum [
                        "simple"
                        "trashcan"
                        "staggered"
                        "external"
                      ];
                      description = "Versioning type";
                    };
                    params = mkOption {
                      type = types.attrsOf types.str;
                      default = { };
                      description = "Versioning parameters";
                    };
                  };
                }
              );
              default = null;
              description = "Versioning configuration";
            };
          };
        }
      );
    };

    openDefaultPorts = mkOption {
      type = types.bool;
      default = false;
      description = "Open default Syncthing ports in firewall";
    };

    extraOptions = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra options to pass to services.syncthing";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.secrets.enable -> (cfg.keyFile == null && cfg.certFile == null);
        message = "When secrets.enable is true, keyFile and certFile should not be set manually";
      }
    ];

    # Configure sops secrets if enabled
    sops.secrets = mkIf cfg.secrets.enable {
      "syncthing-key" = {
        key = cfg.secrets.keyPath;
        owner = cfg.secrets.owner;
        group = cfg.secrets.group;
      }
      // (optionalAttrs (cfg.secrets.sopsFile != null) {
        sopsFile = cfg.secrets.sopsFile;
      });

      "syncthing-cert" = {
        key = cfg.secrets.certPath;
        owner = cfg.secrets.owner;
        group = cfg.secrets.group;
      }
      // (optionalAttrs (cfg.secrets.sopsFile != null) {
        sopsFile = cfg.secrets.sopsFile;
      });
    };

    services.syncthing = mkMerge [
      {
        enable = true;
        user = cfg.user;
        group = cfg.group;
        dataDir = cfg.dataDir;
        overrideDevices = true;
        overrideFolders = true;

        settings = {
          devices = mapAttrs (name: deviceCfg: {
            id = deviceCfg.id;
            addresses = deviceCfg.addresses;
            introducer = deviceCfg.introducer;
          }) cfg.devices;

          folders = mapAttrs mkFolderConfig cfg.folders;
        };
      }

      # Use sops-managed secrets if enabled, otherwise use manual paths
      (mkIf cfg.secrets.enable {
        key = config.sops.secrets."syncthing-key".path;
        cert = config.sops.secrets."syncthing-cert".path;
      })

      (mkIf (!cfg.secrets.enable && cfg.keyFile != null) { key = cfg.keyFile; })
      (mkIf (!cfg.secrets.enable && cfg.certFile != null) { cert = cfg.certFile; })
      (mkIf cfg.openDefaultPorts { openDefaultPorts = true; })

      cfg.extraOptions
    ];

    systemd.services.syncthing.environment = mkIf cfg.noDefaultFolder {
      STNODEFAULTFOLDER = "true";
    };

    # Ensure folder paths exist with correct permissions (only for folders with createFolder = true)
    systemd.tmpfiles.rules = mapAttrsToList (
      name: folderCfg: "d '${folderCfg.path}' 0750 ${folderCfg.user} ${folderCfg.group} - -"
    ) (filterAttrs (_: folderCfg: folderCfg.createFolder) cfg.folders);
  };
}
