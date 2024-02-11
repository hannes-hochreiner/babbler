{
  description = "A tool for extracting information from keepassxc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        craneLib = crane.lib.${system};
        babbler = craneLib.buildPackage {
          src = craneLib.cleanCargoSource ./.;

          buildInputs = [
            # Add additional build inputs here
          ];
        };
      in
      {
        checks = {
          inherit babbler;
        };

        packages.default = babbler;

        apps.default = flake-utils.lib.mkApp {
          drv = babbler;
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.checks;

          # Extra inputs can be added here
          nativeBuildInputs = with pkgs; [
            cargo
            rustc
          ];
        };
      }
    );
}