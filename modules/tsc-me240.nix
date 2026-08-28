{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.services.tscMe240;

  vendorPpd = "${pkgs.nur-packages.tsc-printer}/share/cups/model/tsc-ppds/ME240.ppd";

  # PPD point values must be plain "123.45" strings (no scientific notation,
  # fixed 2 decimals) for CUPS to parse them reliably.
  mmToPt = mm: mm * 72.0 / 25.4;
  fmtPt =
    mm:
    let
      hundredths = builtins.floor (mmToPt mm * 100 + 0.5);
      whole = hundredths / 100;
      frac = hundredths - whole * 100;
      fracStr = if frac < 10 then "0${toString frac}" else toString frac;
    in
    "${toString whole}.${fracStr}";

  # PPD option keywords can't contain spaces/dots; derive one from the
  # size name (e.g. "60x40" -> "w60h40").
  mkKeyword = size: "w${builtins.replaceStrings [ "x" ] [ "h" ] size.name}";

  mkPageSizeLine =
    size:
    let
      w = fmtPt size.widthMm;
      h = fmtPt size.heightMm;
      label = "${size.name} (${toString size.widthMm}.00mm x ${toString size.heightMm}.00mm media)";
    in
    ''*PageSize ${mkKeyword size}/${label}: "<</PageSize[${w} ${h}]/ImagingBBox null>>setpagedevice"'';

  mkPageRegionLine =
    size:
    let
      w = fmtPt size.widthMm;
      h = fmtPt size.heightMm;
      label = "${size.name} (${toString size.widthMm}.00mm x ${toString size.heightMm}.00mm media)";
    in
    ''*PageRegion ${mkKeyword size}/${label}: "<</PageSize[${w} ${h}]/ImagingBBox null>>setpagedevice"'';

  mkImageableAreaLine =
    size:
    let
      w = fmtPt size.widthMm;
      h = fmtPt size.heightMm;
      label = "${size.name} (${toString size.widthMm}.00mm x ${toString size.heightMm}.00mm media)";
    in
    ''*ImageableArea ${mkKeyword size}/${label}: "0 0 ${w} ${h}"'';

  mkPaperDimensionLine =
    size:
    let
      w = fmtPt size.widthMm;
      h = fmtPt size.heightMm;
      label = "${size.name} (${toString size.widthMm}.00mm x ${toString size.heightMm}.00mm media)";
    in
    ''*PaperDimension ${mkKeyword size}/${label}: "${w} ${h}"'';

  # Insert one sed 'a\' block per stanza, appending all custom sizes right
  # after the vendor PPD's last built-in entry for that stanza (w4h6).
  sedAppend =
    anchor: lines:
    "-e '/^\\*${anchor} w4h6/a\\\n${concatStringsSep "\\\n" lines}'";

  customPpd = pkgs.runCommand "ME240-custom.ppd" { } ''
    cp ${vendorPpd} $out
    sed -i \
      ${sedAppend "PageSize" (map mkPageSizeLine cfg.customSizes)} \
      ${sedAppend "PageRegion" (map mkPageRegionLine cfg.customSizes)} \
      ${sedAppend "ImageableArea" (map mkImageableAreaLine cfg.customSizes)} \
      ${sedAppend "PaperDimension" (map mkPaperDimensionLine cfg.customSizes)} \
      $out
  '';

  ppd = if cfg.customSizes == [ ] then vendorPpd else customPpd;

in
{
  options.services.tscMe240 = {
    enable = mkEnableOption "TSC ME240 label printer CUPS queue";

    address = mkOption {
      type = types.str;
      example = "socket://10.100.163.75:9100";
      description = "CUPS device URI for the printer.";
    };

    queueName = mkOption {
      type = types.str;
      default = "TSC-ME240";
      description = "Name of the CUPS queue using the vendor PPD.";
    };

    rawQueueName = mkOption {
      type = types.nullOr types.str;
      default = "TSC-ME240-raw";
      description = "Name of an additional driverless (raw passthrough) queue. Set to null to skip creating it.";
    };

    customSizes = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              example = "60x40";
              description = "Display name for the size, shown in print dialogs.";
            };
            widthMm = mkOption {
              type = types.numbers.positive;
              description = "Physical media width fed to the printer, in mm.";
            };
            heightMm = mkOption {
              type = types.numbers.positive;
              description = "Physical media height fed to the printer, in mm.";
            };
          };
        }
      );
      default = [ ];
      example = [
        {
          name = "60x40";
          widthMm = 64;
          heightMm = 40;
        }
      ];
      description = ''
        Named label sizes to add to the printer's PPD, on top of the
        vendor-provided 2x4in/4x4in/4x6in presets. The printer already
        accepts free-form CUPS "Custom" sizes without any of this; add
        entries here only when a preset needs to show up by name (e.g. for
        software that can't submit an arbitrary custom size). widthMm/
        heightMm are the actual media fed to the printer -- if label roll
        stock is wider than the printed label, use the roll's real
        dimensions here and put the nominal label size in `name`.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.printing.drivers = [ pkgs.nur-packages.tsc-printer ];

    systemd.services.tsc-me240-setup = {
      description = "Configure TSC ME240 CUPS queue(s)";
      wantedBy = [ "multi-user.target" ];
      after = [ "cups.service" ];
      requires = [ "cups.service" ];
      serviceConfig.Type = "oneshot";
      # lpadmin is idempotent, so this reapplies on every activation --
      # changing customSizes and rebuilding is enough, no manual queue
      # deletion needed.
      script = ''
        for i in $(seq 1 10); do
          ${pkgs.cups}/bin/lpstat -H && break
          echo "Waiting for CUPS... ($i)"
          sleep 1
        done

        ${pkgs.cups}/bin/lpadmin \
          -p ${cfg.queueName} \
          -v ${cfg.address} \
          -P ${ppd} \
          -E
        ${pkgs.cups}/bin/lpadmin -d ${cfg.queueName}

        ${optionalString (cfg.rawQueueName != null) ''
          ${pkgs.cups}/bin/lpadmin \
            -p ${cfg.rawQueueName} \
            -v ${cfg.address} \
            -m raw \
            -E
        ''}
      '';
    };
  };
}
