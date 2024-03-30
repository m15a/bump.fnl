{ version, src, stdenv, lib, fennel }:

stdenv.mkDerivation rec {
  pname = "bumpfnl";
  inherit version src;

  nativeBuildInputs = [ fennel ];
  buildInputs = [ fennel.lua ];

  makeFlags = [ "VERSION=${version}" "PREFIX=$(out)" ];

  meta = with lib; {
    description = "A CLI tool to bump version and update changelog.";
    homepage = "https://sr.ht/~m15a/bump.fnl";
    license = licenses.bsd3;
    mainProgram = "bump";
  };
}
