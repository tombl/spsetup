{ pkgs }:

let
  inherit (pkgs) lib;

  packages = [
    "gcc"
    # "openjdk-17-jdk"
    # "openjdk-17-jre"
    # "python3"
    # "pypy3"
  ];
  release = "noble";
  # mirror = "http://archive.ubuntu.com/ubuntu/";
  mirror = "http://au.archive.ubuntu.com/ubuntu/";
  variant = "buildd";
  repos = [
    "main"
    # "universe"
  ];
  debsHash = "sha256-qbHqFe9pYebz86wJJjsM+p+5SInN1j3l2C/g1MxHHF4=";

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
        outputHashMode = "flat";
        outputHashAlgo = "sha256";
        outputHash = debsHash;
      }
      "debootstrap --make-tarball=$out --components=${lib.concatStringsSep "," repos} --include=${lib.concatStringsSep "," packages} --variant=${variant} ${release} tmp ${mirror}";

  rootfs = pkgs.vmTools.runInLinuxVM (
    pkgs.runCommand "ubuntu-rootfs" { nativeBuildInputs = [ debootstrap ]; } ''
      debootstrap --unpack-tarball=${debs} --components=${lib.concatStringsSep "," repos} --include=${lib.concatStringsSep "," packages} --variant=${variant} ${release} out ${mirror}

      rm -r out/dev/* # we can't copy the special files

      rm out/etc/{passwd,shadow,group} # we're going to provide our own users

      cp -r out/* $out
    ''
  );

  run = pkgs.writeShellApplication {
    name = "ubuntu-run";
    runtimeInputs = [ pkgs.bubblewrap ];
    text = ''
      bwrap \
        --bind ${rootfs} / \
        --overlay-src /etc --overlay-src ${rootfs}/etc --ro-overlay /etc \
        --setenv PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
        --proc /proc \
        --dev /dev \
        --bind /home /home \
        "$@"
    '';
  };
in
run
// {
  inherit rootfs;
  inherit debs;
}
