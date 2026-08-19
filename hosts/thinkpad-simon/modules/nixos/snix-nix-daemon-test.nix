# Testing setup for using snix as a Nix-daemon-protocol-speaking store,
# as a step towards using it as Hydra's build output store.
#
# This wires up two snix services:
#   - snix-store-backend: the gRPC blob/directory/pathinfo store (snix-store
#     daemon), backed by local objectstore+file/redb storage under
#     /var/lib/snix-nix-daemon-test.
#   - snix-nix-daemon: speaks the actual Nix worker (nix-daemon) protocol on
#     a unix socket, translating to gRPC calls against snix-store-backend.
#     This is the piece a real `nix`/`nix-store`/Hydra client would point
#     `--store unix://...` at.
#
# Test locally once deployed, e.g.:
#   nix copy --to unix:///run/snix-nix-daemon.sock /nix/store/<something>
#   nix-store --store unix:///run/snix-nix-daemon.sock -q --tree /nix/store/<something>
{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  snix = import inputs.snix { localSystem = pkgs.stdenv.hostPlatform.system; };

  stateDir = "snix-nix-daemon-test";
  backendSocket = "/run/snix-store-backend-test.sock";
  daemonSocket = "/run/snix-nix-daemon-test.sock";
in
{
  users.users.snix-nix-daemon-test = {
    isSystemUser = true;
    group = "snix-nix-daemon-test";
  };
  users.groups.snix-nix-daemon-test = { };

  systemd.services.snix-store-backend-test = {
    description = "snix-store gRPC backend (testing snix as a Hydra store)";
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        "${snix.snix.cli.store}/bin/snix-store"
        "daemon"
        "--listen-address"
        backendSocket
        "--unix-listen-unlink"
        "--blob-service-addr"
        "objectstore+file:/var/lib/${stateDir}/blobs"
        "--directory-service-addr"
        "redb:/var/lib/${stateDir}/directories.redb"
        "--path-info-service-addr"
        "redb:/var/lib/${stateDir}/pathinfo.redb"
      ];

      User = "snix-nix-daemon-test";
      Group = "snix-nix-daemon-test";
      StateDirectory = stateDir;
      RuntimeDirectory = "snix-store-backend-test";

      Restart = "on-failure";
      RestartSec = "5";
    };
  };

  systemd.services.snix-nix-daemon-test = {
    description = "snix Nix-daemon-protocol server (testing snix as a Hydra store)";
    wantedBy = [ "multi-user.target" ];
    after = [ "snix-store-backend-test.service" ];
    requires = [ "snix-store-backend-test.service" ];

    # `build_paths` shells out to nix-store to delegate real building to the
    # host's own real nix-daemon.
    path = [ config.nix.package ];

    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        "${snix.snix.cli.nix-daemon}/bin/snix-nix-daemon"
        "--listen-address"
        daemonSocket
        "--unix-listen-unlink"
        "--unix-listen-chmod"
        "everybody"
        "--blob-service-addr"
        "grpc+unix:${backendSocket}"
        "--directory-service-addr"
        "grpc+unix:${backendSocket}"
        "--path-info-service-addr"
        "grpc+unix:${backendSocket}"
      ];

      User = "snix-nix-daemon-test";
      Group = "snix-nix-daemon-test";
      RuntimeDirectory = "snix-nix-daemon-test";

      Restart = "on-failure";
      RestartSec = "5";
    };
  };
}
