{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fennel-tools = {
      url = "github:m15a/flake-fennel-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fnldoc.url = "sourcehut:~m15a/fnldoc";
  };

  outputs = inputs @ { self, nixpkgs, flake-utils, fennel-tools, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            fennel-tools.overlays.default
            inputs.fnldoc.overlays.default
          ];
        };

        mkCICheckShell = { gnumake, fennel, faith, fnldoc }:
          pkgs.mkShell {
            buildInputs = [ gnumake fennel fennel.lua faith fnldoc ];
            FENNEL_PATH = "${faith}/bin/?";
          };

        builder = { fennelVariant, luaVariant }:
          let
            fennelName =
              if fennelVariant == "stable"
              then "fennel-${luaVariant}"
              else "fennel-${fennelVariant}-${luaVariant}";
          in {
            name = "ci-check-shell-${fennelName}";
            value = pkgs.callPackage mkCICheckShell {
              fennel = pkgs.${fennelName};
              faith = pkgs.faith-unstable;
            };
          };

        ci-check-shells = pkgs.lib.listToAttrs
          (map builder (pkgs.lib.attrsets.cartesianProductOfSets {
            fennelVariant = [ "stable" "unstable" ];
            luaVariant = [ "lua5_1" "lua5_2" "lua5_3" "lua5_4" "luajit" ];
          }));
      in
      {
        devShells = {
          inherit (ci-check-shells)
          ci-check-shell-fennel-lua5_1
          ci-check-shell-fennel-lua5_2
          ci-check-shell-fennel-lua5_3
          ci-check-shell-fennel-lua5_4
          ci-check-shell-fennel-luajit
          ci-check-shell-fennel-unstable-lua5_1
          ci-check-shell-fennel-unstable-lua5_2
          ci-check-shell-fennel-unstable-lua5_3
          ci-check-shell-fennel-unstable-lua5_4
          ci-check-shell-fennel-unstable-luajit;

          default =
            let
              fennel = pkgs.fennel-unstable-luajit;
              faith = pkgs.faith-unstable;
            in
            pkgs.mkShell {
              buildInputs = [
                pkgs.gnumake
                fennel
                fennel.lua
                pkgs.fnlfmt-unstable
                pkgs.fennel-ls-unstable
                pkgs.faith-unstable
                pkgs.fnldoc
              ] ++ (with fennel.lua.pkgs; [
                readline
              ]);
              FENNEL_PATH = "${faith}/bin/?";
            };
          };
      });
}
