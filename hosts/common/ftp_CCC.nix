# NixOS configuration for public FTP server
{ config, pkgs, ... }:

{
  # Enable the FTP service
  services.vsftpd = {
    enable = true;
    
    # Basic server settings
    writeEnable = true;
    localUsers = false;
    anonymousUser = true;
    anonymousUserNoPassword = true;
    anonymousUserHome = "/flash/media";
    
    # Anonymous user permissions
    anonymousUploadEnable = true;
    anonymousMkdirWriteEnable = true;
    
    # Security and connection settings
    chrootlocalUser = false;
    userlistEnable = false;
    
    # Passive mode configuration (recommended for firewalls)
    pasv_enable = true;
    pasv_min_port = 21100;
    pasv_max_port = 21110;
    
    # Additional configuration
    extraConfig = ''
      # Allow anonymous uploads and modifications
      anon_upload_enable=YES
      anon_mkdir_write_enable=YES
      anon_other_write_enable=YES
      
      # Set umask for uploaded files (022 = readable by all, writable by owner)
      anon_umask=022
      
      # Disable seccomp filtering (can cause issues on some systems)
      seccomp_sandbox=NO
      
      # Logging
      xferlog_enable=YES
      xferlog_std_format=YES
      log_ftp_protocol=YES
      
      # Performance settings
      use_localtime=YES
      
      # Connection limits
      max_clients=50
      max_per_ip=5
      
      # Timeout settings
      idle_session_timeout=300
      data_connection_timeout=120
    '';
  };
  
  
  # Ensure the media directory exists and has proper permissions
  system.activationScripts.ftpSetup = ''
    mkdir -p /flash/media
    chown nobody:nogroup /flash/media
    chmod 755 /flash/media
  '';
  
  # Optional: Create a systemd service to monitor FTP logs
  systemd.services.ftp-log-monitor = {
    description = "FTP Log Monitor";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/echo 'FTP server started - logs available in /var/log/vsftpd.log'";
    };
  };
}
