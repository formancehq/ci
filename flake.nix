{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    go-tooling = {
      url = "github:NixOS/nixpkgs/8cec5ef1131078ea76689e84c362b0ed6a1fb6a1";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, go-tooling, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        go = go127;
        go127 = pkgs.callPackage "${go-tooling}/pkgs/development/compilers/go/1.27.nix" {
          buildGo127Module = buildGo127Module;
        };
        buildGo127Module = pkgs.buildGoModule.override { go = go127; };
        golangci-lint = pkgs.callPackage "${go-tooling}/pkgs/by-name/go/golangci-lint/package.nix" {
          inherit buildGo127Module;
        };
      in {
        devShells.default = pkgs.mkShell {
          GOTOOLCHAIN = "local";
          buildInputs = [
            go
            pkgs.just
            golangci-lint
          ];
        };
      }
    );
}
