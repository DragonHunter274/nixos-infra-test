{
  lib,
  self,
  ...
}:
{
  perSystem =
    { pkgs, system, ... }:
    let
      upstreamUBoot = pkgs.pkgsCross.aarch64-multiplatform.buildUBoot {
        defconfig = "qcom_defconfig qcom-phone.config";
        extraConfig = ''
          CONFIG_DEFAULT_DEVICE_TREE="qcom/sdm845-oneplus-fajita"
          CONFIG_NO_FB_CLEAR=n
        '';
        filesToInstall = [
          "u-boot-nodtb.bin"
          "u-boot.dtb"
        ];
        nativeBuildInputs = with pkgs; [
          xxd
          bison
          flex
          openssl
          gnutls
        ];
        extraMeta.platforms = [ "aarch64-linux" ];
      };

      upstreamUBootImage = pkgs.runCommand "uboot-upstream-oneplus-fajita-boot-image" { } ''
        gzip ${upstreamUBoot}/u-boot-nodtb.bin -c > u-boot-nodtb.bin.gz
        cat u-boot-nodtb.bin.gz ${upstreamUBoot}/u-boot.dtb > u-boot.bin.gz
        printf "\\0" | gzip --stdout > empty.gz

        mkdir -p "$out"
        ${pkgs.lib.getExe' pkgs.android-tools "mkbootimg"} \
          --base 0x0 \
          --kernel_offset 0x8000 \
          --pagesize 4096 \
          --os_patch_level 2028-09-21 \
          --ramdisk empty.gz \
          --kernel u-boot.bin.gz \
          -o "$out/u-boot-upstream.img"
        ln -s u-boot-upstream.img "$out/u-boot.img"
      '';

      fajita = self.nixosConfigurations.oneplus-fajita;
      fajitaImages = pkgs.runCommand "oneplus-fajita-netboot" { } ''
        mkdir -p "$out"
        ln -s ${fajita.config.system.build.netbootAndroidBootImage}/nixos-netboot.img \
          "$out/nixos-netboot.img"
        ln -s ${fajita.config.vanilla-mobile.deviceInfo.uboot}/u-boot.img \
          "$out/u-boot.img"
        ln -s ${upstreamUBootImage}/u-boot-upstream.img \
          "$out/u-boot-upstream.img"
        ln -s ${fajita.config.system.build.diskoImages}/nixos-boot.raw \
          "$out/nixos-boot.raw"
        ln -s ${fajita.config.system.build.diskoImages}/nixos-root.raw \
          "$out/nixos-root.raw"
      '';
    in
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.oneplus-fajita-upstream-uboot-image = upstreamUBootImage;
      packages.oneplus-fajita-netboot = fajitaImages;
    };
}
