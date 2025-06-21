{
  description = "A tool for extracting information from keepassxc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ (import rust-overlay) ];
      };

      rust-bin-custom = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" "rust-analyzer" ];
        targets = [ "x86_64-unknown-linux-gnu" ];
      };

      babbler-cargo-toml = (builtins.fromTOML (builtins.readFile ./Cargo.toml));
      hashes-toml = (builtins.fromTOML (builtins.readFile ./hashes.toml));

      babbler-deps = derivation {
        inherit system;
        name = "${babbler-cargo-toml.package.name}-${hashes-toml.cargo_lock}-deps";
        builder = "${pkgs.nushell}/bin/nu";
        buildInputs = with pkgs; [
          rust-bin-custom
        ];
        args = [ ./builder.nu "vendor" ./. ];

        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        outputHash = hashes-toml.deps;
      };

      babbler-bin = derivation {
          inherit system;
          name = "${babbler-cargo-toml.package.name}-v${babbler-cargo-toml.package.version}";
          builder = "${pkgs.nushell}/bin/nu";
          buildInputs = with pkgs; [
            gcc_multi
            rust-bin-custom
          ];
          args = [ ./builder.nu "build" ./. babbler-deps "babbler" hashes-toml.cargo_config ];
      };
    in {
      packages.${system} = {
        deps = babbler-deps;
        bin = babbler-bin;
        default = babbler-bin;
      };

      devShells.${system}.default = pkgs.mkShell {
        name = "babbler";

        # Inherit inputs from checks.
        # checks = self.checks.${system}
        # shellHook = ''
        #   exec zellij -l zellij.kdl
        # '';
        shellHook = ''
          exec nu
        '';
        # Additional dev-shell environment variables can be set directly
        # MY_CUSTOM_DEVELOPMENT_VAR = "something else"
        # Extra inputs can be added here; cargo and rustc are provided by default.
        buildInputs = with pkgs; [
          # zellij
          rust-bin-custom
        ];
      };
    };

    nixConfig = {
      substituters = [
        "https://cache.nixos.org"
        "https://hannes-hochreiner.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hannes-hochreiner.cachix.org-1:+ljzSuDIM6I+FbA0mdBTSGHcKOcEZSECEtYIEcDA4Hg="
      ];
    };
}
