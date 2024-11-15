{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];
          buildInputs = with pkgs; [
            nodejs
            python3
            typescript
            node2nix
            circom
            nodePackages.ts-node
            nodePackages.pnpm
            # Add any other dependencies your project needs, possibly other X11 stuff
          ];

          shellHook = ''
            nix build github:aiken-lang/aiken#aiken
            export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath (with pkgs; [
            ])}:$LD_LIBRARY_PATH
          '';
        };
      }
    );
}
