{ inputs, system }:

if system == "aarch64-linux" then
  inputs.nixos-generators.nixosGenerate {
    inherit system;
    format = "sd-aarch64";
    modules = [
      inputs.self.nixosModules.base
      inputs.nixos-hardware.nixosModules.raspberry-pi-4
    ];
  }
else
  null
