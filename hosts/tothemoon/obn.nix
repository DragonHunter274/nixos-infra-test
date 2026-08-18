# obn.nix — open-bamboo-networking, built against this system's own glibc/openssl/curl
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config, git
, openssl, curl, zlib, cjson }:

let
  mosquittoSrc = fetchFromGitHub {
    owner = "eclipse-mosquitto";
    repo = "mosquitto";
    rev = "v2.1.2";
    hash = "sha256-Zl55yjuzQY2fyaKs/zLaJ7a3OONKTDQPaT+DpPURdZI=";
  };
  cjsonSrc = fetchFromGitHub {
    owner = "DaveGamble";
    repo = "cJSON";
    rev = "v1.7.18";   
    hash = "sha256-UgUWc/+Zie2QNijxKK5GFe4Ypk97EidG8nTiiHhn5Ys=";
  };
in
stdenv.mkDerivation rec {
  pname = "open-bamboo-networking";
  version = "unstable";          # pin to a release tag once you've confirmed it builds

  src = fetchFromGitHub {
    owner = "ClusterM";
    repo = "open-bamboo-networking";
    rev = "master";
    hash = "sha256-dbqvQdeEpMEmjZGsMMXE7+HPuLVZpIfN13XXv0joIuQ=";
  };

  nativeBuildInputs = [ cmake pkg-config git ];
  buildInputs = [ openssl curl zlib ];

  # obn's CMake vendoring scripts patch the mosquitto/cJSON sources in
  # place, so FETCHCONTENT_SOURCE_DIR can't point at the read-only Nix
  # store paths directly — copy them into a writable location first.
  preConfigure = ''
    cp -r --no-preserve=mode,ownership ${mosquittoSrc} ./vendor-mosquitto
    cp -r --no-preserve=mode,ownership ${cjsonSrc} ./vendor-cjson
    chmod -R u+w ./vendor-mosquitto ./vendor-cjson
    cmakeFlagsArray+=(
      "-DFETCHCONTENT_SOURCE_DIR_ECLIPSE_MOSQUITTO=$PWD/vendor-mosquitto"
      "-DFETCHCONTENT_SOURCE_DIR_CJSON=$PWD/vendor-cjson"
    )
  '';

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DOBN_VERSION=02.03.00.99"
  ];

  # Don't run the project's own installer/CMake install step — it assumes
  # it's placing files into a slicer's live config dir. Just take the .so's.
  #
  # The build produces an unversioned libbambu_networking.so — OrcaSlicer's
  # plugin loader expects the version baked into the filename (matching
  # OBN_VERSION above), so install it under that name.
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    find . -name 'libbambu_networking.so' -exec cp {} $out/lib/libbambu_networking_02.03.00.99.so \;
    find . -name 'libBambuSource.so' -exec cp {} $out/lib/ \;
    runHook postInstall
  '';

  meta = with lib; {
    description = "FOSS reimplementation of Bambu Studio's network plugin";
    homepage = "https://github.com/ClusterM/open-bamboo-networking";
    license = licenses.agpl3Only;
    platforms = platforms.linux;
  };
}
