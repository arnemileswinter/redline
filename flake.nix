{
  description = "Inline Markdown review with local AI agents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bun2nix.url = "github:nix-community/bun2nix";
  };

  outputs =
    { nixpkgs, bun2nix, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          bun2nixLib = bun2nix.packages.${system}.default;
          package = builtins.fromJSON (builtins.readFile ./package.json);
          pname = builtins.elemAt (nixpkgs.lib.splitString "/" package.name) 1;
        in
        {
          default = bun2nixLib.mkDerivation {
            inherit pname;

            packageJson = ./package.json;
            src = ./.;

            bunDeps = bun2nixLib.fetchBunDeps {
              bunNix = ./bun.nix;
            };

            nativeBuildInputs = [
              pkgs.bun
              pkgs.makeWrapper
            ];

            dontUseBunBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p "$out/lib/redline" "$out/bin"

              cp -r . "$out/lib/redline"

              makeWrapper ${pkgs.bun}/bin/bun "$out/bin/redline" \
                --add-flags "$out/lib/redline/bin/redline.cjs"

              runHook postInstall
            '';
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.bun
              bun2nix.packages.${system}.default
            ];
          };
        }
      );
    };
}
