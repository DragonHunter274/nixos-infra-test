{
  self,
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    {
      devShells.default = pkgs.mkShell {
        buildInputs =
          with pkgs;
          [
            nixos-rebuild
            nix-output-monitor
            nvd
            git
            nixfmt-rfc-style
            sops
          ]
          ++ lib.optionals (system == "x86_64-linux") [
            inputs.nix-netboot-serve.defaultPackage.${system}
          ];

        shellHook = ''
          echo "🚀 NixOS Infrastructure Development Environment"
          echo ""
          echo "Available hosts:"
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: _: "echo '  - ${name}'") self.nixosConfigurations
          )}
          echo ""
          echo "Commands:"
          echo "  nixos-rebuild switch --flake .#<hostname> --target-host <ip>"
          echo "  nix flake check"
          echo "  nix fmt"
          echo ""
          echo "Build outputs:"
          echo "  nix build .#nixosConfigurations.<hostname>.config.system.build.toplevel"
          echo "  nix build .#hydraJobs.nixos.<hostname>"
          echo "  nix build .#hydraJobs.sdImages.<rpi-hostname>"
          echo "  nix build .#hydraJobs.isoImages.<hostname-iso>"
          echo "  nix build .#hydraJobs.netboot.<hostname-netboot>"
          echo ""
          echo "ISO images:"
          echo "  Build: nix build .#nixosConfigurations.desktop-simon-iso.config.system.build.isoImage"
          echo "  Output: result/iso/*.iso"
          echo ""
          echo "Netboot:"
          echo "  Build: nix build .#nixosConfigurations.desktop-simon-netboot.config.system.build.netboot"
          echo "  Serve: nix-netboot-serve result/ --address 0.0.0.0"
          echo "  iPXE: chain http://<server-ip>:3030/<hostname-netboot>/netboot.ipxe"
        '';
      };
    };
}
