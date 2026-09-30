{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.vmnw.oneplus-fajita;
in
{
  options.vmnw.oneplus-fajita = {
    enable = lib.mkEnableOption "OnePlus 6T (oneplus-fajita)";
  };

  config = lib.mkIf cfg.enable {
    warnings =
      if !config.boot.loader.systemd-boot.enable then
        [
          ''
            systemd-boot is disabled. oneplus-fajita has currently only
            been configured for systemd-boot.
          ''
        ]
      else
        [ ];

    vanilla-mobile = {
      deviceInfo = {
        name = "OnePlus 6T";
        codename = "oneplus-fajita";
        manufacturer = "OnePlus";
        dtb = "qcom/sdm845-oneplus-fajita.dtb";
        imageSectorSize = 4096;
        firmware =
          inputs.vanilla-mobile-nixos.packages.${pkgs.stdenv.hostPlatform.system}.oneplus-sdm845-firmware;
        uboot = inputs.self.packages.x86_64-linux.oneplus-fajita-upstream-uboot-image;
      };
      soc.sdm845.enable = true;
    };

    boot = {
      consoleLogLevel = 8;
      kernelParams = [
        "firmware_class.path=/extra-firmware"
        "ignore_loglevel"
      ];
      initrd = {
        kernelModules = [
          "i2c_qcom_geni"
          "rmi_core"
          "rmi_i2c"
          "qcom_spmi_haptics"
        ];

        systemd.enable = true;
        systemd.storePaths =
          map
            (fw: {
              source = "${config.hardware.firmware}/lib/firmware/${fw}.zst";
              target = "/extra-firmware/${fw}.zst";
            })
            [
              "qcom/sdm845/OnePlus/enchilada/adsp.mbn"
              "qcom/sdm845/OnePlus/enchilada/cdsp.mbn"
              "qcom/sdm845/OnePlus/enchilada/ipa_fws.mbn"

              "qcom/sdm845/OnePlus/enchilada/a630_zap.mbn"
              "qcom/sdm845/OnePlus/enchilada/slpi.mbn"
              "ath10k/WCN3990/hw1.0/board-2.bin"
              "qca/crbtfw21.tlv"
              "qca/crnv21.bin"
              "qca/OnePlus/enchilada/crnv21.bin"

              "qcom/a630_sqe.fw"
              "qcom/a630_gmu.bin"
            ];
      };
    };

    services.q6voiced.settings = {
      q6voice_card = 0;
      q6voice_device = 6;
    };

    services.msm-modem-uim-selection.package =
      inputs.vanilla-mobile-nixos.inputs.nixpkgs.legacyPackages.aarch64-linux.msm-modem;
  };

  meta.maintainers = [ lib.maintainers.kwaa ];
}
