{ version, src, stdenv, lib, lua }:

stdenv.mkDerivation rec {
  pname = "bumpfnl";
  inherit version src;

  nativeBuildInputs = [ lua.pkgs.fennel ];
  buildInputs = [ lua ];

  makeFlags = [ "VERSION=${version}" "PREFIX=$(out)" ];

  meta = with lib; {
    description = "A CLI tool to bump version and update changelog.";
    homepage = "https://sr.ht/~m15a/bump.fnl";
    license = licenses.bsd3;
    mainProgram = "bump";
  };
}
