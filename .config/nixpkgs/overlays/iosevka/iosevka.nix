{ stdenv, fetchurl, fetchgit, unzip, otfcc, nodejs-6_x, ttfautohint, python2, libtool, utillinux, runCommand, writeTextFile }:

let

  nodeDependencies =
    let
      # node-packages.nix and node-env.nix generated by node2nix (generate.sh)
      nodejs = nodejs-6_x;
      nodeEnv = import ./node-env.nix { inherit stdenv nodejs python2 libtool utillinux runCommand writeTextFile; };
      nodePackages = import ./node-packages.nix { inherit fetchurl fetchgit nodeEnv; };
    in nodePackages.shell.nodeDependencies;

  version = "2.2.1";

in
stdenv.mkDerivation {
  inherit version;
  name = "iosevka-${version}";

  src = fetchurl {
    url = "https://github.com/be5invis/Iosevka/archive/v2.2.1.tar.gz";
    sha256 = "0b45bzn60k5xr95p19fy1mhzhmf7g6rz91ab5jb6qjaw4p6md56c";
  };

  nativeBuildInputs = [ unzip otfcc nodejs-6_x ttfautohint ];

  patches = [ ./ligatures.patch ];

  buildPhase = ''
    ln -s ${nodeDependencies}/lib/node_modules
    npm run build -- contents::iosevka-expanded
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
