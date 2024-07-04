{
  description = "Generate an RSS feed from markup content and metadata";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-24.05;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pandoc-rss-name = "pandoc-rss";
          pandoc-rss-buildinputs = with pkgs; [ pandoc ./share/pandoc-rss ];
          pandoc-rss-script = pkgs.runCommandNoCC "pandoc-rss" {} ''
            mkdir -p $out/bin
              cp "${./bin/pandoc-rss}" $out/bin/pandoc-rss
              substituteInPlace $out/bin/pandoc-rss \
                --replace-fail "\$SHARE" "${./share/pandoc-rss}" \
                --replace-fail "/usr/bin/date" "${pkgs.coreutils}/bin/date"
          '';
        in
        rec {
          packages = {
            default = packages.pandoc-rss;
            pandoc-rss = pkgs.symlinkJoin {
              name = pandoc-rss-name;
              paths = [ pandoc-rss-script ] ++ pandoc-rss-buildinputs;
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/${pandoc-rss-name} --prefix PATH : $out/bin
              '';
            };
          };

          apps = {
            pandoc-rss = {
              type = "app";
              program = "${self.packages.${system}.pandoc-rss}/bin/pandoc-rss";
            };

            default = self.apps.${system}.pandoc-rss;
          };

          devShells.default = pkgs.mkShell {
            buildInputs = [
              pkgs.pandoc
              pkgs.nixfmt
            ];
          };
          formatter = pkgs.nixpkgs-fmt;
        });
}
