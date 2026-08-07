# Packages the kernel/initrd/cmdline nix-netboot-manager's NfsStoreNetboot
# boot target needs from a `mkNetbootNfsroot` nixosConfigurations variant
# (see lib.nix / hosts.nix's "-netboot-nfsroot" entries), in the same
# linkFarm shape nixos-netboot-manager's own flake.nix uses for its
# autoinstall-netboot package: a single store path with `kernel`, `initrd`,
# `cmdline` entries. The manager's UI takes the resulting `nix build`
# output path directly as a system's `artifact_path`.
#
# Deliberately uses `system.build.initialRamdisk`, NOT
# `system.build.netbootRamdisk` -- netboot.nix's netbootRamdisk
# unconditionally embeds the *entire* compressed closure
# (system.build.squashfsStore) into the initrd regardless of how
# fileSystems."/nix/.ro-store" is set, which would silently defeat the
# whole point of mounting it over NFS instead. initialRamdisk is the bare
# stage-1 initrd from before netboot.nix appends that squashfs -- stage-1
# already mounts fileSystems."/nix/.ro-store" (our NFS override) via the
# normal neededForBoot machinery, no squashfs involved.
{ self, ... }:
{
  flake.packages.x86_64-linux.tothemoon-netboot-nfsroot-artifact =
    let
      cfg = self.nixosConfigurations.tothemoon-netboot-nfsroot;
    in
    cfg.pkgs.linkFarm "tothemoon-netboot-nfsroot-artifact" [
      {
        name = "kernel";
        path = "${cfg.config.system.build.kernel}/${cfg.config.system.boot.loader.kernelFile}";
      }
      {
        name = "initrd";
        path = "${cfg.config.system.build.initialRamdisk}/initrd";
      }
      {
        name = "cmdline";
        path = cfg.pkgs.writeText "tothemoon-netboot-nfsroot-cmdline" (
          "init=${cfg.config.system.build.toplevel}/init initrd=initrd "
          + toString cfg.config.boot.kernelParams
        );
      }
    ];
}
