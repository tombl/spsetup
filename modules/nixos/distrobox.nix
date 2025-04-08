{ pkgs, ... }:

let
  image = import ../../container/image.nix { inherit pkgs; };
  distrobox-shell = pkgs.writeShellApplication {
    name = "dbsh";
    runtimeInputs = [
      pkgs.distrobox
      pkgs.podman
    ];
    text = ''
      if [ "$USER" != team ]; then
        echo "This shell is not designed for you."
        exit 1
      fi

      if ! podman image exists spcontestant; then
          # outputs "Loaded image: sha256:<hash>"
          image="$(podman load --input ${image} --quiet | cut -d ' ' -f 3)"
          podman image tag "$image" spcontestant
      fi

      if ! distrobox-list | grep -q spcontestant; then
        distrobox-create --image spcontestant
      fi

      exec distrobox-enter spcontestant
    '';
    derivationArgs.passthru.shellPath = "/bin/dbsh";
  };
in

{
  virtualisation.podman.enable = true;
  environment.sessionVariables.DBX_CONTAINER_MANAGER = "podman";

  environment.systemPackages = [
    pkgs.distrobox
  ];

  environment.shells = [ distrobox-shell ];
  users.users.team.shell = distrobox-shell;
}
