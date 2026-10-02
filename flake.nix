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
          packages = [
            pkgs.typst
            pkgs.check-jsonschema
          ];
          TYPST_FEATURES = "bundle,html";
        };
      });

      packages = forAllSystems (pkgs: {
        default = pkgs.stdenv.mkDerivation {
          pname = "mkor-je";
          version = self.shortRev or self.dirtyShortRev or "dev";
          src = self;
          nativeBuildInputs = [
            pkgs.typst
            pkgs.check-jsonschema
          ];
          TYPST_FEATURES = "bundle,html";
          SOURCE_DATE_EPOCH = toString self.lastModified;
          buildPhase = ''
            runHook preBuild
            check-jsonschema --schemafile src/data.schema.json src/data.yaml
            typst compile --format bundle \
              --input rev=${self.rev or self.dirtyRev or ""} \
              src/main.typ "$out"

            # Typst adds a <style> for MathML to the end of the <head> of pages
            # with equations; its rules live in styles.css instead. That leaves
            # the one <style> from styles.css, to allow by its hash in the
            # Content-Security-Policy.
            find "$out" -name '*.html' -exec sed -zi 's|<style>[^<]*</style></head>|</head>|' {} +
            for f in $(find "$out" -name '*.html'); do
              if [ "$(grep -o '<style' "$f" | wc -l)" -ne 1 ] || grep -q ' style="' "$f"; then
                echo "error: $f should have exactly one <style>, and no style attributes" >&2
                exit 1
              fi
            done

            runHook postBuild
          '';
          dontInstall = true;
        };
      });
    };
}
