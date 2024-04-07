{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fennel-tools = {
      url = "github:m15a/flake-fennel-tools";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fnldoc = {
      url = "sourcehut:~m15a/fnldoc";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.fennel-tools.follows = "fennel-tools";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      fennel-tools,
      ...
    }:
    {
      overlays.default = import ./nix/overlay.nix {
        shortRev =
          self.shortRev or self.dirtyShortRev or self.lastModified or "unknown";
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
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

        apps =
          with flake-utils.lib;
          builtins.mapAttrs (
            name: pkg:
            mkApp {
              drv = pkg;
              name = pkg.meta.mainProgram or pkg.pname;
            }
          ) packages;

        checks = packages;

        devShells = {
          inherit (pkgs)
            ci-check-fennel-lua5_1
            ci-check-fennel-lua5_2
            ci-check-fennel-lua5_3
            ci-check-fennel-lua5_4
            ci-check-fennel-luajit

            ci-check-fennel-unstable-lua5_1
            ci-check-fennel-unstable-lua5_2
            ci-check-fennel-unstable-lua5_3
            ci-check-fennel-unstable-lua5_4
            ci-check-fennel-unstable-luajit
            ;

          default =
            let
              fennelName = "fennel-unstable-luajit";
            in
            pkgs."ci-check-${fennelName}".overrideAttrs (old: {
              nativeBuildInputs =
                old.nativeBuildInputs
                ++ [
                  pkgs.fennel-ls-unstable
                  pkgs.fnlfmt-unstable
                  pkgs.nixfmt-rfc-style
                ]
                ++ (with pkgs.${fennelName}.lua.pkgs; [ readline ]);
            });
        };
      }
    );
}
