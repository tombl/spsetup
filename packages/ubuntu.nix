{ pkgs }:

let
  inherit (pkgs) lib;

  packages = [
    "hello"
  ];
  release = "noble";
  # mirror = "http://archive.ubuntu.com/ubuntu/";
  mirror = "http://au.archive.ubuntu.com/ubuntu/";
  variant = "minbase";
  debsHash = "sha256-FcU6plRxHbiARRr2FIGgatPlPxwjC/VUn6S4JJDUZRg=";

  debootstrap = pkgs.debootstrap.overrideAttrs {
    postInstall = ''
      substituteInPlace $out/bin/debootstrap \
        --replace-fail "PATH='" "PATH="$PATH":'"
    '';
  };

  debs =
    pkgs.runCommand "ubuntu-packages.tar"
      {
        nativeBuildInputs = [ debootstrap ];
        outputHashMode = "recursive";
        outputHashAlgo = "sha256";
        outputHash = debsHash;
      }
      "debootstrap --make-tarball=$out --include=${lib.concatStringsSep "," packages} --variant=${variant} ${release} tmp ${mirror}";

  rootfs = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "ubuntu-rootfs" { nativeBuildInputs = [ debootstrap ]; } ''
      debootstrap --unpack-tarball=${debs} --include=${lib.concatStringsSep "," packages} --variant=${variant} ${release} out ${mirror}
      rm -r out/dev # we can't copy the special files
      cp -r out/* $out
    ''
  );
in
rootfs
