{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Use the published stable compiler and its matching module builder.
    nixpkgs-go = {
      url = "https://api.flakehub.com/f/pinned/NixOS/nixpkgs/0.2605.1016949%2Brev-1f607aa79b6356ed45d3cd3c8079c196e79efa2c/01a17424-ae2d-7b20-83c4-cf14527294c3/source.tar.gz";
      flake = false;
    };
    # Keep golangci-lint 2.15.0; stable currently provides 2.12.2.
    go-tooling = {
      url = "github:NixOS/nixpkgs/8cec5ef1131078ea76689e84c362b0ed6a1fb6a1";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixpkgs-go, go-tooling, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        goPkgs = import nixpkgs-go { inherit system; };
        go = goPkgs.go_1_27;
        golangci-lint = goPkgs.callPackage "${go-tooling}/pkgs/by-name/go/golangci-lint/package.nix" { };
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
