{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.networkmanager.bootImport;
in
{
  options.services.networkmanager.bootImport = {
    enable = mkEnableOption "Import NetworkManager connections from /boot on startup";

    bootPath = mkOption {
      type = types.str;
      default = "/boot";
      description = "Path to the boot partition where .nmconnection files are located";
    };

    targetPath = mkOption {
      type = types.str;
      default = "/etc/NetworkManager/system-connections";
      description = "Target path for NetworkManager connection files";
    };

    removeAfterImport = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to remove .nmconnection files from boot partition after importing";
    };
  };

  config = mkIf cfg.enable {
    # Ensure NetworkManager is enabled
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "NetworkManager must be enabled to use bootImport";
      }
    ];

    # Create systemd service to import connections
    systemd.services.networkmanager-boot-import = {
      description = "Import NetworkManager connections from boot partition";
      wantedBy = [ "multi-user.target" ];
      after = [ "NetworkManager.service" ];
      before = [ "network-online.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        BOOT_PATH="${cfg.bootPath}"
        TARGET_PATH="${cfg.targetPath}"
        REMOVE_AFTER="${if cfg.removeAfterImport then "yes" else "no"}"

        # Check if boot path exists and is mounted
        if [ ! -d "$BOOT_PATH" ]; then
          echo "Boot path $BOOT_PATH does not exist, skipping import"
          exit 0
        fi

        # Find all .nmconnection files in boot partition
        shopt -s nullglob
        connections=("$BOOT_PATH"/*.nmconnection)
        
        if [ ''${#connections[@]} -eq 0 ]; then
          echo "No .nmconnection files found in $BOOT_PATH"
          exit 0
        fi

        echo "Found ''${#connections[@]} connection file(s) to import"

        # Import each connection file
        for conn_file in "''${connections[@]}"; do
          filename=$(basename "$conn_file")
          target_file="$TARGET_PATH/$filename"
          
          echo "Importing $filename..."
          
          # Copy file with correct permissions
          ${pkgs.coreutils}/bin/install -m 600 "$conn_file" "$target_file"
          
          # Ensure correct ownership
          ${pkgs.coreutils}/bin/chown root:root "$target_file"
          
          # Remove from boot if configured
          if [ "$REMOVE_AFTER" = "yes" ]; then
            echo "Removing $filename from boot partition"
            ${pkgs.coreutils}/bin/rm "$conn_file"
          fi
        done

        # Reload NetworkManager to pick up new connections
        echo "Reloading NetworkManager..."
        ${pkgs.systemd}/bin/systemctl reload NetworkManager.service || true
        
        echo "NetworkManager connection import complete"
      '';
    };
  };
}
