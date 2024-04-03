final: prev:

let
  inherit (prev.lib) optionalAttrs cartesianProductOfSets;

  buildPackageSet = { builder, args }: builtins.listToAttrs (map builder args);

  builder = { fennelVariant, luaVariant }:
    let
      fennelName = if fennelVariant == "stable" then
        "fennel-${luaVariant}"
      else
        "fennel-${fennelVariant}-${luaVariant}";
    in {
      name = "ci-check-${fennelName}";
      value = final.callPackage mkCICheckShell {
        fennel = final.${fennelName};
        faith = final.faith-no-compiler-sandbox;
      };
    };

  mkCICheckShell = { mkShell, fennel, faith, fnldoc }:
    mkShell {
      packages = [ fennel faith fnldoc ];
      FENNEL_PATH = "${faith}/bin/?";
    };

in {
  faith-no-compiler-sandbox = prev.faith-unstable.overrideAttrs (old: {
    postBuild = (old.postBuild or "") + ''
      sed -Ei bin/faith \
          -e '1s|(fennel)|-S \1 --no-compiler-sandbox|'
    '';
    dontFixup = true;
  });

} // buildPackageSet {
  inherit builder;
  args = cartesianProductOfSets {
    fennelVariant = [ "stable" "unstable" ];
    luaVariant = [ "lua5_1" "lua5_2" "lua5_3" "lua5_4" "luajit" ];
  };
}
