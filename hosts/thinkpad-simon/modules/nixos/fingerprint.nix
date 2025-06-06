{ pkgs, ... }:
{

  security.pam.services.polkit-1.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;

  services.udev.extraHwdb = ''
    usb:v138Ap0097*
     ID_AUTOSUSPEND=1
     ID_PERSIST=1

  '';

  services.open-fprintd.enable = true;
  services.python-validity.enable = true;

  systemd.services = {
    open-fprintd-suspend = {
      enable = true;
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
    };
    open-fprintd-resume = {
      enable = true;
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
        "suspend-then-hibernate.target"
      ];
    };
  };

  #   # System service to trigger the user service
  #   systemd.services.fprintd-verify-trigger = {
  #     description = "Trigger user-level fingerprint verification";
  #
  #     after = [ "open-fprintd-resume.service" ];
  #     requires = [ "open-fprintd-resume.service" ];
  #     wantedBy = [ "open-fprintd-resume.service" ];
  #
  #     serviceConfig = {
  #       User = "simon";
  #       Type = "oneshot";
  #       RemainAfterExit = false;
  #       ExecStart = pkgs.writeScript "fprintd-verify-loop" ''
  #         #!${pkgs.bash}/bin/bash
  #         ${pkgs.dbus}/bin/dbus-send --system --print-reply --dest=net.reactivated.Fprint --type=method_call /net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device.Claim string:"simon";
  #         ${pkgs.dbus}/bin/dbus-send --system --print-reply --dest=net.reactivated.Fprint --type=method_call /net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device.VerifyStop;
  #         ${pkgs.dbus}/bin/dbus-send --system --print-reply --dest=net.reactivated.Fprint --type=method_call /net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device.Release;
  #         ${pkgs.dbus}/bin/dbus-send --system --print-reply --dest=net.reactivated.Fprint --type=method_call /net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device.Claim string:"simon";
  #         until ${pkgs.fprintd}/bin/fprintd-verify -f right-index-finger; do
  #           :
  #         done
  #         ${pkgs.procps}/bin/pkill -USR1 hyprlock
  #         exit 0
  #       '';
  #     };
  #   };
  #
  #   # User service that does the actual verification
  #   systemd.user.services.fprintd-verify-loop = {
  #     description = "Run fingerprint verification after resume";
  #
  #     serviceConfig = {
  #       Type = "oneshot";
  #       RemainAfterExit = false;
  #
  #       ExecStart = pkgs.writeScript "fprintd-verify-loop" ''
  #         #!${pkgs.bash}/bin/bash
  #         ${pkgs.dbus}/bin/dbus-send --system --dest=net.reactivated.Fprint --type=method_call /net/reactivated/Fprint/Device/0 net.reactivated.Fprint.Device.VerifyStop
  #         until ${pkgs.fprintd}/bin/fprintd-verify -f right-index-finger; do
  #           :
  #         done
  #         ${pkgs.procps}/bin/pkill -USR1 hyprlock
  #         exit 0
  #       '';
  #
  #       # User service hardening
  #       ProtectSystem = "strict";
  #       ProtectHome = "read-only";
  #       NoNewPrivileges = true;
  #       RestrictSUIDSGID = true;
  #       PrivateTmp = true;
  #       RestrictNamespaces = true;
  #       SystemCallFilter = "@system-service";
  #     };
  #   };
  #
  #   # Enable lingering for your user
  #   users.users.simon.linger = true;

}
