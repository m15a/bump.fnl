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
      in
      {
        devShells.default =
          let
            fennel = pkgs.fennel-unstable-luajit;
          in
          pkgs.mkShell {
            buildInputs = [
              pkgs.gnumake
              fennel
              fennel.lua
              pkgs.fnlfmt-unstable
              pkgs.fennel-ls-unstable
              pkgs.fnldoc
            ] ++ (with fennel.lua.pkgs; [
              readline
            ]);
          };
      });
}
