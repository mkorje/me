{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    typst = {
      url = "github:typst/typst-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.typst.url = "github:typst/typst";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      systems,
      typst,
    }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system:
          f (
            import nixpkgs {
              inherit system;
              overlays = [ typst.overlays.default ];
            }
          )
        );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.typst-dev ];
          TYPST_FEATURES = "bundle,html";
        };
      });

      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "mkor-je";
          version = self.shortRev or self.dirtyShortRev or "dev";
          src = self;
          nativeBuildInputs = [ pkgs.typst-dev ];
          TYPST_FEATURES = "bundle,html";
          SOURCE_DATE_EPOCH = toString self.lastModified;
          buildPhase = ''
            runHook preBuild
            typst compile --format bundle src/main.typ "$out"
            runHook postBuild
          '';
          dontInstall = true;
        };
      });
    };
}
