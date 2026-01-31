{ ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      ipxe-boot = pkgs.writeShellApplication {
        name = "ipxe-boot";
        runtimeInputs = with pkgs; [
          pixiecore
          nix
          iptables
        ];
        text = ''
          if [ $# -lt 1 ]; then
            echo "Usage: ipxe-boot <nixos-config-name>"
            echo "Example: ipxe-boot netboot-minimal"
            exit 1
          fi

          CONFIG="$1"
          shift

          FLAKEREF=".#nixosConfigurations.''${CONFIG}-netboot.config.system.build"

          echo "Building ''${CONFIG}-netboot kernel, ramdisk, and iPXE script..."
          KERNEL=$(nix build "''${FLAKEREF}.kernel" --no-link --print-out-paths)
          INITRD=$(nix build "''${FLAKEREF}.netbootRamdisk" --no-link --print-out-paths)
          IPXESCRIPT=$(nix build "''${FLAKEREF}.netbootIpxeScript" --no-link --print-out-paths)

          # Extract cmdline from the generated iPXE script (includes init= path)
          CMDLINE=$(grep '^kernel ' "''${IPXESCRIPT}/netboot.ipxe" | sed 's|^kernel bzImage ||' | sed 's| initrd=initrd||' | sed 's| [$][{]cmdline[}]||')

          KERNEL="''${KERNEL}/bzImage"
          INITRD="''${INITRD}/initrd"

          echo "Kernel:  ''${KERNEL}"
          echo "Initrd:  ''${INITRD}"
          echo "Cmdline: ''${CMDLINE}"
          echo ""

          # Open firewall ports for pixiecore:
          #   DHCP proxy: UDP 67, 4011
          #   TFTP: UDP 69
          #   HTTP: TCP 80 (default pixiecore HTTP port)
          cleanup() {
            echo ""
            echo "Closing firewall ports..."
            sudo iptables -D INPUT -p udp --dport 67 -j ACCEPT 2>/dev/null || true
            sudo iptables -D INPUT -p udp --dport 4011 -j ACCEPT 2>/dev/null || true
            sudo iptables -D INPUT -p udp --dport 69 -j ACCEPT 2>/dev/null || true
            sudo iptables -D INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null || true
            echo "Firewall restored."
          }
          trap cleanup EXIT

          echo "Opening firewall ports (67, 4011, 69, 80)..."
          sudo iptables -I INPUT -p udp --dport 67 -j ACCEPT
          sudo iptables -I INPUT -p udp --dport 4011 -j ACCEPT
          sudo iptables -I INPUT -p udp --dport 69 -j ACCEPT
          sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

          echo "Starting pixiecore (proxyDHCP mode)..."
          echo "Clients on the network will PXE boot into ''${CONFIG}"

          sudo pixiecore boot "''${KERNEL}" "''${INITRD}" --cmdline "''${CMDLINE}" "$@"
        '';
      };
    in
    {
      apps.ipxe = {
        type = "app";
        program = "${ipxe-boot}/bin/ipxe-boot";
      };
    };
}
