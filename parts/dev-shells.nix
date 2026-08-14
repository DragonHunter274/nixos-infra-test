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
            age
            ssh-to-age
            # tothemoon's TPM-sealed sops key: sops can't decrypt the
            # "p256tag" stanzas age-plugin-tpm >=1.0.0-rc1 always emits
            # (see hosts/tothemoon/configuration.nix for the full story
            # and https://github.com/getsops/sops/issues/2129), so
            # `sops updatekeys`/`sops -e` for tothemoon's secrets must
            # run against this pre-p256tag build, not the stock package.
            (age-plugin-tpm.overrideAttrs (old: {
              version = "0.3.0";
              src = pkgs.fetchFromGitHub {
                owner = "Foxboron";
                repo = "age-plugin-tpm";
                rev = "v0.3.0";
                hash = "sha256-yr1PSSmcUoOrQ8VMQEoaCLNvDO+3+6N7XXdNUyYVz9M=";
              };
              vendorHash = "sha256-VEx6qP02QcwETOQUkMsrqVb+cOElceXcTDaUr480ngs=";
              doInstallCheck = false;
              doCheck = false;
            }))
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
