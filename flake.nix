{
  description = "GNOME Shell extensions";

  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;

      forAllSystems = lib.genAttrs [
        "aarch64-linux"
        "x86_64-linux"
      ];

      extensionNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./extensions)
      );
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          mkExtension =
            name:
            let
              pname = "gnome-shell-extension-${name}";
              src = ./extensions/${name};
              metadata = builtins.fromJSON (builtins.readFile (src + "/metadata.json"));
            in
            # refer: https://github.com/NixOS/nixpkgs/blob/master/pkgs/desktops/gnome/extensions/buildGnomeExtension.nix
            pkgs.stdenvNoCC.mkDerivation {
              inherit pname src;
              version = toString metadata.version;

              installPhase = ''
                runHook preInstall

                mkdir -p $out/share/gnome-shell/extensions/
                cp -r -T . $out/share/gnome-shell/extensions/${metadata.uuid}

                runHook postInstall
              '';

              passthru = {
                extensionPortalSlug = pname;
                extensionUuid = metadata.uuid;
              };
            };
        in
        lib.genAttrs extensionNames mkExtension
      );
    };
}
