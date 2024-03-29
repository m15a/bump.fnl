{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fennel-tools = {
      url = "github:m15a/flake-fennel-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fnldoc = {
      url = "sourcehut:~m15a/fnldoc";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, flake-utils, fennel-tools, ... }:
    ({
      overlays.default = import ./nix/overlay.nix {
        shortRev =
          self.shortRev or
          self.dirtyShortRev or
          self.lastModified or
          "unknown";
      };
    } // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            fennel-tools.overlays.default
            inputs.fnldoc.overlays.default
            self.overlays.default
            (import ./nix/ci.nix)
          ];
        };
      in
      rec {
        packages = rec {
          inherit (pkgs) bumpfnl;
          default = bumpfnl;
        };

        apps = with flake-utils.lib;
          builtins.mapAttrs
            (name: pkg: mkApp {
              drv = pkg;
              name = pkg.meta.mainProgram or pkg.pname;
            })
            packages;

        checks = packages;

        devShells = {
          inherit (pkgs)
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
                fennel
                fennel.lua
                faith
                pkgs.fnldoc
                pkgs.fennel-ls-unstable
                pkgs.fnlfmt-unstable
                pkgs.gnumake
              ] ++ (with fennel.lua.pkgs; [
                readline
              ]);
              FENNEL_PATH = "${faith}/bin/?";
            };
          };
      }));
}
