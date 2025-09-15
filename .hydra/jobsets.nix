{
  nixpkgs,
  pulls,
  declInput,
  ...
}:
let
  pkgs = import nixpkgs { };

  # The pulls should be the path to the JSON file we just saw
  prs = builtins.fromJSON (builtins.readFile pulls);

  # Create PR jobsets using the correct JSON structure
  prJobsets = pkgs.lib.mapAttrs (num: info: {
    enabled = if info.state == "open" then 1 else 0;
    hidden = info.state != "open";
    description = "PR ${num}: ${info.title}";
    checkinterval = 60;
    schedulingshares = 20;
    enableemail = false;
    emailoverride = "";
    keepnr = 3;
    type = 1;
    flake = "github:dragonhunter274/nixos-infra-test/pull/${num}/head";
  }) prs;

  # Main jobset
  mainJobset = {
    "main" = {
      enabled = 1;
      hidden = false;
      description = "Build main branch";
      checkinterval = 300;
      schedulingshares = 100;
      enableemail = false;
      emailoverride = "";
      keepnr = 10;
      type = 1;
      flake = "github:dragonhunter274/nixos-infra-test/main";
    };
  };

  allJobsets = prJobsets // mainJobset;
in
{
  jobsets = pkgs.runCommand "spec-jobsets.json" { } ''
    cat >$out <<EOF
    ${builtins.toJSON allJobsets}
    EOF
  '';
}
