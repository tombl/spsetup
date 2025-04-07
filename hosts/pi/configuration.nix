{ inputs }:

{
  imports = [
    inputs.self.nixosModules.base
  ];
  nixpkgs.hostPlatform = "aarch64-linux";
}
