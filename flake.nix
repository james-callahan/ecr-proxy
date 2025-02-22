{
  description = "ecr-proxy devshell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        gci = pkgs.buildGoModule rec {
           name = "gci";
           src = pkgs.fetchFromGitHub {
              owner = "daixiang0";
              repo = "gci";
              rev = "v0.10.1";
              sha256 = "sha256-/YR61lovuYw+GEeXIgvyPbesz2epmQVmSLWjWwKT4Ag=";
           };

           # Switch to fake vendor sha for upgrades:
           #vendorSha256 = pkgs.lib.fakeSha256;
           vendorSha256 = "sha256-g7htGfU6C2rzfu8hAn6SGr0ZRwB8ZzSf9CgHYmdupE8=";
        };

        tkbuild = pkgs.writeScriptBin "build" ''
          #!/bin/sh
          pushd $(git rev-parse --show-toplevel)/src/cmd/ecr-proxy
          ${pkgs.go}/bin/go build -o $(go env GOPATH)/bin/ecr-proxy
        '';

        tklint = pkgs.writeScriptBin "lint" ''
          #!/bin/sh
          pushd $(git rev-parse --show-toplevel)/src
          ${pkgs.go}/bin/go mod tidy
          ${pkgs.gofumpt}/bin/gofumpt -w ./cmd/ecr-proxy/*
          ${gci}/bin/gci write --skip-generated -s standard -s default -s "Prefix(github.com/tkhq)" ./cmd/ecr-proxy
          ${pkgs.golangci-lint}/bin/golangci-lint run ./cmd/ecr-proxy/...
          ${pkgs.go}/bin/go test -v ./...
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bashInteractive
            envsubst
            gci
            gofumpt
            golangci-lint
            go
            go-tools
            tkbuild
            tklint
          ];
        };
      });
}
