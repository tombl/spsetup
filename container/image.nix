{ pkgs }:

builtins.storePath "/nix/store/rxkwapmsvn8ia2qdiszvhh23zckxn0zr-img2.tar"

# let
#   system = builtins.split "-" pkgs.system;
# in

# pkgs.dockerTools.pullImage {
#   imageName = "ghcr.io/tombl/spsetup";
#   # imageDigest = "sha256:";
#   # sha256 = pkgs.lib.fakeHash;
#   os = builtins.elemAt system 0;
#   arch = builtins.elemAt system 1;
# }
