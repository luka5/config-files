{ stdenv, fetchurl, fetchgit, unzip, otfcc, nodejs-6_x, ttfautohint, python2, utillinux, runCommand, writeTextFile }:

let

  nodeDependencies =
    let
      # node-packages.nix and node-env.nix generated by node2nix (generate.sh)
      nodejs = nodejs-6_x;
      nodeEnv = import ./node-env.nix { inherit stdenv nodejs python2 utillinux runCommand writeTextFile; };
      nodePackages = import ./node-packages.nix { inherit fetchurl fetchgit nodeEnv; };
    in nodePackages.shell.nodeDependencies;

  version = "1.12.5";

  set = "custom";

  variants = [
    "light"
    "lightitalic"
    "regular"
    "italic"
    "bold"
    "bolditalic"
    "heavy"
    "heavyitalic"
  ];
  styleGeneral = [ "expanded" ];
  styleUpright = [
    "v-l-italic"
    "v-i-italic"
    "v-brace-straight"
    "v-m-shortleg"
    "v-zero-dotted"
    "v-asterisk-low"
    "v-caret-low"
    "v-dollar-open"
  ];
  styleItalic = [
    "v-brace-straight"
    "v-m-shortleg"
    "v-zero-dotted"
    "v-asterisk-low"
    "v-caret-low"
    "v-dollar-open"
  ];

in
stdenv.mkDerivation {
  inherit version;
  name = "iosevka-${version}";

  src = fetchurl {
    url = "https://github.com/be5invis/Iosevka/archive/63c33eaf1a8853b4614fd922826c0525a9946f96.zip";
    sha256 = "0sksb49dh74fap8riysvhg1y582mdlnxr2f2i89qswzj9cr13yvf";
  };

  nativeBuildInputs = [ unzip otfcc nodejs-6_x ttfautohint ];

  patches = [ ./ligatures.patch ];

  buildPhase = ''
    ln -s ${nodeDependencies}/lib/node_modules

    make custom-config \
        set=${set} \
        design='${stdenv.lib.concatStringsSep " " styleGeneral}' \
        upright='${stdenv.lib.concatStringsSep " " styleUpright}' \
        italic='${stdenv.lib.concatStringsSep " " styleItalic}'
    for variant in ${stdenv.lib.concatStringsSep " " variants}; do
      make -f utility/custom.mk dist/iosevka-${set}/iosevka-${set}-$variant.ttf set=${set} __IOSEVKA_CUSTOM_BUILD__=true
    done
  '';

  installPhase = ''
    fontdir=$out/share/fonts/truetype
    mkdir -p $fontdir
    cp -v dist/iosevka-${set}/* $fontdir
  '';

  meta = with stdenv.lib; {
    homepage = "http://be5invis.github.io/Iosevka/";
    downloadPage = "https://github.com/be5invis/Iosevka/releases";
    description = ''
      Slender monospace sans-serif and slab-serif typeface inspired by Pragmata
      Pro, M+ and PF DIN Mono, designed to be the ideal font for programming.
    '';
    license = licenses.ofl;
    platforms = platforms.all;
    maintainers = [ maintainers.fmthoma ];
  };
}
