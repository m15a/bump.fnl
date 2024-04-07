{
  shortRev ? null,
}:

final: prev:

let
  inherit (prev) lib;

  packageVersions = lib.strings.fromJSON (lib.readFile ./versions.json);
in
{
  bumpfnl = final.callPackage ./package.nix {
    version =
      let
        version' = packageVersions.bumpfnl;
      in
      if isNull (builtins.match ".*-[-.[:alnum:]]+$" version') then
        version'
      else
        version' + lib.optionalString (shortRev != null) "-${shortRev}";
    src = ../.;
    lua = final.luajit;
  };
}
