final: prev:

let
  inherit (prev.lib)
    optionalAttrs
    cartesianProductOfSets;

  buildPackageSet = { builder, args }:
    builtins.listToAttrs (map builder args);

  builder = { fennelVariant, luaVariant }:
    let
      fennelName =
        if fennelVariant == "stable"
        then "fennel-${luaVariant}"
        else "fennel-${fennelVariant}-${luaVariant}";
    in {
      name = "ci-check-shell-${fennelName}";
      value = final.callPackage mkCICheckShell {
        fennel = final.${fennelName};
        faith = final.faith-unstable;
      };
    };

    mkCICheckShell = { mkShell, fennel, faith, fnldoc }:
      mkShell {
        packages = [
          fennel
          faith
          fnldoc
        ];
        FENNEL_PATH = "${faith}/bin/?";
      };
in

buildPackageSet {
  inherit builder;
  args = cartesianProductOfSets {
    fennelVariant = [
      "stable"
      "unstable"
    ];
    luaVariant = [
      "lua5_1"
      "lua5_2"
      "lua5_3"
      "lua5_4"
      "luajit"
    ];
  };
}
